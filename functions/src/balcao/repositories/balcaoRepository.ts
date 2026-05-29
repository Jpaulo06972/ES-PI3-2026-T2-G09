// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import { db } from "../../shared/firebase";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { calculateNewPrice } from "../services/priceEngine";

export interface TokenOperationDoc {
  id?: string;
  buyerId?: string;
  sellerId?: string;
  userId: string; // Para compatibilidade
  startupId: string;
  type: "buy" | "sell" | "buy_from_order" | "sell_via_order";
  quantity: number;
  pricePerToken: number; // em BRL
  totalValue: number;    // em BRL
  status: "completed" | "pending" | "cancelled";
  createdAt: any;
  updatedAt: any;
  relatedOfferId?: string | null;
}

export interface BalcaoOfferDoc {
  id?: string;
  userId: string;
  buyerId?: string | null;
  sellerId?: string | null;
  startupId: string;
  type: "buy" | "sell";
  quantity: number;
  remainingQuantity: number;
  pricePerToken: number; // em BRL
  reservedAmount: number; // em BRL
  status: "open" | "pending_approval" | "matched" | "cancelled" | "rejected";
  createdAt: any;
  updatedAt?: any;
}

/**
 * Recupera o volume negociado (compras e vendas separadas) nas últimas 24 horas para uma startup.
 */
