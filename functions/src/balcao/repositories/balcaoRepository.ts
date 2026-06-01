// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

// ════════════════════════════════════════════════════════════════════════════════
// Repositório do Balcão (Mercado de Tokens) — MesclaInvest
//
// Este é o coração do sistema de negociação de tokens. Contém todas as operações
// atômicas (transações Firestore) para compra, venda, criação/cancelamento de
// ofertas e consulta de holdings e histórico de preços.
//
// WALKTHROUGH DETALHADO (arquivo do Tomás — explicação aprofundada):
//
// O repositório mantém DUAS fontes de holdings em paralelo:
// 1. Coleção top-level `holdings` (nova) — document ID: `${userId}_${startupId}`
// 2. Subcoleção `startups/{id}/investors/{uid}` (legada)
//
// Essa dualidade existe por retrocompatibilidade: dados antigos vivem na subcoleção,
// mas novas operações escrevem em ambas para garantir que queries por ambos os caminhos
// funcionem. Com o tempo, a subcoleção legada pode ser descontinuada.
//
// RACE CONDITIONS E ATOMICIDADE:
// Todas as operações financeiras usam `db.runTransaction()` para garantir que
// leituras e escritas sejam atômicas. Se duas compras simultâneas ocorrerem,
// o Firestore detecta o conflito e re-executa a transação do "perdedor".
// Isso previne saldo negativo, overselling de tokens e inconsistências.
//
// MOTOR DE PREÇO:
// Após cada compra/venda, o motor de preço dinâmico (priceEngine.ts) recalcula
// o valor do token com base na pressão de mercado das últimas 24h.
// ════════════════════════════════════════════════════════════════════════════════

// Instância compartilhada do Firestore — garante conexão única em todo o backend
import { db } from "../../shared/firebase";

// FieldValue.serverTimestamp() grava o horário do servidor (não do cliente).
// Timestamp é usado para queries com filtro temporal (ex: últimas 24h).
import { FieldValue, Timestamp } from "firebase-admin/firestore";

// Motor de precificação dinâmica — calcula o novo preço com base em pressão de mercado
import { calculateNewPrice } from "../services/priceEngine";

// ════════════════════════════════════════════════════════════════════════════════
// SEÇÃO 1: Helpers para a coleção top-level `holdings`
//
// A coleção `holdings` armazena quantos tokens cada usuário possui de cada startup.
// O document ID segue a convenção `${userId}_${startupId}` para acesso direto.
// ════════════════════════════════════════════════════════════════════════════════

/**
 * Gera o ID do documento de holding a partir de userId e startupId.
 * Convenção: concatenar com underscore para acesso direto sem queries.
 * Ex: "abc123_biochip-campus"
 */
function holdingDocId(userId: string, startupId: string): string {
  return `${userId}_${startupId}`;
}

/**
 * Retorna a referência do documento de holding no Firestore.
 * Usado internamente por todas as funções que lêem ou escrevem holdings.
 */
function holdingRef(userId: string, startupId: string) {
  return db.collection("holdings").doc(holdingDocId(userId, startupId));
}

/**
 * Tipo que representa o snapshot de um holding lido dentro de uma transação.
 * `exists` indica se o documento já existia — importante para saber se estamos
 * criando um novo holding ou atualizando um existente.
 */
interface HoldingSnapshot {
  quantity: number;           // Quantidade de tokens que o usuário possui
  averagePriceCents: number;  // Preço médio ponderado de aquisição (em centavos)
  exists: boolean;            // Se o documento já existe no Firestore
}

/**
 * Lê os dados de um holding dentro de uma transação Firestore.
 *
 * WALKTHROUGH: Essa leitura PRECISA ser feita dentro da transação para
 * garantir atomicidade. Se fizéssemos fora da transação, outro processo
 * poderia alterar o holding entre a leitura e a escrita, causando
 * inconsistência no preço médio e na quantidade.
 *
 * Retorna { quantity: 0, averagePriceCents: 0, exists: false } se o
 * documento não existir — padrão seguro para contas novas.
 */
async function readHolding(
  transaction: FirebaseFirestore.Transaction,
  userId: string,
  startupId: string
): Promise<HoldingSnapshot> {
  const doc = await transaction.get(holdingRef(userId, startupId));
  if (!doc.exists) return { quantity: 0, averagePriceCents: 0, exists: false };
  const data = doc.data()!;
  return {
    quantity: Number(data.quantity ?? 0),
    averagePriceCents: Number(data.averagePriceCents ?? 0),
    exists: true,
  };
}

/**
 * Aplica uma compra ao holding do usuário dentro de uma transação.
 *
 * WALKTHROUGH — Preço médio ponderado:
 * O preço médio é recalculado usando média ponderada:
 *   novoMédio = (qtdAnterior × preçoMédioAnterior + qtdComprada × preçoAtual) / novaQtdTotal
 *
 * Exemplo: se o usuário tem 100 tokens a R$ 5,00 e compra 50 a R$ 6,00:
 *   novoMédio = (100 × 500 + 50 × 600) / 150 = 80000/150 ≈ 533 centavos = R$ 5,33
 *
 * Se a quantidade final for 0 (caso improvável), o preço médio é zerado.
 * `merge: true` garante que outros campos do documento não sejam apagados.
 */
