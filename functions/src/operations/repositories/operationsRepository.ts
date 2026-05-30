// Grupo: G09 — PI3-2026-T2
// Módulo de Operações de Trading (buy_from_startup, buy_from_user, sell_to_user)

import { db } from "../../shared/firebase";
import { FieldValue } from "firebase-admin/firestore";

type OperationType = "buy_from_startup" | "buy_from_user" | "sell_to_user";
type OperationStatus = "pending" | "accepted" | "rejected" | "cancelled";

function holdingDocId(userId: string, startupId: string): string {
  return `${userId}_${startupId}`;
}

function holdingRef(userId: string, startupId: string) {
  return db.collection("holdings").doc(holdingDocId(userId, startupId));
}

// ─── Mode A: Compra direta da startup ──────────────────────────────────────

export async function buyFromStartup(
  userId: string,
  startupId: string,
  quantity: number
): Promise<{ operationId: string; updatedBalance: number; newHoldings: number }> {
  return db.runTransaction(async (transaction) => {
    const startupRef = db.collection("startups").doc(startupId);
    const startupDoc = await transaction.get(startupRef);
    if (!startupDoc.exists) throw new Error("Startup não encontrada.");

    const startupData = startupDoc.data()!;
    const pricePerTokenCents: number = startupData.currentTokenPriceCents ?? 0;
    const availableTokens: number = startupData.availableTokens ?? 0;
    const startupName: string = startupData.name ?? "";

    if (pricePerTokenCents <= 0) throw new Error("Preço de token inválido.");
    if (availableTokens < quantity) {
      throw new Error(`Tokens insuficientes. Disponível: ${availableTokens}.`);
    }

    const userRef = db.collection("users").doc(userId);
    const userDoc = await transaction.get(userRef);
    if (!userDoc.exists) throw new Error("Usuário não encontrado.");

    const currentBalance: number = userDoc.data()!.saldo ?? 0;
    const totalCents = quantity * pricePerTokenCents;
    const totalBRL = totalCents / 100;

    if (currentBalance < totalBRL) {
      throw new Error("Saldo insuficiente para realizar esta compra.");
    }

    const hRef = holdingRef(userId, startupId);
    const hDoc = await transaction.get(hRef);
    const currentQty: number = hDoc.exists ? (hDoc.data()!.quantity ?? 0) : 0;
    const currentAvg: number = hDoc.exists ? (hDoc.data()!.averagePriceCents ?? 0) : 0;
    const newQty = currentQty + quantity;
    const newAvg = newQty > 0
      ? Math.round((currentQty * currentAvg + quantity * pricePerTokenCents) / newQty)
      : 0;

    const newBalance = currentBalance - totalBRL;

    transaction.update(userRef, { saldo: newBalance });
    transaction.set(hRef, {
      userId, startupId,
      quantity: newQty,
      averagePriceCents: newAvg,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    transaction.update(startupRef, {
      availableTokens: availableTokens - quantity,
      tokensSold: FieldValue.increment(quantity),
    });

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

// ─── Mode B: Oferta de compra a outro investidor ────────────────────────────

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
    const currentReserved: number = userDoc.data()!.reservedBalance ?? 0;
    const totalCents = quantity * pricePerTokenCents;
    const totalBRL = totalCents / 100;
    const available = currentBalance - currentReserved;

    if (available < totalBRL) {
      throw new Error("Saldo disponível insuficiente para reservar esta oferta.");
    }

    transaction.update(userRef, {
      reservedBalance: currentReserved + totalBRL,
    });

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + (validityDays || 1));

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

// ─── Criar oferta de venda ───────────────────────────────────────────────────

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

    const hRef = holdingRef(userId, startupId);
    const hDoc = await transaction.get(hRef);
    if (!hDoc.exists || (hDoc.data()!.quantity ?? 0) < quantity) {
      throw new Error("Holdings insuficientes para realizar esta oferta de venda.");
    }

    const totalCents = quantity * askedPricePerTokenCents;

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

// ─── Vendedor aceita oferta de compra ────────────────────────────────────────

export async function acceptOperation(
  sellerId: string,
  operationId: string
): Promise<{ updatedSellerBalance: number }> {
  return db.runTransaction(async (transaction) => {
    const opRef = db.collection("operations").doc(operationId);
    const opDoc = await transaction.get(opRef);
    if (!opDoc.exists) throw new Error("Operação não encontrada.");

    const opData = opDoc.data()!;
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

    // Validar holdings do vendedor
    const sellerHRef = holdingRef(sellerId, startupId);
    const sellerHDoc = await transaction.get(sellerHRef);
    if (!sellerHDoc.exists || (sellerHDoc.data()!.quantity ?? 0) < quantity) {
      throw new Error("Você não possui tokens suficientes para aceitar esta oferta.");
    }

    // Validar saldo reservado do comprador
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

    // Debitar saldo do comprador (reservado → deduzido)
    transaction.update(buyerRef, {
      saldo: buyerBalance - totalBRL,
      reservedBalance: Math.max(0, buyerReserved - totalBRL),
    });

    // Creditar vendedor
    const newSellerBalance = sellerBalance + totalBRL;
    transaction.update(sellerRef, { saldo: newSellerBalance });

    // Decrementar holdings do vendedor
    const sellerQty: number = sellerHDoc.data()!.quantity;
    transaction.update(sellerHRef, {
      quantity: Math.max(0, sellerQty - quantity),
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Incrementar holdings do comprador
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

    // Atualizar operação
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

    if (opData.type === "buy_from_user") {
      if (opData.buyerId !== userId) {
        throw new Error("Apenas o comprador pode cancelar sua própria oferta.");
      }
      // Liberar saldo reservado do comprador
      const buyerRef = db.collection("users").doc(opData.buyerId);
      const buyerDoc = await transaction.get(buyerRef);
      if (buyerDoc.exists) {
        const reserved: number = buyerDoc.data()!.reservedBalance ?? 0;
        const totalBRL: number = opData.totalCents / 100;
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

    transaction.update(opRef, {
      status: "cancelled" as OperationStatus,
      resolvedAt: FieldValue.serverTimestamp(),
      resolvedBy: userId,
    });
  });
}

// ─── Queries ─────────────────────────────────────────────────────────────────

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

  const seen = new Set<string>();
  return [...buyerSnap.docs, ...sellerSnap.docs]
    .filter(d => !seen.has(d.id) && seen.add(d.id))
    .map(doc => ({ id: doc.id, ...doc.data() }));
}

export async function getOperationsByStartup(startupId: string): Promise<any[]> {
  const snap = await db.collection("operations")
    .where("startupId", "==", startupId)
    .orderBy("createdAt", "desc")
    .limit(100)
    .get();
  return snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
}

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