async function getRecentVolume24h(startupId: string): Promise<{ buyVolume: number; sellVolume: number }> {
  const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
  const snapshot = await db.collection("tokenOperations")
    .where("startupId", "==", startupId)
    .where("status", "==", "completed")
    .where("createdAt", ">=", Timestamp.fromDate(oneDayAgo))
    .get();

  let buyVolume = 0;
  let sellVolume = 0;

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

/**
 * Compra de tokens diretamente da startup atomically (Venda direta).
 */
export async function buyTokensTransaction(
  userId: string,
  startupId: string,
  quantity: number
): Promise<{ updatedBalance: number; newTokenPrice: number }> {
  // 1. Busca volumes de negociação das últimas 24 horas antes da transação
  const { buyVolume, sellVolume } = await getRecentVolume24h(startupId);

  // Inclui a quantidade da operação atual no cálculo da pressão recente
  const recentBuyVolume = buyVolume + quantity;
  const recentSellVolume = sellVolume;

  const userRef = db.collection("users").doc(userId);
  const startupRef = db.collection("startups").doc(startupId);
  const investorRef = startupRef.collection("investors").doc(userId);
  const operationRef = db.collection("tokenOperations").doc();

  let updatedBalance = 0;
  let newTokenPrice = 0;

  await db.runTransaction(async (transaction) => {
    const userDoc = await transaction.get(userRef);
    const startupDoc = await transaction.get(startupRef);
    const investorDoc = await transaction.get(investorRef);

    if (!userDoc.exists) {
      throw new Error("Usuário não encontrado.");
    }
    if (!startupDoc.exists) {
      throw new Error("Startup não encontrada no catálogo.");
    }

    const userData = userDoc.data()!;
    const startupData = startupDoc.data()!;

    // Verifica se a startup possui tokens disponíveis em estoque
    const currentAvailable = startupData.availableTokens !== undefined ? Number(startupData.availableTokens) : 999999;
    const currentSold = startupData.tokensSold !== undefined ? Number(startupData.tokensSold) : Math.max(0, Number(startupData.totalTokensIssued ?? 0) - currentAvailable);
    if (currentAvailable < quantity) {
      throw new Error(`A startup não possui tokens suficientes disponíveis para venda direta. Disponível: ${currentAvailable}`);
    }

    // Saldo do usuário (disponível = total - reservado)
    const totalBalance = Number(userData.saldo ?? userData.balance ?? 0);
    const reservedBalance = Number(userData.reservedBalance ?? userData.reserved ?? 0);
    const availableBalance = totalBalance - reservedBalance;

    // Preço do token da startup (armazenado em centavos no modelo do Tomás)
    const currentPriceCents = Number(startupData.currentTokenPriceCents ?? 0);
    const pricePerToken = currentPriceCents / 100;
    const totalCost = quantity * pricePerToken;

    if (availableBalance < totalCost) {
      throw new Error("Saldo insuficiente para realizar esta compra.");
    }

    // Calcula o preço inicial de emissão (trava no primeiro trade se não existir)
    const initialPriceCents = Number(startupData.initialPriceCents ?? startupData.currentTokenPriceCents ?? currentPriceCents);
    const initialPrice = initialPriceCents / 100;

    // Calcula o novo preço com base na variação linear por pressão de mercado
    newTokenPrice = calculateNewPrice(pricePerToken, recentBuyVolume, recentSellVolume, initialPrice);
    const newTokenPriceCents = Math.round(newTokenPrice * 100);

    // Atualiza o saldo do usuário
    updatedBalance = totalBalance - totalCost;
    transaction.update(userRef, {
      saldo: updatedBalance,
      balance: updatedBalance
    });

    // Atualiza as participações de tokens (investors subcollection)
    const currentHolding = investorDoc.exists ? Number(investorDoc.data()!.tokens ?? 0) : 0;
    transaction.set(investorRef, {
      userId: userId,
      startupId: startupId,
      tokens: currentHolding + quantity,
      updatedAt: FieldValue.serverTimestamp()
    }, { merge: true });

    // Atualiza a startup no catálogo (Preço, Preço em centavos e tokens disponíveis)
    const startupUpdates: any = {
      currentTokenPriceCents: newTokenPriceCents,
      currentTokenPrice: newTokenPrice, // BRL double
      availableTokens: Math.max(0, currentAvailable - quantity),
      tokensSold: currentSold + quantity,
      updatedAt: FieldValue.serverTimestamp()
    };
    if (!startupData.initialPriceCents) {
      startupUpdates.initialPriceCents = initialPriceCents;
    }
    transaction.update(startupRef, startupUpdates);

    // Registra a operação na nova coleção tokenOperations
    transaction.set(operationRef, {
      buyerId: userId,
      sellerId: `startup:${startupId}`,
      userId, // Para compatibilidade
      startupId,
      type: "buy",
      quantity,
      pricePerToken,
      totalValue: totalCost,
      status: "completed",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp()
    });

    // Registra o histórico de preço da startup
    const priceHistoryRef = db.collection("tokenPriceHistory").doc(startupId).collection("prices").doc();
    transaction.set(priceHistoryRef, {
      price: newTokenPrice,
      timestamp: FieldValue.serverTimestamp(),
      triggerOperationId: operationRef.id
    });
  });

  return { updatedBalance, newTokenPrice };
}

/**
 * Venda de tokens diretamente de volta para a startup atomically.
 */
export async function sellTokensTransaction(
  userId: string,
  startupId: string,
  quantity: number
): Promise<{ updatedBalance: number; newTokenPrice: number }> {
  // 1. Busca volumes de negociação das últimas 24 horas antes da transação
  const { buyVolume, sellVolume } = await getRecentVolume24h(startupId);

  // Inclui a quantidade da operação atual no cálculo da pressão recente
  const recentBuyVolume = buyVolume;
  const recentSellVolume = sellVolume + quantity;

  const userRef = db.collection("users").doc(userId);
  const startupRef = db.collection("startups").doc(startupId);
  const investorRef = startupRef.collection("investors").doc(userId);
  const operationRef = db.collection("tokenOperations").doc();

  let updatedBalance = 0;
  let newTokenPrice = 0;

  await db.runTransaction(async (transaction) => {
    const userDoc = await transaction.get(userRef);
    const startupDoc = await transaction.get(startupRef);
    const investorDoc = await transaction.get(investorRef);

    if (!userDoc.exists) {
      throw new Error("Usuário não encontrado.");
    }
    if (!startupDoc.exists) {
      throw new Error("Startup não encontrada no catálogo.");
    }
    if (!investorDoc.exists) {
      throw new Error("Você não possui tokens desta startup para vender.");
    }

    const userData = userDoc.data()!;
    const startupData = startupDoc.data()!;
    const investorData = investorDoc.data()!;

    // Verifica holdings de tokens do investidor
    const currentHolding = Number(investorData.tokens ?? 0);
    if (currentHolding < quantity) {
      throw new Error("Você não possui tokens suficientes para esta venda.");
    }

    // Saldo do usuário em BRL
    const currentBalance = Number(userData.saldo ?? userData.balance ?? 0);

    // Preço do token em centavos
    const currentPriceCents = Number(startupData.currentTokenPriceCents ?? 0);
    const pricePerToken = currentPriceCents / 100;
    const saleValue = quantity * pricePerToken;

    // Calcula o preço inicial de emissão (trava se não existir)
    const initialPriceCents = Number(startupData.initialPriceCents ?? startupData.currentTokenPriceCents ?? currentPriceCents);
    const initialPrice = initialPriceCents / 100;

    // Calcula o novo preço baseado na pressão de venda
    newTokenPrice = calculateNewPrice(pricePerToken, recentBuyVolume, recentSellVolume, initialPrice);
    const newTokenPriceCents = Math.round(newTokenPrice * 100);

    // Atualiza o saldo do usuário
    updatedBalance = currentBalance + saleValue;
    transaction.update(userRef, {
      saldo: updatedBalance,
      balance: updatedBalance
    });

    // Atualiza holdings de tokens
    const remainingHolding = currentHolding - quantity;
    if (remainingHolding <= 0) {
      transaction.delete(investorRef);
    } else {
      transaction.update(investorRef, {
        tokens: remainingHolding,
        updatedAt: FieldValue.serverTimestamp()
      });
    }

    // Atualiza o preço da startup e incrementa os tokens disponíveis (devolvidos ao catálogo)
    const currentAvailable = startupData.availableTokens !== undefined ? Number(startupData.availableTokens) : 0;
    const currentSold = startupData.tokensSold !== undefined ? Number(startupData.tokensSold) : Math.max(0, Number(startupData.totalTokensIssued ?? 0) - currentAvailable);
    const startupUpdates: any = {
      currentTokenPriceCents: newTokenPriceCents,
      currentTokenPrice: newTokenPrice, // BRL double
      availableTokens: currentAvailable + quantity,
      tokensSold: Math.max(0, currentSold - quantity),
      updatedAt: FieldValue.serverTimestamp()
    };
    if (!startupData.initialPriceCents) {
      startupUpdates.initialPriceCents = initialPriceCents;
    }
    transaction.update(startupRef, startupUpdates);

    // Registra a operação na coleção tokenOperations
    transaction.set(operationRef, {
      buyerId: `startup:${startupId}`,
      sellerId: userId,
      userId, // Para compatibilidade
      startupId,
      type: "sell",
      quantity,
      pricePerToken,
      totalValue: saleValue,
      status: "completed",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp()
    });

    // Registra o histórico de preço da startup
    const priceHistoryRef = db.collection("tokenPriceHistory").doc(startupId).collection("prices").doc();
    transaction.set(priceHistoryRef, {
      price: newTokenPrice,
      timestamp: FieldValue.serverTimestamp(),
      triggerOperationId: operationRef.id
    });
  });

  return { updatedBalance, newTokenPrice };
}

/**
 * Cria uma nova oferta no Balcão.
 * Se for oferta de compra (tipo buy), reserva o saldo da carteira do usuário.
 * Se o preço for abaixo do mercado, cria a oferta com status pending_approval.
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

    if (!userDoc.exists) throw new Error("Usuário não encontrado.");
    if (!startupDoc.exists) throw new Error("Startup não encontrada.");

    const userData = userDoc.data()!;
    const startupData = startupDoc.data()!;

    const currentBalance = Number(userData.saldo ?? userData.balance ?? 0);
    const currentReserved = Number(userData.reservedBalance ?? userData.reserved ?? 0);

    const priceCents = Number(startupData.currentTokenPriceCents ?? 0);
    const currentMarketPrice = priceCents / 100;

    let status: "open" | "pending_approval" = "open";
    let reservedAmount = 0;

    if (type === "buy") {
      reservedAmount = quantity * pricePerToken;
      if ((currentBalance - currentReserved) < reservedAmount) {
        throw new Error("Saldo disponível insuficiente (descontando outras ofertas reservadas).");
      }

      // Se o preço for abaixo do mercado, define como pendente de aprovação
      if (pricePerToken < currentMarketPrice) {
        status = "pending_approval";
      }

      const nextReserved = currentReserved + reservedAmount;
      transaction.update(userRef, {
        reservedBalance: nextReserved,
        reserved: nextReserved
      });
    }

    transaction.set(offerRef, {
      userId,
      buyerId: type === "buy" ? userId : null,
      sellerId: type === "sell" ? userId : null,
      startupId,
      type,
      quantity,
      remainingQuantity: quantity,
      pricePerToken,
      reservedAmount,
      status,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp()
    });
  });

  return offerRef.id;
}

/**
 * Cancela uma oferta aberta/pendente pertencente ao usuário.
 * Se for oferta de compra (tipo buy), libera a reserva de saldo do usuário.
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
    if (offerData.userId !== userId) {
      throw new Error("Você não tem permissão para cancelar esta oferta.");
    }
    if (offerData.status !== "open" && offerData.status !== "pending_approval") {
      throw new Error("Esta oferta já foi executada, cancelada ou rejeitada.");
    }

    // Se for oferta de compra, libera a reserva de saldo na carteira
    if (offerData.type === "buy") {
      const userDoc = await transaction.get(userRef);
      if (userDoc.exists) {
        const userData = userDoc.data()!;
        const currentReserved = Number(userData.reservedBalance ?? userData.reserved ?? 0);
        const reservedAmount = Number(offerData.reservedAmount ?? 0);
        const nextReserved = Math.max(0, currentReserved - reservedAmount);

        transaction.update(userRef, {
          reservedBalance: nextReserved,
          reserved: nextReserved
        });
      }
    }

    transaction.update(offerRef, {
      status: "cancelled",
      updatedAt: FieldValue.serverTimestamp()
    });
  });
}

/**
 * Compra tokens casando com múltiplas ofertas de venda ativas de outros usuários.
 * Preenche da mais barata para a mais cara (Greedy matching).
 */
export async function buyFromOrdersTransaction(
  buyerId: string,
  startupId: string,
  quantity: number
): Promise<{ filledQuantity: number; totalPaid: number; change: number; operations: string[] }> {
  // Busca ofertas de venda ativas e ordena por preço crescente (mais barato primeiro)
  const sellOffersSnapshot = await db.collection("balcaoOffers")
    .where("startupId", "==", startupId)
    .where("type", "==", "sell")
    .where("status", "==", "open")
    .get();

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

  let filledQuantity = 0;
  let totalPaid = 0;
  const operationIds: string[] = [];

  await db.runTransaction(async (transaction) => {
    const buyerDoc = await transaction.get(buyerRef);
    const startupDoc = await transaction.get(startupRef);

    if (!buyerDoc.exists) throw new Error("Comprador não encontrado.");
    if (!startupDoc.exists) throw new Error("Startup não encontrada.");

    const buyerData = buyerDoc.data()!;
    const buyerBalance = Number(buyerData.saldo ?? buyerData.balance ?? 0);
    const buyerReserved = Number(buyerData.reservedBalance ?? buyerData.reserved ?? 0);
    const buyerAvailable = buyerBalance - buyerReserved;

    let remainingToBuy = quantity;

    for (const offer of sellOffers) {
      if (remainingToBuy <= 0) break;

      const offerRemaining = Number(offer.remainingQuantity ?? offer.quantity ?? 0);
      if (offerRemaining <= 0) continue;

      // Impede comprar de si mesmo
      if (offer.userId === buyerId) continue;

      const matchQty = Math.min(remainingToBuy, offerRemaining);
      const matchPrice = Number(offer.pricePerToken);
      const cost = matchQty * matchPrice;

      if (buyerAvailable < totalPaid + cost) {
        // Para se estourar o saldo disponível restante do comprador
        break;
      }

      const sellerId = offer.userId;
      const sellerRef = db.collection("users").doc(sellerId);
      const sellerDoc = await transaction.get(sellerRef);

      if (!sellerDoc.exists) continue;

      // Transferência de tokens na subcoleção "investors"
      const buyerInvestorRef = startupRef.collection("investors").doc(buyerId);
      const sellerInvestorRef = startupRef.collection("investors").doc(sellerId);

      const buyerInvestorDoc = await transaction.get(buyerInvestorRef);
      const sellerInvestorDoc = await transaction.get(sellerInvestorRef);

      const buyerHolding = buyerInvestorDoc.exists ? Number(buyerInvestorDoc.data()!.tokens ?? 0) : 0;
      const sellerHolding = sellerInvestorDoc.exists ? Number(sellerInvestorDoc.data()!.tokens ?? 0) : 0;

      if (sellerHolding < matchQty) {
        // Vendedor com tokens insuficientes (inconsistência no banco), pula
        continue;
      }

      // Atualiza holdings do comprador
      transaction.set(buyerInvestorRef, {
        userId: buyerId,
        startupId: startupId,
        tokens: buyerHolding + matchQty,
        updatedAt: FieldValue.serverTimestamp()
      }, { merge: true });

      // Atualiza holdings do vendedor
      const remainingSellerHolding = sellerHolding - matchQty;
      if (remainingSellerHolding <= 0) {
        transaction.delete(sellerInvestorRef);
      } else {
        transaction.update(sellerInvestorRef, {
          tokens: remainingSellerHolding,
          updatedAt: FieldValue.serverTimestamp()
        });
      }

      // Credita o vendedor
      const sellerData = sellerDoc.data()!;
      const sellerBalance = Number(sellerData.saldo ?? sellerData.balance ?? 0);
      transaction.update(sellerRef, {
        saldo: sellerBalance + cost,
        balance: sellerBalance + cost
      });

      // Atualiza a oferta de venda
      const nextOfferRemaining = offerRemaining - matchQty;
      transaction.update(offer.ref, {
        remainingQuantity: nextOfferRemaining,
        status: nextOfferRemaining <= 0 ? "matched" : "open",
        updatedAt: FieldValue.serverTimestamp()
      });

      // Registra a operação atômica de troca de tokens entre investidores
      const operationRef = db.collection("tokenOperations").doc();
      transaction.set(operationRef, {
        buyerId: buyerId,
        sellerId: sellerId,
        userId: buyerId, // Para compatibilidade
        startupId: startupId,
        type: "buy_from_order",
        quantity: matchQty,
        pricePerToken: matchPrice,
        totalValue: cost,
        relatedOfferId: offer.id,
        status: "completed",
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp()
      });

      operationIds.push(operationRef.id);
      totalPaid += cost;
      filledQuantity += matchQty;
      remainingToBuy -= matchQty;
    }

    if (filledQuantity > 0) {
      // Deduz o saldo do comprador
      transaction.update(buyerRef, {
        saldo: buyerBalance - totalPaid,
        balance: buyerBalance - totalPaid
      });

      // Atualiza o motor de preço com base na pressão recente
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

      const startupUpdates: any = {
        currentTokenPriceCents: newTokenPriceCents,
        currentTokenPrice: newTokenPrice, // BRL double
        updatedAt: FieldValue.serverTimestamp()
      };
      if (!startupData.initialPriceCents) {
        startupUpdates.initialPriceCents = initialPriceCents;
      }
      transaction.update(startupRef, startupUpdates);

      // Histórico de preços
      const priceHistoryRef = db.collection("tokenPriceHistory").doc(startupId).collection("prices").doc();
      transaction.set(priceHistoryRef, {
        price: newTokenPrice,
        timestamp: FieldValue.serverTimestamp(),
        triggerOperationId: operationIds[0]
      });
    }
  });

  return {
    filledQuantity,
    totalPaid,
    change: 0.0, // Como apenas debitamos o valor exato gasto, não há troco pendente
    operations: operationIds
  };
}

/**
 * Vendedor aprova uma oferta de compra pendente (mesmo abaixo do preço de mercado).
 * Executa as wallet transfers e token transfers de forma atômica.
 */
export async function approvePendingOfferTransaction(
  sellerId: string,
  offerId: string
): Promise<{ success: boolean; totalPaid: number; matchQty: number }> {
  const offerRef = db.collection("balcaoOffers").doc(offerId);
  const sellerRef = db.collection("users").doc(sellerId);

  let totalPaid = 0;
  let matchQty = 0;

  await db.runTransaction(async (transaction) => {
    const offerDoc = await transaction.get(offerRef);
    if (!offerDoc.exists) throw new Error("Oferta do comprador não encontrada.");

    const offerData = offerDoc.data()!;
    if (offerData.status !== "pending_approval") {
      throw new Error("Esta oferta não está mais pendente de aprovação.");
    }
    if (offerData.type !== "buy") {
      throw new Error("Apenas ofertas de compra podem ser aprovadas pelo vendedor.");
    }

    const startupId = offerData.startupId;
    const buyerId = offerData.userId;
    const buyerRef = db.collection("users").doc(buyerId);

    const buyerDoc = await transaction.get(buyerRef);
    const sellerDoc = await transaction.get(sellerRef);
    const startupRef = db.collection("startups").doc(startupId);
    const startupDoc = await transaction.get(startupRef);

    if (!buyerDoc.exists) throw new Error("Comprador não encontrado.");
    if (!sellerDoc.exists) throw new Error("Vendedor não encontrado.");
    if (!startupDoc.exists) throw new Error("Startup não encontrada.");

    // Busca oferta de venda correspondente ativa/aberta deste vendedor para casar
    const sellOffersSnapshot = await db.collection("balcaoOffers")
      .where("startupId", "==", startupId)
      .where("userId", "==", sellerId)
      .where("type", "==", "sell")
      .where("status", "==", "open")
      .limit(1)
      .get();

    if (sellOffersSnapshot.empty) {
      throw new Error("Você precisa ter uma oferta de venda ativa/aberta para esta startup no Balcão para aprovar lances.");
    }

    const sellerOfferDoc = sellOffersSnapshot.docs[0];
    const sellerOfferData = sellerOfferDoc.data();
    const sellerOfferRemaining = Number(sellerOfferData.remainingQuantity ?? sellerOfferData.quantity ?? 0);

    const buyerOfferRemaining = Number(offerData.remainingQuantity ?? offerData.quantity ?? 0);
    const price = Number(offerData.pricePerToken);

    matchQty = Math.min(buyerOfferRemaining, sellerOfferRemaining);
    totalPaid = matchQty * price;

    // Transfere tokens na subcoleção "investors"
    const buyerInvestorRef = startupRef.collection("investors").doc(buyerId);
    const sellerInvestorRef = startupRef.collection("investors").doc(sellerId);

    const buyerInvestorDoc = await transaction.get(buyerInvestorRef);
    const sellerInvestorDoc = await transaction.get(sellerInvestorRef);

    const buyerHolding = buyerInvestorDoc.exists ? Number(buyerInvestorDoc.data()!.tokens ?? 0) : 0;
    const sellerHolding = sellerInvestorDoc.exists ? Number(sellerInvestorDoc.data()!.tokens ?? 0) : 0;

    if (sellerHolding < matchQty) {
      throw new Error("Você não possui tokens suficientes na carteira para cobrir esta aprovação.");
    }

    // 1. Atualiza holdings de investidores
    transaction.set(buyerInvestorRef, {
      userId: buyerId,
      startupId: startupId,
      tokens: buyerHolding + matchQty,
      updatedAt: FieldValue.serverTimestamp()
    }, { merge: true });

    const remainingSellerHolding = sellerHolding - matchQty;
    if (remainingSellerHolding <= 0) {
      transaction.delete(sellerInvestorRef);
    } else {
      transaction.update(sellerInvestorRef, {
        tokens: remainingSellerHolding,
        updatedAt: FieldValue.serverTimestamp()
      });
    }

    // 2. Transfere fundos da carteira do comprador (que estavam reservados) para o vendedor
    const buyerData = buyerDoc.data()!;
    const buyerBalance = Number(buyerData.saldo ?? buyerData.balance ?? 0);
    const buyerReserved = Number(buyerData.reservedBalance ?? buyerData.reserved ?? 0);

    const sellerData = sellerDoc.data()!;
    const sellerBalance = Number(sellerData.saldo ?? sellerData.balance ?? 0);

    // Deduz do comprador (e diminui o reservado correspondente)
    const nextBuyerBalance = buyerBalance - totalPaid;
    const nextBuyerReserved = Math.max(0, buyerReserved - totalPaid);

    transaction.update(buyerRef, {
      saldo: nextBuyerBalance,
      balance: nextBuyerBalance,
      reservedBalance: nextBuyerReserved,
      reserved: nextBuyerReserved
    });

    // Credita o vendedor
    transaction.update(sellerRef, {
      saldo: sellerBalance + totalPaid,
      balance: sellerBalance + totalPaid
    });

    // 3. Atualiza estado das duas ofertas de balcão
    const nextBuyerRemaining = buyerOfferRemaining - matchQty;
    const nextBuyerOfferReserved = Math.max(0, Number(offerData.reservedAmount ?? 0) - totalPaid);

    transaction.update(offerRef, {
      remainingQuantity: nextBuyerRemaining,
      reservedAmount: nextBuyerOfferReserved,
      status: nextBuyerRemaining <= 0 ? "matched" : "pending_approval",
      updatedAt: FieldValue.serverTimestamp()
    });

    const nextSellerRemaining = sellerOfferRemaining - matchQty;
    transaction.update(sellerOfferDoc.ref, {
      remainingQuantity: nextSellerRemaining,
      status: nextSellerRemaining <= 0 ? "matched" : "open",
      updatedAt: FieldValue.serverTimestamp()
    });

    // 4. Cria completed tokenOperation
    const operationRef = db.collection("tokenOperations").doc();
    transaction.set(operationRef, {
      buyerId: buyerId,
      sellerId: sellerId,
      userId: buyerId, // Para compatibilidade
      startupId: startupId,
      type: "buy_from_order",
      quantity: matchQty,
      pricePerToken: price,
      totalValue: totalPaid,
      relatedOfferId: offerId,
      status: "completed",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp()
    });

    // 5. Atualiza o preço da startup (motor de preço)
    const { buyVolume, sellVolume } = await getRecentVolume24h(startupId);
    const recentBuy = buyVolume + matchQty;
    const recentSell = sellVolume;

    const startupUpdates: any = {
      currentTokenPriceCents: Math.round(calculateNewPrice(price, recentBuy, recentSell, price) * 100),
      currentTokenPrice: calculateNewPrice(price, recentBuy, recentSell, price), // BRL double
      updatedAt: FieldValue.serverTimestamp()
    };
    transaction.update(startupRef, startupUpdates);

    // Registra histórico de preços
    const priceHistoryRef = db.collection("tokenPriceHistory").doc(startupId).collection("prices").doc();
    transaction.set(priceHistoryRef, {
      price: startupUpdates.currentTokenPrice,
      timestamp: FieldValue.serverTimestamp(),
      triggerOperationId: operationRef.id
    });
  });

  return { success: true, totalPaid, matchQty };
}

/**
 * Rejeita uma oferta de compra abaixo do mercado.
 * Libera a reserva correspondente na carteira do comprador.
 */
export async function rejectPendingOfferTransaction(
  sellerId: string,
  offerId: string
): Promise<void> {
  const offerRef = db.collection("balcaoOffers").doc(offerId);

  await db.runTransaction(async (transaction) => {
    const offerDoc = await transaction.get(offerRef);
    if (!offerDoc.exists) throw new Error("Oferta do comprador não encontrada.");

    const offerData = offerDoc.data()!;
    if (offerData.status !== "pending_approval") {
      throw new Error("Esta oferta não está mais pendente de aprovação.");
    }

    const buyerId = offerData.userId;
    const buyerRef = db.collection("users").doc(buyerId);
    const buyerDoc = await transaction.get(buyerRef);

    // Desfaz reserva de saldo
    if (buyerDoc.exists) {
      const buyerData = buyerDoc.data()!;
      const currentReserved = Number(buyerData.reservedBalance ?? buyerData.reserved ?? 0);
      const reservedAmount = Number(offerData.reservedAmount ?? 0);
      const nextReserved = Math.max(0, currentReserved - reservedAmount);

      transaction.update(buyerRef, {
        reservedBalance: nextReserved,
        reserved: nextReserved
      });
    }

    transaction.update(offerRef, {
      status: "rejected",
      updatedAt: FieldValue.serverTimestamp()
    });
  });
}

/**
 * Obtém lances de compra pendentes direcionados às startups onde o vendedor tem oferta de venda aberta.
 */
export async function getPendingApprovals(sellerId: string): Promise<any[]> {
  // Busca todas as ofertas de venda abertas criadas por este vendedor
  const mySellOffersSnapshot = await db.collection("balcaoOffers")
    .where("userId", "==", sellerId)
    .where("type", "==", "sell")
    .where("status", "==", "open")
    .get();

  if (mySellOffersSnapshot.empty) return [];

  // Agrupa os IDs de startups que têm ofertas abertas por este vendedor
  const startupIds = Array.from(new Set(mySellOffersSnapshot.docs.map(doc => doc.data().startupId)));

  // Busca lances de compra com status pending_approval para essas startups
  const pendingBuySnapshot = await db.collection("balcaoOffers")
    .where("type", "==", "buy")
    .where("status", "==", "pending_approval")
    .where("startupId", "in", startupIds)
    .get();

  const pendingOffers: any[] = [];

  for (const doc of pendingBuySnapshot.docs) {
    const data = doc.data();
    const buyerId = data.userId;
    const sId = data.startupId;

    // Impede aceitar ofertas criadas por si mesmo
    if (buyerId === sellerId) continue;

    // Recupera dados do comprador e da startup correspondente
    const buyerDoc = await db.collection("users").doc(buyerId).get();
    const startupDoc = await db.collection("startups").doc(sId).get();

    const buyerName = buyerDoc.exists ? `${buyerDoc.data()!.firstName ?? "Comprador"} ${buyerDoc.data()!.lastName ?? ""}`.trim() : "Comprador Anônimo";
    const startupName = startupDoc.exists ? (startupDoc.data()!.name ?? "Startup") : "Startup";
    const currentPriceCents = startupDoc.exists ? Number(startupDoc.data()!.currentTokenPriceCents ?? 0) : 0;
    const currentMarketPrice = currentPriceCents / 100;

    const offerPrice = Number(data.pricePerToken ?? 0);
    const discountPercent = currentMarketPrice > 0 ? Math.round(((currentMarketPrice - offerPrice) / currentMarketPrice) * 100) : 0;

    pendingOffers.push({
      id: doc.id,
      buyerId,
      buyerName,
      startupId: sId,
      startupName,
      quantity: Number(data.quantity ?? 0),
      pricePerToken: offerPrice,
      currentMarketPrice,
      discountPercent,
      createdAt: data.createdAt?.toDate?.()?.toISOString?.() ?? data.createdAt
    });
  }

  return pendingOffers;
}

/**
 * Lista as ofertas ativas para uma startup (excluindo as do próprio usuário).
 */
export async function listActiveOffers(
  userId: string | null,
  startupId: string
): Promise<BalcaoOfferDoc[]> {
  let query = db.collection("balcaoOffers")
    .where("startupId", "==", startupId)
    .where("status", "==", "open");

  const snapshot = await query.get();
  const offers: BalcaoOfferDoc[] = [];

  snapshot.docs.forEach((doc) => {
    const data = doc.data();
    // Filtra ofertas do próprio usuário
    if (userId && data.userId === userId) {
      return;
    }

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
 * Retorna as holdings (tokens) de um usuário com o preço atual.
 */
export async function getUserTokenHoldings(userId: string): Promise<any[]> {
  const snapshot = await db.collectionGroup("investors")
    .where("userId", "==", userId)
    .get();

  const holdings: any[] = [];

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const tokens = Number(data.tokens ?? 0);
    const startupId = doc.ref.parent.parent ? doc.ref.parent.parent.id : "";

    if (!startupId || tokens <= 0) continue;

    // Busca o preço atual do catálogo de startups
    const startupDoc = await db.collection("startups").doc(startupId).get();
    let currentPrice = 0;
    let startupName = "Startup";
    let tokenSymbol = startupId.toUpperCase().slice(0, 4);

    if (startupDoc.exists) {
      const sData = startupDoc.data()!;
      startupName = sData.name ?? "Startup";
      currentPrice = Number(sData.currentTokenPriceCents ?? 0) / 100;
      tokenSymbol = sData.tokenSymbol ?? tokenSymbol;
    }

    holdings.push({
      startupId,
      startupName,
      tokenSymbol,
      tokens,
      quantity: tokens,
      pricePerToken: currentPrice,
      currentPrice,
      totalValue: tokens * currentPrice
    });
  }

  return holdings;
}

/**
 * Retorna o histórico de preços filtrado por período.
 */
export async function getPriceHistory(
  startupId: string,
  period?: string
): Promise<any[]> {
  const pricesRef = db.collection("tokenPriceHistory").doc(startupId).collection("prices");
  let query = pricesRef.orderBy("timestamp", "asc");

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
        cutoffDate = new Date(new Date().getFullYear(), 0, 1);
        break;
      default:
        // Sem filtro de período
        break;
    }
    
    // Se selecionou um período válido, aplica o filtro
    if (period !== "all") {
      query = query.where("timestamp", ">=", Timestamp.fromDate(cutoffDate));
    }
  }

  const snapshot = await query.get();
  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      price: Number(data.price ?? 0),
      timestamp: data.timestamp?.toDate?.()?.toISOString?.() ?? data.timestamp,
      triggerOperationId: data.triggerOperationId ?? ""
    };
  });
}