function applyHoldingBuy(
  transaction: FirebaseFirestore.Transaction,
  userId: string,
  startupId: string,
  current: HoldingSnapshot,
  addedQty: number,
  pricePerTokenCents: number
) {
  // Calcula a nova quantidade total de tokens após a compra
  const newQuantity = current.quantity + addedQty;

  // Recalcula o preço médio ponderado em centavos
  const newAverageCents = newQuantity > 0
    ? Math.round(
        (current.quantity * current.averagePriceCents + addedQty * pricePerTokenCents) /
          newQuantity
      )
    : 0;

  // Grava o holding atualizado (merge: true preserva campos existentes)
  transaction.set(
    holdingRef(userId, startupId),
    {
      userId,
      startupId,
      quantity: newQuantity,
      averagePriceCents: newAverageCents,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

/**
 * Aplica uma venda ao holding do usuário dentro de uma transação.
 *
 * WALKTHROUGH — Decisão de design:
 * Quando o usuário vende TODOS os tokens (quantity chega a 0), o documento
 * NÃO é deletado. Em vez disso, mantemos com quantity=0 para preservar
 * o `averagePriceCents` — isso é útil para relatórios de P&L (lucro/prejuízo)
 * e auditoria. O app pode filtrar holdings com quantity > 0 na exibição.
 */
function applyHoldingSell(
  transaction: FirebaseFirestore.Transaction,
  userId: string,
  startupId: string,
  current: HoldingSnapshot,
  soldQty: number
) {
  // Math.max(0, ...) previne quantidade negativa em caso de inconsistência
  const newQuantity = Math.max(0, current.quantity - soldQty);
  const ref = holdingRef(userId, startupId);

  if (newQuantity <= 0) {
    // Zera a quantidade mas mantém o documento para preservar histórico de preço médio
    transaction.set(
      ref,
      {
        userId,
        startupId,
        quantity: 0,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  } else {
    // Apenas atualiza a quantidade — averagePriceCents permanece inalterado
    transaction.update(ref, {
      quantity: newQuantity,
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// SEÇÃO 2: Tipos de documentos do Balcão
// ════════════════════════════════════════════════════════════════════════════════

/**
 * Documento que registra uma operação de compra/venda de tokens.
 * Armazenado na coleção `tokenOperations` para histórico e auditoria.
 */
export interface TokenOperationDoc {
  id?: string;                 // ID gerado pelo Firestore (adicionado após leitura)
  buyerId?: string;            // UID do comprador (pode ser "startup:XXX" em vendas diretas)
  sellerId?: string;           // UID do vendedor (pode ser "startup:XXX" em compras diretas)
  userId: string;              // Para compatibilidade com queries legadas
  startupId: string;           // Startup cujos tokens foram negociados
  type: "buy" | "sell" | "buy_from_order" | "sell_via_order"; // Tipo da operação
  quantity: number;            // Quantidade de tokens negociados
  pricePerToken: number;       // Preço por token em BRL (reais)
  totalValue: number;          // Valor total da operação em BRL
  status: "completed" | "pending" | "cancelled"; // Estado da operação
  createdAt: any;              // Timestamp de criação (FieldValue.serverTimestamp)
  updatedAt: any;              // Timestamp da última atualização
  relatedOfferId?: string | null; // ID da oferta do balcão que originou esta operação
}

/**
 * Documento que registra uma oferta aberta no book de ordens do Balcão.
 * Armazenado na coleção `balcaoOffers`.
 *
 * WALKTHROUGH — Ciclo de vida de uma oferta:
 * 1. Criação: status = "open" (ou "pending_approval" se preço abaixo do mercado)
 * 2. Match parcial: remainingQuantity diminui, status permanece "open"
 * 3. Match total: remainingQuantity = 0, status muda para "matched"
 * 4. Cancelamento: status = "cancelled", saldo reservado é liberado
 */
export interface BalcaoOfferDoc {
  id?: string;                 // ID gerado pelo Firestore
  userId: string;              // UID de quem criou a oferta
  buyerId?: string | null;     // UID do comprador (null se for oferta de venda)
  sellerId?: string | null;    // UID do vendedor (null se for oferta de compra)
  startupId: string;           // Startup dos tokens sendo ofertados
  type: "buy" | "sell";        // Tipo: oferta de compra ou venda
  quantity: number;            // Quantidade original de tokens ofertados
  remainingQuantity: number;   // Quantidade ainda disponível (diminui com matches parciais)
  pricePerToken: number;       // Preço pedido/oferecido por token em BRL
  reservedAmount: number;      // Saldo reservado na carteira do comprador (BRL)
  status: "open" | "pending_approval" | "matched" | "cancelled" | "rejected"; // Estado atual
  createdAt: any;              // Timestamp de criação
  updatedAt?: any;             // Timestamp da última atualização
}

// ════════════════════════════════════════════════════════════════════════════════
// SEÇÃO 3: Volume de negociação para o motor de preço
// ════════════════════════════════════════════════════════════════════════════════

/**
 * Recupera o volume negociado (compras e vendas separadas) nas últimas 24 horas.
 *
 * WALKTHROUGH — Por que separar buyVolume e sellVolume?
 * O motor de preço precisa saber a DIREÇÃO da pressão: mais compras = alta,
 * mais vendas = baixa. Se só tivéssemos volume total, não saberíamos para
 * onde o preço deve se mover.
 *
 * EDGE CASE: Operações "buy_from_order" contam como compra, e "sell_via_order"
 * como venda, porque ambos representam pressão real de mercado.
 */
async function getRecentVolume24h(startupId: string): Promise<{ buyVolume: number; sellVolume: number }> {
  // Calcula o timestamp de 24h atrás
  const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

  // Busca apenas operações completadas (não canceladas/pendentes) das últimas 24h
  const snapshot = await db.collection("tokenOperations")
    .where("startupId", "==", startupId)
    .where("status", "==", "completed")
    .where("createdAt", ">=", Timestamp.fromDate(oneDayAgo))
    .get();

  let buyVolume = 0;
  let sellVolume = 0;

  // Acumula o volume por tipo de operação
  snapshot.docs.forEach((doc) => {
    const data = doc.data();
    const quantity = Number(data.quantity ?? 0);
    if (data.type === "buy" || data.type === "buy_from_order") {
      buyVolume += quantity;
    } else if (data.type === "sell" || data.type === "sell_via_order") {
      sellVolume += quantity;
    }
  });

  return { buyVolume, sellVolume };
}

// ════════════════════════════════════════════════════════════════════════════════
// SEÇÃO 4: Compra direta da startup (transação atômica)
// ════════════════════════════════════════════════════════════════════════════════

/**
 * Compra de tokens diretamente da startup (venda primária).
 *
 * WALKTHROUGH DETALHADO — Fluxo da transação:
 * 1. Busca volume de 24h FORA da transação (leitura não-transacional é OK aqui
 *    porque o volume é apenas um input para o cálculo de preço, não um valor
 *    que precisa de atomicidade estrita)
 * 2. Dentro da transação, lê:
 *    - Saldo do usuário (inclui campo `reservedBalance` para descontar)
 *    - Dados da startup (preço atual, tokens disponíveis)
 *    - Holdings atuais (subcoleção legada + coleção top-level)
 * 3. Valida: tokens suficientes no estoque? Saldo suficiente?
 * 4. Calcula novo preço com o motor de precificação
 * 5. Grava atomicamente: saldo atualizado, holdings incrementados,
 *    startup atualizada, operação registrada, histórico de preço
 *
 * RACE CONDITION: Se dois usuários comprarem simultaneamente, o Firestore
 * detecta conflito nas leituras transacionais e re-executa uma delas.
 * Isso garante que o estoque de tokens nunca fique negativo.
 */
export async function buyTokensTransaction(
  userId: string,
  startupId: string,
  quantity: number
): Promise<{ updatedBalance: number; newTokenPrice: number }> {
  // 1. Busca volumes de negociação das últimas 24 horas (pré-transação)
  const { buyVolume, sellVolume } = await getRecentVolume24h(startupId);

  // Inclui a quantidade da operação atual no cálculo da pressão de compra
  const recentBuyVolume = buyVolume + quantity;
  const recentSellVolume = sellVolume;

  // Referências aos documentos que serão lidos/escritos na transação
  const userRef = db.collection("users").doc(userId);
  const startupRef = db.collection("startups").doc(startupId);
  const investorRef = startupRef.collection("investors").doc(userId);
  const operationRef = db.collection("tokenOperations").doc(); // Doc com ID auto-gerado

  let updatedBalance = 0;
  let newTokenPrice = 0;

  // Executa tudo em transação atômica — tudo ou nada
  await db.runTransaction(async (transaction) => {
    // Lê todos os documentos necessários dentro da transação
    const userDoc = await transaction.get(userRef);
    const startupDoc = await transaction.get(startupRef);
    const investorDoc = await transaction.get(investorRef);
    const holdingSnapshot = await readHolding(transaction, userId, startupId);

    // Validações de existência
    if (!userDoc.exists) {
      throw new Error("Usuário não encontrado.");
    }
    if (!startupDoc.exists) {
      throw new Error("Startup não encontrada no catálogo.");
    }

    const userData = userDoc.data()!;
    const startupData = startupDoc.data()!;

    // Verifica se a startup possui tokens suficientes em estoque para venda
    // Fallback para 999999 se o campo não existir (startups legadas sem controle de estoque)
    const currentAvailable = startupData.availableTokens !== undefined ? Number(startupData.availableTokens) : 999999;
    // Calcula quantos tokens já foram vendidos (para atualizar depois)
    const currentSold = startupData.tokensSold !== undefined ? Number(startupData.tokensSold) : Math.max(0, Number(startupData.totalTokensIssued ?? 0) - currentAvailable);
    if (currentAvailable < quantity) {
      throw new Error(`A startup não possui tokens suficientes disponíveis para venda direta. Disponível: ${currentAvailable}`);
    }

    // Saldo do usuário: total menos reservado (reservas de ofertas de compra pendentes)
    const totalBalance = Number(userData.saldo ?? userData.balance ?? 0);
    const reservedBalance = Number(userData.reservedBalance ?? userData.reserved ?? 0);
    const availableBalance = totalBalance - reservedBalance;

    // Preço do token em centavos → converte para BRL para os cálculos
    const currentPriceCents = Number(startupData.currentTokenPriceCents ?? 0);
    const pricePerToken = currentPriceCents / 100;
    const totalCost = quantity * pricePerToken;

    // Valida saldo disponível (descontando reservas)
    if (availableBalance < totalCost) {
      throw new Error("Saldo insuficiente para realizar esta compra.");
    }

    // Calcula o preço inicial de emissão — trava no primeiro trade se não existir
    // Isso serve como âncora para o cálculo do preço de piso (floor)
    const initialPriceCents = Number(startupData.initialPriceCents ?? startupData.currentTokenPriceCents ?? currentPriceCents);
    const initialPrice = initialPriceCents / 100;

    // Calcula o novo preço com o motor de precificação linear
    newTokenPrice = calculateNewPrice(pricePerToken, recentBuyVolume, recentSellVolume, initialPrice);
    const newTokenPriceCents = Math.round(newTokenPrice * 100);

    // Debita o saldo do usuário pelo custo total da compra
    updatedBalance = totalBalance - totalCost;
    transaction.update(userRef, {
      saldo: updatedBalance,   // Campo legado mantido por retrocompatibilidade
      balance: updatedBalance  // Campo novo — ambos são atualizados em paralelo
    });

    // Atualiza holdings na subcoleção `investors` (retrocompatibilidade)
    const currentHolding = investorDoc.exists ? Number(investorDoc.data()!.tokens ?? 0) : 0;
    transaction.set(investorRef, {
      userId: userId,
      startupId: startupId,
      tokens: currentHolding + quantity,
      updatedAt: FieldValue.serverTimestamp()
    }, { merge: true });

    // Atualiza holdings na coleção top-level `holdings` (com preço médio ponderado)
    applyHoldingBuy(transaction, userId, startupId, holdingSnapshot, quantity, currentPriceCents);

    // Atualiza o catálogo da startup: novo preço, estoque e contagem de vendidos
    const startupUpdates: any = {
      currentTokenPriceCents: newTokenPriceCents,
      currentTokenPrice: newTokenPrice, // BRL double para exibição no app
      availableTokens: Math.max(0, currentAvailable - quantity),
      tokensSold: currentSold + quantity,
      updatedAt: FieldValue.serverTimestamp()
    };
    // Trava o preço inicial na primeira operação (se ainda não existir)
    if (!startupData.initialPriceCents) {
      startupUpdates.initialPriceCents = initialPriceCents;
    }
    transaction.update(startupRef, startupUpdates);

    // Registra a operação na coleção `tokenOperations` para histórico e auditoria
    // sellerId: "startup:XXX" indica que a venda foi feita pela própria startup
    transaction.set(operationRef, {
      buyerId: userId,
      sellerId: `startup:${startupId}`,
      userId, // Para compatibilidade com queries legadas
      startupId,
      type: "buy",
      quantity,
      pricePerToken,
      totalValue: totalCost,
      status: "completed",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp()
    });

    // Registra o ponto no histórico de preços (usado para gráficos no app)
    const priceHistoryRef = db.collection("tokenPriceHistory").doc(startupId).collection("prices").doc();
    transaction.set(priceHistoryRef, {
      price: newTokenPrice,
      timestamp: FieldValue.serverTimestamp(),
      triggerOperationId: operationRef.id // Liga o preço à operação que o causou
    });
  });

  return { updatedBalance, newTokenPrice };
}

// ════════════════════════════════════════════════════════════════════════════════
// SEÇÃO 5: Venda direta de volta para a startup (transação atômica)
// ════════════════════════════════════════════════════════════════════════════════

/**
 * Venda de tokens diretamente de volta para a startup.
 *
 * WALKTHROUGH — Diferenças da compra:
 * 1. A pressão é de VENDA (recentSellVolume aumenta), fazendo o preço CAIR
 * 2. O saldo do usuário é CREDITADO (em vez de debitado)
 * 3. Os tokens disponíveis da startup AUMENTAM (devolvidos ao estoque)
 * 4. O holding do investidor DIMINUI (pode chegar a 0)
 *
 * EDGE CASE: Se o holding na coleção top-level `holdings` existir, ele tem
 * prioridade sobre a subcoleção legada `investors`. Isso garante consistência
 * para dados migrados recentemente.
 */
export async function sellTokensTransaction(
  userId: string,
  startupId: string,
  quantity: number
): Promise<{ updatedBalance: number; newTokenPrice: number }> {
  // 1. Busca volumes de negociação das últimas 24 horas (pré-transação)
  const { buyVolume, sellVolume } = await getRecentVolume24h(startupId);

  // Inclui a quantidade da operação atual na pressão de venda
  const recentBuyVolume = buyVolume;
  const recentSellVolume = sellVolume + quantity;

  const userRef = db.collection("users").doc(userId);
  const startupRef = db.collection("startups").doc(startupId);
  const investorRef = startupRef.collection("investors").doc(userId);
  const operationRef = db.collection("tokenOperations").doc();

  let updatedBalance = 0;
  let newTokenPrice = 0;

  await db.runTransaction(async (transaction) => {
    // Lê todos os documentos necessários atomicamente
    const userDoc = await transaction.get(userRef);
    const startupDoc = await transaction.get(startupRef);
    const investorDoc = await transaction.get(investorRef);
    const holdingSnapshot = await readHolding(transaction, userId, startupId);

    if (!userDoc.exists) {
      throw new Error("Usuário não encontrado.");
    }
    if (!startupDoc.exists) {
      throw new Error("Startup não encontrada no catálogo.");
    }

    const userData = userDoc.data()!;
    const startupData = startupDoc.data()!;
    const investorData = investorDoc.exists ? investorDoc.data()! : null;

    // Verifica holdings: prioriza coleção top-level `holdings`,
    // fallback para subcoleção legada `investors`
    const legacyHolding = Number(investorData?.tokens ?? 0);
    const currentHolding = holdingSnapshot.exists ? holdingSnapshot.quantity : legacyHolding;

    // Não pode vender se não tem tokens (0 ou menos)
    if (currentHolding <= 0) {
      throw new Error("Insufficient tokens");
    }
    // Não pode vender mais tokens do que possui
    if (currentHolding < quantity) {
      throw new Error("Insufficient tokens");
    }

    // Saldo do usuário em BRL (será creditado com o valor da venda)
    const currentBalance = Number(userData.saldo ?? userData.balance ?? 0);

    // Preço do token em centavos → converte para BRL
    const currentPriceCents = Number(startupData.currentTokenPriceCents ?? 0);
    const pricePerToken = currentPriceCents / 100;
    const saleValue = quantity * pricePerToken;

    // Preço inicial de emissão para cálculo do piso
    const initialPriceCents = Number(startupData.initialPriceCents ?? startupData.currentTokenPriceCents ?? currentPriceCents);
    const initialPrice = initialPriceCents / 100;

    // Calcula o novo preço com pressão de venda (preço tende a cair)
    newTokenPrice = calculateNewPrice(pricePerToken, recentBuyVolume, recentSellVolume, initialPrice);
    const newTokenPriceCents = Math.round(newTokenPrice * 100);

    // Credita o saldo do usuário com o valor da venda
    updatedBalance = currentBalance + saleValue;
    transaction.update(userRef, {
      saldo: updatedBalance,
      balance: updatedBalance
    });

    // Atualiza holdings na subcoleção legada `investors`
    const remainingHolding = currentHolding - quantity;
    if (investorDoc.exists) {
      if (remainingHolding <= 0) {
        // Se vendeu tudo, deleta o documento da subcoleção legada
        // (diferente da coleção top-level, que mantém com qty=0)
        transaction.delete(investorRef);
      } else {
        transaction.update(investorRef, {
          tokens: remainingHolding,
          updatedAt: FieldValue.serverTimestamp()
        });
      }
    }

    // Atualiza holdings na coleção top-level (mantém documento com qty=0 se vendeu tudo)
    applyHoldingSell(transaction, userId, startupId, holdingSnapshot, quantity);

    // Devolve os tokens ao estoque da startup e atualiza o preço
    const currentAvailable = startupData.availableTokens !== undefined ? Number(startupData.availableTokens) : 0;
    const currentSold = startupData.tokensSold !== undefined ? Number(startupData.tokensSold) : Math.max(0, Number(startupData.totalTokensIssued ?? 0) - currentAvailable);
    const startupUpdates: any = {
      currentTokenPriceCents: newTokenPriceCents,
      currentTokenPrice: newTokenPrice,
      availableTokens: currentAvailable + quantity, // Devolve ao estoque
      tokensSold: Math.max(0, currentSold - quantity), // Decrementa vendidos
      updatedAt: FieldValue.serverTimestamp()
    };
    if (!startupData.initialPriceCents) {
      startupUpdates.initialPriceCents = initialPriceCents;
    }
    transaction.update(startupRef, startupUpdates);

    // Registra a operação (sellerId = userId, buyerId = startup)
    transaction.set(operationRef, {
      buyerId: `startup:${startupId}`,
      sellerId: userId,
      userId,
      startupId,
      type: "sell",
      quantity,
      pricePerToken,
      totalValue: saleValue,
      status: "completed",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp()
    });

    // Registra no histórico de preços
    const priceHistoryRef = db.collection("tokenPriceHistory").doc(startupId).collection("prices").doc();
    transaction.set(priceHistoryRef, {
      price: newTokenPrice,
      timestamp: FieldValue.serverTimestamp(),
      triggerOperationId: operationRef.id
    });
  });

  return { updatedBalance, newTokenPrice };
}

// ════════════════════════════════════════════════════════════════════════════════
// SEÇÃO 6: Criação e cancelamento de ofertas no Balcão
// ════════════════════════════════════════════════════════════════════════════════

/**
 * Cria uma nova oferta no Balcão (book de ordens).
 *
 * WALKTHROUGH — Fluxo detalhado:
 *
 * Para ofertas de COMPRA (type="buy"):
 * 1. Calcula o valor total: quantity × pricePerToken
 * 2. Verifica saldo disponível: saldo total - saldo reservado ≥ valor total
 * 3. Reserva o saldo na carteira do usuário (incrementa reservedBalance)
 * 4. Se o preço for abaixo do mercado, define status "pending_approval"
 * 5. Cria o documento da oferta
 *
 * Para ofertas de VENDA (type="sell"):
 * 1. Verifica se o usuário possui tokens suficientes na coleção `holdings`
 * 2. Cria o documento da oferta (sem reservar saldo)
 *
 * EDGE CASE — Preço abaixo do mercado:
 * Se o comprador oferece menos que o preço atual, a oferta fica como
 * "pending_approval" — isso evita que ofertas muito baratas distorçam
 * o preço de mercado. Essas ofertas precisam de match manual ou aprovação.
 */
export async function createBalcaoOffer(
  userId: string,
  startupId: string,
  type: "buy" | "sell",
  quantity: number,
  pricePerToken: number
): Promise<string> {
  const offerRef = db.collection("balcaoOffers").doc();
  const userRef = db.collection("users").doc(userId);
  const startupRef = db.collection("startups").doc(startupId);

  await db.runTransaction(async (transaction) => {
    const userDoc = await transaction.get(userRef);
    const startupDoc = await transaction.get(startupRef);
    // Lê holdings apenas para ofertas de venda (precisa verificar tokens disponíveis)
    const holdingSnapshot = type === "sell"
      ? await readHolding(transaction, userId, startupId)
      : null;

    if (!userDoc.exists) throw new Error("Usuário não encontrado.");
    if (!startupDoc.exists) throw new Error("Startup não encontrada.");

    const userData = userDoc.data()!;
    const startupData = startupDoc.data()!;

    // Saldo total e reservado do usuário
    const currentBalance = Number(userData.saldo ?? userData.balance ?? 0);
    const currentReserved = Number(userData.reservedBalance ?? userData.reserved ?? 0);

    // Preço de mercado atual para comparação
    const priceCents = Number(startupData.currentTokenPriceCents ?? 0);
    const currentMarketPrice = priceCents / 100;

    let status: "open" | "pending_approval" = "open";
    let reservedAmount = 0;

    if (type === "buy") {
      // Calcula o valor a reservar (preço × quantidade)
      reservedAmount = quantity * pricePerToken;

      // Verifica se o saldo DISPONÍVEL (total - já reservado) é suficiente
      if ((currentBalance - currentReserved) < reservedAmount) {
        throw new Error("Saldo disponível insuficiente (descontando outras ofertas reservadas).");
      }

      // Oferta de compra com preço abaixo do mercado → pendente de aprovação
      if (pricePerToken < currentMarketPrice) {
        status = "pending_approval";
      }

      // Incrementa o saldo reservado na carteira do usuário
      const nextReserved = currentReserved + reservedAmount;
      transaction.update(userRef, {
        reservedBalance: nextReserved,
        reserved: nextReserved // Campo legado
      });
    } else {
      // Sell — valida que o usuário tem tokens suficientes
      const heldQuantity = holdingSnapshot ? holdingSnapshot.quantity : 0;
      if (heldQuantity < quantity) {
        throw new Error("Insufficient tokens");
      }
    }

    // Cria o documento da oferta no book de ordens
    transaction.set(offerRef, {
      userId,
      buyerId: type === "buy" ? userId : null,   // Identificação clara do comprador
      sellerId: type === "sell" ? userId : null,  // Identificação clara do vendedor
      startupId,
      type,
      quantity,
      remainingQuantity: quantity, // Começa igual à quantidade total
      pricePerToken,
      reservedAmount,
      status,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp()
    });
  });

  // Retorna o ID da oferta criada
  return offerRef.id;
}

/**
 * Cancela uma oferta aberta/pendente pertencente ao usuário.
 *
 * WALKTHROUGH — Liberação de reserva:
 * Se for uma oferta de COMPRA, o saldo reservado precisa ser devolvido
 * ao saldo disponível do usuário. Sem isso, o dinheiro ficaria "preso"
 * em uma oferta que não existe mais.
 *
 * Math.max(0, ...) previne que o reservedBalance fique negativo em caso
 * de inconsistência (ex: reservedAmount gravado incorretamente em operação anterior).
 */
export async function cancelBalcaoOffer(userId: string, offerId: string): Promise<void> {
  const offerRef = db.collection("balcaoOffers").doc(offerId);
  const userRef = db.collection("users").doc(userId);

  await db.runTransaction(async (transaction) => {
    const offerDoc = await transaction.get(offerRef);
    if (!offerDoc.exists) {
      throw new Error("Oferta não encontrada.");
    }

    const offerData = offerDoc.data()!;

    // Verifica propriedade — só o criador pode cancelar sua própria oferta
    if (offerData.userId !== userId) {
      throw new Error("Você não tem permissão para cancelar esta oferta.");
    }

    // Só pode cancelar ofertas que estão abertas ou pendentes de aprovação
    if (offerData.status !== "open" && offerData.status !== "pending_approval") {
      throw new Error("Esta oferta já foi executada, cancelada ou rejeitada.");
    }

    // Se for oferta de compra, libera o saldo reservado de volta
    if (offerData.type === "buy") {
      const userDoc = await transaction.get(userRef);
      if (userDoc.exists) {
        const userData = userDoc.data()!;
        const currentReserved = Number(userData.reservedBalance ?? userData.reserved ?? 0);
        const reservedAmount = Number(offerData.reservedAmount ?? 0);
        // Math.max(0, ...) garante que nunca fique negativo
        const nextReserved = Math.max(0, currentReserved - reservedAmount);

        transaction.update(userRef, {
          reservedBalance: nextReserved,
          reserved: nextReserved
        });
      }
    }

    // Marca a oferta como cancelada
    transaction.update(offerRef, {
      status: "cancelled",
      updatedAt: FieldValue.serverTimestamp()
    });
  });
}

// ════════════════════════════════════════════════════════════════════════════════
// SEÇÃO 7: Compra casada com ofertas do book de ordens (Greedy Matching)
// ════════════════════════════════════════════════════════════════════════════════

/**
 * Compra tokens casando com múltiplas ofertas de venda ativas de outros usuários.
 *
 * WALKTHROUGH DETALHADO — Algoritmo de Greedy Matching:
 *
 * 1. Busca todas as ofertas de venda "open" para a startup
 * 2. Ordena por preço crescente (mais barato primeiro)
 * 3. Percorre as ofertas, comprando o máximo possível de cada uma:
 *    - Calcula a quantidade a casar (min entre o que quer e o que está disponível)
 *    - Verifica se o comprador tem saldo para esta parcela
 *    - Pula ofertas do próprio comprador (self-trading não é permitido)
 *    - Pula se o vendedor não tem tokens suficientes (inconsistência de dados)
 * 4. Para cada match:
 *    - Transfere tokens: vendedor → comprador (ambas as coleções)
 *    - Credita o vendedor
 *    - Atualiza a oferta (remainingQuantity, status)
 *    - Registra a operação
 * 5. Após todos os matches, debita o total do comprador e atualiza o preço
 *
 * RACE CONDITION: A query inicial (fora da transação) pode retornar ofertas
 * que são modificadas antes da transação executar. O Firestore detecta isso
 * e re-executa a transação automaticamente. A segunda tentativa terá dados frescos.
 *
 * LIMITAÇÃO: O Firestore limita transações a 500 escritas. Em cenários com
 * muitas ofertas pequenas, isso pode ser um gargalo.
 */
export async function buyFromOrdersTransaction(
  buyerId: string,
  startupId: string,
  quantity: number
): Promise<{ filledQuantity: number; totalPaid: number; change: number; operations: string[] }> {
  // Busca ofertas de venda ativas e ordena por preço crescente (greedy: mais barato primeiro)
  const sellOffersSnapshot = await db.collection("balcaoOffers")
    .where("startupId", "==", startupId)
    .where("type", "==", "sell")
    .where("status", "==", "open")
    .get();

  // Converte os documentos para objetos tipados com referência e ordena por preço
  const sellOffers = sellOffersSnapshot.docs.map(doc => {
    const data = doc.data() as BalcaoOfferDoc;
    return {
      id: doc.id,
      ref: doc.ref,
      ...data
    };
  }).sort((a, b) => Number(a.pricePerToken) - Number(b.pricePerToken));

  const buyerRef = db.collection("users").doc(buyerId);
  const startupRef = db.collection("startups").doc(startupId);

  // Acumuladores para o resultado final
  let filledQuantity = 0;  // Total de tokens efetivamente comprados
  let totalPaid = 0;       // Total pago em BRL
  const operationIds: string[] = []; // IDs das operações geradas

  await db.runTransaction(async (transaction) => {
    // Lê dados do comprador e da startup dentro da transação
    const buyerDoc = await transaction.get(buyerRef);
    const startupDoc = await transaction.get(startupRef);

    if (!buyerDoc.exists) throw new Error("Comprador não encontrado.");
    if (!startupDoc.exists) throw new Error("Startup não encontrada.");

    const buyerData = buyerDoc.data()!;
    // Saldo disponível = total - reservado
    const buyerBalance = Number(buyerData.saldo ?? buyerData.balance ?? 0);
    const buyerReserved = Number(buyerData.reservedBalance ?? buyerData.reserved ?? 0);
    const buyerAvailable = buyerBalance - buyerReserved;

    let remainingToBuy = quantity; // Quanto ainda precisa comprar

    // Percorre cada oferta de venda, da mais barata para a mais cara
    for (const offer of sellOffers) {
      if (remainingToBuy <= 0) break; // Já comprou tudo que precisava

      const offerRemaining = Number(offer.remainingQuantity ?? offer.quantity ?? 0);
      if (offerRemaining <= 0) continue; // Oferta já totalmente consumida

      // Impede self-trading (comprar de si mesmo)
      if (offer.userId === buyerId) continue;

      // Calcula a quantidade a casar nesta oferta
      const matchQty = Math.min(remainingToBuy, offerRemaining);
      const matchPrice = Number(offer.pricePerToken);
      const cost = matchQty * matchPrice;

      // Verifica se o comprador tem saldo para esta parcela
      if (buyerAvailable < totalPaid + cost) {
        break; // Para se estourar o saldo disponível
      }

      const sellerId = offer.userId;
      const sellerRef = db.collection("users").doc(sellerId);
      const sellerDoc = await transaction.get(sellerRef);

      if (!sellerDoc.exists) continue; // Vendedor deletado — pula

      // Referências para transferência de tokens (subcoleção legada)
      const buyerInvestorRef = startupRef.collection("investors").doc(buyerId);
      const sellerInvestorRef = startupRef.collection("investors").doc(sellerId);

      const buyerInvestorDoc = await transaction.get(buyerInvestorRef);
      const sellerInvestorDoc = await transaction.get(sellerInvestorRef);

      // Snapshots da coleção top-level `holdings`
      const buyerHoldingSnap = await readHolding(transaction, buyerId, startupId);
      const sellerHoldingSnap = await readHolding(transaction, sellerId, startupId);

      // Holdings legados e novos
      const buyerHolding = buyerInvestorDoc.exists ? Number(buyerInvestorDoc.data()!.tokens ?? 0) : 0;
      const legacySellerHolding = sellerInvestorDoc.exists ? Number(sellerInvestorDoc.data()!.tokens ?? 0) : 0;
      const sellerHolding = sellerHoldingSnap.exists ? sellerHoldingSnap.quantity : legacySellerHolding;

      // Pula se o vendedor tem tokens insuficientes (inconsistência de dados)
      if (sellerHolding < matchQty) {
        continue;
      }

      // Incrementa tokens do comprador (subcoleção legada)
      transaction.set(buyerInvestorRef, {
        userId: buyerId,
        startupId: startupId,
        tokens: buyerHolding + matchQty,
        updatedAt: FieldValue.serverTimestamp()
      }, { merge: true });

      // Decrementa tokens do vendedor (subcoleção legada)
      const remainingSellerHolding = legacySellerHolding - matchQty;
      if (sellerInvestorDoc.exists) {
        if (remainingSellerHolding <= 0) {
          transaction.delete(sellerInvestorRef);
        } else {
          transaction.update(sellerInvestorRef, {
            tokens: remainingSellerHolding,
            updatedAt: FieldValue.serverTimestamp()
          });
        }
      }

      // Atualiza coleção top-level `holdings` (comprador ganha, vendedor perde)
      applyHoldingBuy(
        transaction,
        buyerId,
        startupId,
        buyerHoldingSnap,
        matchQty,
        Math.round(matchPrice * 100) // Converte BRL para centavos
      );
      applyHoldingSell(transaction, sellerId, startupId, sellerHoldingSnap, matchQty);

      // Credita o vendedor com o valor da venda
      const sellerData = sellerDoc.data()!;
      const sellerBalance = Number(sellerData.saldo ?? sellerData.balance ?? 0);
      transaction.update(sellerRef, {
        saldo: sellerBalance + cost,
        balance: sellerBalance + cost
      });

      // Atualiza a oferta de venda (decrementa remainingQuantity)
      const nextOfferRemaining = offerRemaining - matchQty;
      transaction.update(offer.ref, {
        remainingQuantity: nextOfferRemaining,
        // Se a oferta foi totalmente consumida, marca como "matched"
        status: nextOfferRemaining <= 0 ? "matched" : "open",
        updatedAt: FieldValue.serverTimestamp()
      });

      // Registra a operação de match entre investidores
      const operationRef = db.collection("tokenOperations").doc();
      transaction.set(operationRef, {
        buyerId: buyerId,
        sellerId: sellerId,
        userId: buyerId,
        startupId: startupId,
        type: "buy_from_order",
        quantity: matchQty,
        pricePerToken: matchPrice,
        totalValue: cost,
        relatedOfferId: offer.id, // Liga a operação à oferta original
        status: "completed",
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp()
      });

      operationIds.push(operationRef.id);
      totalPaid += cost;
      filledQuantity += matchQty;
      remainingToBuy -= matchQty;
    }

    // Se houve pelo menos um match, debita o comprador e atualiza o preço
    if (filledQuantity > 0) {
      // Debita o valor total gasto do saldo do comprador
      transaction.update(buyerRef, {
        saldo: buyerBalance - totalPaid,
        balance: buyerBalance - totalPaid
      });

      // Recalcula o preço da startup com base no volume acumulado
      const { buyVolume, sellVolume } = await getRecentVolume24h(startupId);
      const recentBuy = buyVolume + filledQuantity;
      const recentSell = sellVolume;

      const startupData = startupDoc.data()!;
      const currentPriceCents = Number(startupData.currentTokenPriceCents ?? 0);
      const currentPrice = currentPriceCents / 100;
      const initialPriceCents = Number(startupData.initialPriceCents ?? startupData.currentTokenPriceCents ?? currentPriceCents);
      const initialPrice = initialPriceCents / 100;

      const newTokenPrice = calculateNewPrice(currentPrice, recentBuy, recentSell, initialPrice);
      const newTokenPriceCents = Math.round(newTokenPrice * 100);

      // Atualiza o preço da startup no catálogo
      const startupUpdates: any = {
        currentTokenPriceCents: newTokenPriceCents,
        currentTokenPrice: newTokenPrice,
        updatedAt: FieldValue.serverTimestamp()
      };
      if (!startupData.initialPriceCents) {
        startupUpdates.initialPriceCents = initialPriceCents;
      }
      transaction.update(startupRef, startupUpdates);

      // Registra o novo preço no histórico
      const priceHistoryRef = db.collection("tokenPriceHistory").doc(startupId).collection("prices").doc();
      transaction.set(priceHistoryRef, {
        price: newTokenPrice,
        timestamp: FieldValue.serverTimestamp(),
        triggerOperationId: operationIds[0] // Liga ao primeiro match da sessão
      });
    }
  });

  return {
    filledQuantity,
    totalPaid,
    change: 0.0, // Sem troco — debitamos apenas o valor exato gasto
    operations: operationIds
  };
}

// ════════════════════════════════════════════════════════════════════════════════
// SEÇÃO 8: Consultas de ofertas e holdings
// ════════════════════════════════════════════════════════════════════════════════

/**
 * Lista as ofertas ativas para uma startup (excluindo as do próprio usuário).
 *
 * WALKTHROUGH — Por que excluir ofertas próprias?
 * Não faz sentido o usuário ver suas próprias ofertas na lista de ofertas
 * disponíveis para match. Ele já pode gerenciá-las pela tela de "Minhas Ofertas".
 * Isso também previne self-trading acidental.
 */
export async function listActiveOffers(
  userId: string | null,
  startupId: string
): Promise<BalcaoOfferDoc[]> {
  // Query filtrando por startup e status "open"
  let query = db.collection("balcaoOffers")
    .where("startupId", "==", startupId)
    .where("status", "==", "open");

  const snapshot = await query.get();
  const offers: BalcaoOfferDoc[] = [];

  snapshot.docs.forEach((doc) => {
    const data = doc.data();

    // Filtra as próprias ofertas do usuário (se logado)
    if (userId && data.userId === userId) {
      return; // Pula — não mostra para si mesmo
    }

    // Mapeia o documento para o tipo BalcaoOfferDoc com conversões numéricas seguras
    offers.push({
      id: doc.id,
      userId: data.userId,
      startupId: data.startupId,
      type: data.type,
      quantity: Number(data.quantity ?? 0),
      remainingQuantity: Number(data.remainingQuantity ?? data.quantity ?? 0),
      pricePerToken: Number(data.pricePerToken ?? 0),
      reservedAmount: Number(data.reservedAmount ?? 0),
      status: data.status,
      createdAt: data.createdAt
    });
  });

  return offers;
}

/**
 * Retorna as holdings (tokens) de um usuário com o preço atual de cada startup.
 *
 * WALKTHROUGH — Estratégia de agregação:
 * 1. Lê da coleção top-level `holdings` (dados novos)
 * 2. Faz fallback para a subcoleção legada `investors` (dados antigos)
 * 3. Agrega usando Map para evitar duplicatas
 * 4. Para cada holding, busca o preço atual da startup no catálogo
 *
 * Isso garante que mesmo usuários com dados antigos (pré-migração)
 * vejam seus tokens na carteira corretamente.
 */
export async function getUserTokenHoldings(userId: string): Promise<any[]> {
  // Map para agregar holdings de ambas as fontes, usando startupId como chave
  const aggregated = new Map<string, number>();

  // 1) Lê da coleção top-level `holdings`
  const holdingsSnap = await db.collection("holdings")
    .where("userId", "==", userId)
    .get();
  holdingsSnap.docs.forEach((doc) => {
    const data = doc.data();
    const sid = String(data.startupId ?? "");
    const qty = Number(data.quantity ?? 0);
    if (sid && qty > 0) aggregated.set(sid, qty);
  });

  // 2) Fallback: lê da subcoleção `investors` usando collectionGroup query
  // Só adiciona se o startupId não já estiver no Map (dados novos têm prioridade)
  const investorsSnap = await db.collectionGroup("investors")
    .where("userId", "==", userId)
    .get();
  investorsSnap.docs.forEach((doc) => {
    const data = doc.data();
    // O startupId é extraído do path do documento pai (startups/{startupId}/investors/{uid})
    const sid = doc.ref.parent.parent ? doc.ref.parent.parent.id : "";
    const qty = Number(data.tokens ?? 0);
    // Só adiciona se não existir na coleção top-level (evita duplicata)
    if (sid && qty > 0 && !aggregated.has(sid)) {
      aggregated.set(sid, qty);
    }
  });

  const holdings: any[] = [];

  // 3) Para cada holding, busca informações atuais da startup
  for (const [startupId, tokens] of aggregated) {
    if (!startupId || tokens <= 0) continue;

    // Busca o preço atual e o nome da startup no catálogo
    const startupDoc = await db.collection("startups").doc(startupId).get();
    let currentPrice = 0;
    let startupName = "Startup";
    let tokenSymbol = startupId.toUpperCase().slice(0, 4); // Fallback: 4 letras do ID

    if (startupDoc.exists) {
      const sData = startupDoc.data()!;
      startupName = sData.name ?? "Startup";
      currentPrice = Number(sData.currentTokenPriceCents ?? 0) / 100;
      tokenSymbol = sData.tokenSymbol ?? tokenSymbol;
    }

    // Monta o objeto de holding com dados enriquecidos para o app
    holdings.push({
      startupId,
      startupName,
      tokenSymbol,
      tokens,               // Campo legado
      quantity: tokens,      // Campo novo (mesmo valor, nomes diferentes para retrocompat)
      pricePerToken: currentPrice,
      currentPrice,
      totalValue: tokens * currentPrice // Valor total da posição em BRL
    });
  }

  return holdings;
}

// ════════════════════════════════════════════════════════════════════════════════
// SEÇÃO 9: Histórico de preços
// ════════════════════════════════════════════════════════════════════════════════

/**
 * Retorna o histórico de preços de uma startup, filtrado por período.
 *
 * WALKTHROUGH — Filtros de período:
 * - "daily": últimas 24 horas
 * - "weekly": últimos 7 dias
 * - "monthly": últimos 30 dias
 * - "6months": últimos 180 dias
 * - "ytd": desde 1º de janeiro do ano atual (Year To Date)
 * - "all": sem filtro (todo o histórico)
 * - sem período: todo o histórico
 *
 * Os dados são retornados em ordem cronológica (ASC) para facilitar
 * a renderização de gráficos de linha no app Flutter.
 */
export async function getPriceHistory(
  startupId: string,
  period?: string
): Promise<any[]> {
  // Referência à subcoleção de preços da startup
  const pricesRef = db.collection("tokenPriceHistory").doc(startupId).collection("prices");

  // Query base: ordena por timestamp ascendente (do mais antigo para o mais recente)
  let query = pricesRef.orderBy("timestamp", "asc");

  // Aplica filtro de período se especificado
  if (period) {
    let cutoffDate = new Date();
    switch (period) {
      case "daily":
        cutoffDate.setHours(cutoffDate.getHours() - 24);
        break;
      case "weekly":
        cutoffDate.setDate(cutoffDate.getDate() - 7);
        break;
      case "monthly":
        cutoffDate.setDate(cutoffDate.getDate() - 30);
        break;
      case "6months":
        cutoffDate.setDate(cutoffDate.getDate() - 180);
        break;
      case "ytd":
        // Year To Date: primeiro dia do ano atual
        cutoffDate = new Date(new Date().getFullYear(), 0, 1);
        break;
      default:
        // Período desconhecido → sem filtro (retorna tudo)
        break;
    }
    
    // Se selecionou um período válido (diferente de "all"), aplica o filtro temporal
    if (period !== "all") {
      query = query.where("timestamp", ">=", Timestamp.fromDate(cutoffDate));
    }
  }

  // Executa a query e mapeia os documentos para o formato de resposta
  const snapshot = await query.get();
  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      price: Number(data.price ?? 0),
      // Converte Timestamp do Firestore para string ISO (serializável em JSON)
      // Usa optional chaining para lidar com campos null/undefined
      timestamp: data.timestamp?.toDate?.()?.toISOString?.() ?? data.timestamp,
      triggerOperationId: data.triggerOperationId ?? ""
    };
  });
}
