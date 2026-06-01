// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

// Módulo de Operações de Trading (buy_from_startup, buy_from_user, sell_to_user)

import { db } from "../../shared/firebase";
import { FieldValue } from "firebase-admin/firestore";

// Tipos definidos para classificar as operações e controlar a máquina de estados de ofertas no sistema
type OperationType = "buy_from_startup" | "buy_from_user" | "sell_to_user";
type OperationStatus = "pending" | "accepted" | "rejected" | "cancelled";

// Função utilitária para gerar a chave primária composta da coleção 'holdings' (carteira)
// A composição "userId_startupId" garante a unicidade absoluta de um ativo por investidor no Firestore
function holdingDocId(userId: string, startupId: string): string {
  return `${userId}_${startupId}`;
}

// Retorna a referência do documento de holdings para operações de leitura/escrita rápidas
function holdingRef(userId: string, startupId: string) {
  return db.collection("holdings").doc(holdingDocId(userId, startupId));
}

// ─── Modo A: Compra direta da startup (Rodada Primária) ─────────────────────────
// Executa a transação atômica de compra de tokens emitidos diretamente pela startup emissores.
export async function buyFromStartup(
  userId: string,
  startupId: string,
  quantity: number
): Promise<{ operationId: string; updatedBalance: number; newHoldings: number }> {
  // Toda a operação roda dentro de uma transação do Firestore para mitigar condições de corrida (race conditions)
  // (ex: dois investidores tentando comprar os últimos 10 tokens simultaneamente)
  return db.runTransaction(async (transaction) => {
    const startupRef = db.collection("startups").doc(startupId);
    const startupDoc = await transaction.get(startupRef);
    if (!startupDoc.exists) throw new Error("Startup não encontrada.");

    const startupData = startupDoc.data()!;
    const pricePerTokenCents: number = startupData.currentTokenPriceCents ?? 0;
    const totalTokensIssued: number = startupData.totalTokensIssued ?? 0;
    const tokensSold: number = startupData.tokensSold ?? 0;
    // Calcula dinamicamente a escassez se o campo 'availableTokens' não existir explicitamente
    const availableTokens: number = startupData.availableTokens !== undefined
      ? startupData.availableTokens
      : Math.max(0, totalTokensIssued - tokensSold);
    const startupName: string = startupData.name ?? "";

    // Validações básicas de segurança operacional
    if (pricePerTokenCents <= 0) throw new Error("Preço de token inválido.");
    if (availableTokens < quantity) {
      throw new Error(`Tokens insuficientes. Disponível: ${availableTokens}.`);
    }

    const userRef = db.collection("users").doc(userId);
    const userDoc = await transaction.get(userRef);
    if (!userDoc.exists) throw new Error("Usuário não encontrado.");

    const currentBalance: number = userDoc.data()!.saldo ?? 0;
    const totalCents = quantity * pricePerTokenCents;
    const totalBRL = totalCents / 100; // Converte os centavos acumulados de volta para valor real em reais BRL

    // Impede a compra se o investidor não tiver saldo em conta virtual suficiente
    if (currentBalance < totalBRL) {
      throw new Error("Saldo insuficiente para realizar esta compra.");
    }

    // Gerenciamento e cálculo do Preço Médio (Cost Basis) do ativo:
    // Se o usuário já tiver tokens dessa startup, recalculamos a média ponderada do preço de aquisição
    const hRef = holdingRef(userId, startupId);
    const hDoc = await transaction.get(hRef);
    const currentQty: number = hDoc.exists ? (hDoc.data()!.quantity ?? 0) : 0;
    const currentAvg: number = hDoc.exists ? (hDoc.data()!.averagePriceCents ?? 0) : 0;
    const newQty = currentQty + quantity;
    const newAvg = newQty > 0
      ? Math.round((currentQty * currentAvg + quantity * pricePerTokenCents) / newQty)
      : 0;

    const newBalance = currentBalance - totalBRL;

    // Efetiva a dedução de saldo e atualização de carteira
    transaction.update(userRef, { saldo: newBalance });
    transaction.set(hRef, {
      userId, startupId,
      quantity: newQty,
      averagePriceCents: newAvg,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    
    // Atualiza a escassez e total de tokens vendidos no documento da startup
    transaction.update(startupRef, {
      availableTokens: availableTokens - quantity,
      tokensSold: FieldValue.increment(quantity),
    });

    // Registra o documento de auditoria e histórico de operações financeira
    const opRef = db.collection("operations").doc();
    transaction.set(opRef, {
      type: "buy_from_startup" as OperationType,
      status: "accepted" as OperationStatus,
      buyerId: userId,
      sellerId: null,
      startupId,
      startupName,
      quantity,
      pricePerTokenCents,
      askedPricePerTokenCents: pricePerTokenCents,
      totalCents,
      createdAt: FieldValue.serverTimestamp(),
      resolvedAt: FieldValue.serverTimestamp(),
      resolvedBy: "startup",
    });

    return { operationId: opRef.id, updatedBalance: newBalance, newHoldings: newQty };
  });
}

// ─── Modo B: Oferta de compra a outro investidor (Balcão de Negociação) ────────────
// Cria uma intenção/oferta de compra que ficará exposta no Livro de Ofertas (Order Book)
export async function buyFromUser(
  userId: string,
  startupId: string,
  quantity: number,
  pricePerTokenCents: number,
  validityDays: number
): Promise<{ operationId: string }> {
  return db.runTransaction(async (transaction) => {
    const startupRef = db.collection("startups").doc(startupId);
    const startupDoc = await transaction.get(startupRef);
    if (!startupDoc.exists) throw new Error("Startup não encontrada.");
    const startupName: string = startupDoc.data()!.name ?? "";

    const userRef = db.collection("users").doc(userId);
    const userDoc = await transaction.get(userRef);
    if (!userDoc.exists) throw new Error("Usuário não encontrado.");

    const currentBalance: number = userDoc.data()!.saldo ?? 0;
    // O saldo reservado ('reservedBalance') evita que o usuário lance múltiplas ofertas de compra 
    // com o mesmo dinheiro físico disponível em conta, protegendo contra double-spending
    const currentReserved: number = userDoc.data()!.reservedBalance ?? 0;
    const totalCents = quantity * pricePerTokenCents;
    const totalBRL = totalCents / 100;
    const available = currentBalance - currentReserved; // Saldo real livre para ser usado

    if (available < totalBRL) {
      throw new Error("Saldo disponível insuficiente para reservar esta oferta.");
    }

    // Incrementa o saldo reservado do comprador no banco de dados
    transaction.update(userRef, {
      reservedBalance: currentReserved + totalBRL,
    });

    // Define a data limite/expiração para o término automático da validade da oferta
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + (validityDays || 1));

    // Salva a oferta como "pending" (Pendente) no histórico de operações do Balcão
    const opRef = db.collection("operations").doc();
    transaction.set(opRef, {
      type: "buy_from_user" as OperationType,
      status: "pending" as OperationStatus,
      buyerId: userId,
      sellerId: null,
      startupId,
      startupName,
      quantity,
      pricePerTokenCents,
      askedPricePerTokenCents: pricePerTokenCents,
      totalCents,
      reservedBRL: totalBRL,
      expiresAt,
      createdAt: FieldValue.serverTimestamp(),
      resolvedAt: null,
      resolvedBy: null,
    });

    return { operationId: opRef.id };
  });
}

// ─── Criar oferta de venda (Balcão de Negociação) ───────────────────────────────────
// Permite que um investidor que possui ativos anuncie parte de seus tokens no livro
export async function sell(
  userId: string,
  startupId: string,
  quantity: number,
  askedPricePerTokenCents: number
): Promise<{ operationId: string }> {
  return db.runTransaction(async (transaction) => {
    const startupRef = db.collection("startups").doc(startupId);
    const startupDoc = await transaction.get(startupRef);
    if (!startupDoc.exists) throw new Error("Startup não encontrada.");
    const startupName: string = startupDoc.data()!.name ?? "";

    // Verifica se o vendedor realmente possui esses ativos em sua carteira no banco de dados
    const hRef = holdingRef(userId, startupId);
    const hDoc = await transaction.get(hRef);
    if (!hDoc.exists || (hDoc.data()!.quantity ?? 0) < quantity) {
      throw new Error("Holdings insuficientes para realizar esta oferta de venda.");
    }

    const totalCents = quantity * askedPricePerTokenCents;

    // Registra a oferta de venda pendente
    const opRef = db.collection("operations").doc();
    transaction.set(opRef, {
      type: "sell_to_user" as OperationType,
      status: "pending" as OperationStatus,
      buyerId: null,
      sellerId: userId,
      startupId,
      startupName,
      quantity,
      pricePerTokenCents: askedPricePerTokenCents,
      askedPricePerTokenCents,
      totalCents,
      createdAt: FieldValue.serverTimestamp(),
      resolvedAt: null,
      resolvedBy: null,
    });

    return { operationId: opRef.id };
  });
}

// ─── Vendedor aceita oferta de compra (Casamento / Liquidação de Negociação) ────────
// Chamado quando um investidor decide vender seus tokens aceitando uma oferta de compra pendente
export async function acceptOperation(
  sellerId: string,
  operationId: string
): Promise<{ updatedSellerBalance: number }> {
  return db.runTransaction(async (transaction) => {
    const opRef = db.collection("operations").doc(operationId);
    const opDoc = await transaction.get(opRef);
    if (!opDoc.exists) throw new Error("Operação não encontrada.");

    const opData = opDoc.data()!;
    // Garante segurança impedindo re-processamento ou concorrência de aceitação dupla
    if (opData.status !== "pending") throw new Error("Esta operação não está mais pendente.");
    if (opData.type !== "buy_from_user") {
      throw new Error("Apenas ofertas de compra entre usuários podem ser aceitas aqui.");
    }
    if (opData.buyerId === sellerId) {
      throw new Error("Você não pode aceitar sua própria oferta.");
    }

    const { buyerId, startupId, quantity, pricePerTokenCents, totalCents } = opData as {
      buyerId: string; startupId: string; quantity: number;
      pricePerTokenCents: number; totalCents: number;
    };
    const totalBRL = totalCents / 100;

    // Validar holdings reais do vendedor no exato momento da transação
    const sellerHRef = holdingRef(sellerId, startupId);
    const sellerHDoc = await transaction.get(sellerHRef);
    if (!sellerHDoc.exists || (sellerHDoc.data()!.quantity ?? 0) < quantity) {
      throw new Error("Você não possui tokens suficientes para aceitar esta oferta.");
    }

    // Validar se o saldo do comprador reservado no doc original está correto
    const buyerRef = db.collection("users").doc(buyerId);
    const buyerDoc = await transaction.get(buyerRef);
    if (!buyerDoc.exists) throw new Error("Comprador não encontrado.");
    const buyerBalance: number = buyerDoc.data()!.saldo ?? 0;
    const buyerReserved: number = buyerDoc.data()!.reservedBalance ?? 0;
    if (buyerReserved < totalBRL) throw new Error("Saldo reservado do comprador insuficiente.");

    const sellerRef = db.collection("users").doc(sellerId);
    const sellerDoc = await transaction.get(sellerRef);
    if (!sellerDoc.exists) throw new Error("Vendedor não encontrado.");
    const sellerBalance: number = sellerDoc.data()!.saldo ?? 0;

    // 1. LIQUIDAÇÃO FINANCEIRA
    // Debita o saldo real do comprador e libera a fatia do seu saldo reservado
    transaction.update(buyerRef, {
      saldo: buyerBalance - totalBRL,
      reservedBalance: Math.max(0, buyerReserved - totalBRL),
    });

    // Credita o vendedor adicionando o dinheiro real em seu saldo em reais
    const newSellerBalance = sellerBalance + totalBRL;
    transaction.update(sellerRef, { saldo: newSellerBalance });

    // 2. TRANSFERÊNCIA DOS ATIVOS (TOKENS)
    // Decrementa os tokens da carteira do Vendedor
    const sellerQty: number = sellerHDoc.data()!.quantity;
    transaction.update(sellerHRef, {
      quantity: Math.max(0, sellerQty - quantity),
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Incrementa os tokens e recalcula a média ponderada do preço de aquisição do Comprador
    const buyerHRef = holdingRef(buyerId, startupId);
    const buyerHDoc = await transaction.get(buyerHRef);
    const buyerQty: number = buyerHDoc.exists ? (buyerHDoc.data()!.quantity ?? 0) : 0;
    const buyerAvg: number = buyerHDoc.exists ? (buyerHDoc.data()!.averagePriceCents ?? 0) : 0;
    const newBuyerQty = buyerQty + quantity;
    const newBuyerAvg = newBuyerQty > 0
      ? Math.round((buyerQty * buyerAvg + quantity * pricePerTokenCents) / newBuyerQty)
      : 0;
    
    transaction.set(buyerHRef, {
      userId: buyerId, startupId,
      quantity: newBuyerQty,
      averagePriceCents: newBuyerAvg,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    // 3. REGISTRO DE FECHAMENTO
    // Atualiza a operação para aceito ("accepted") finalizando o ciclo de vida da oferta
    transaction.update(opRef, {
      status: "accepted" as OperationStatus,
      sellerId,
      resolvedAt: FieldValue.serverTimestamp(),
      resolvedBy: sellerId,
    });

    return { updatedSellerBalance: newSellerBalance };
  });
}

// ─── Cancelar/recusar operação pendente ─────────────────────────────────────
// Executado se o criador da oferta decidir retirá-la do livro (desistência de compra/venda)
export async function rejectOperation(
  userId: string,
  operationId: string
): Promise<void> {
  await db.runTransaction(async (transaction) => {
    const opRef = db.collection("operations").doc(operationId);
    const opDoc = await transaction.get(opRef);
    if (!opDoc.exists) throw new Error("Operação não encontrada.");

    const opData = opDoc.data()!;
    if (opData.status !== "pending") throw new Error("Esta operação não está mais pendente.");

    // Se for uma oferta de compra, precisamos desbloquear e devolver o dinheiro do saldo reservado
    if (opData.type === "buy_from_user") {
      if (opData.buyerId !== userId) {
        throw new Error("Apenas o comprador pode cancelar sua própria oferta.");
      }
      
      const buyerRef = db.collection("users").doc(opData.buyerId);
      const buyerDoc = await transaction.get(buyerRef);
      if (buyerDoc.exists) {
        const reserved: number = buyerDoc.data()!.reservedBalance ?? 0;
        const totalBRL: number = opData.totalCents / 100;
        
        // Devolve o dinheiro de volta ao saldo livre
        transaction.update(buyerRef, {
          reservedBalance: Math.max(0, reserved - totalBRL),
        });
      }
    } else if (opData.type === "sell_to_user") {
      if (opData.sellerId !== userId) {
        throw new Error("Apenas o vendedor pode cancelar sua própria oferta de venda.");
      }
    } else {
      throw new Error("Este tipo de operação não pode ser cancelada.");
    }

    // Altera o status da operação para "cancelled" (Cancelado) para registro histórico
    transaction.update(opRef, {
      status: "cancelled" as OperationStatus,
      resolvedAt: FieldValue.serverTimestamp(),
      resolvedBy: userId,
    });
  });
}

// ─── Consultas (Queries de Banco de Dados) ───────────────────────────────────

// Busca o extrato unificado de transações do usuário (filtrando onde ele foi o comprador OU vendedor)
export async function getOperationsByUser(userId: string): Promise<any[]> {
  const [buyerSnap, sellerSnap] = await Promise.all([
    db.collection("operations")
      .where("buyerId", "==", userId)
      .orderBy("createdAt", "desc")
      .limit(50)
      .get(),
    db.collection("operations")
      .where("sellerId", "==", userId)
      .orderBy("createdAt", "desc")
      .limit(50)
      .get(),
  ]);

  // Remove duplicidades na fusão das listas caso o usuário tenha negociado consigo mesmo por algum motivo
  const seen = new Set<string>();
  return [...buyerSnap.docs, ...sellerSnap.docs]
    .filter(d => !seen.has(d.id) && seen.add(d.id))
    .map(doc => ({ id: doc.id, ...doc.data() }));
}

// Lista o histórico de transações específicas de uma determinada startup
export async function getOperationsByStartup(startupId: string): Promise<any[]> {
  const snap = await db.collection("operations")
    .where("startupId", "==", startupId)
    .orderBy("createdAt", "desc")
    .limit(100)
    .get();
  return snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
}

// Retorna as ofertas de compra abertas expostas no Livro de Ofertas secundário da startup
export async function getPendingBuyOperations(startupId: string): Promise<any[]> {
  const snap = await db.collection("operations")
    .where("startupId", "==", startupId)
    .where("type", "==", "buy_from_user")
    .where("status", "==", "pending")
    .orderBy("createdAt", "desc")
    .limit(50)
    .get();
  return snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
}
