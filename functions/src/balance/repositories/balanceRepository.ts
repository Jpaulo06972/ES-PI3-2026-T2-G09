// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684


import {
  OperationDocument,
  OperationStatus
} from "../types";

import {db} from "../../shared/firebase";
import {FieldValue} from "firebase-admin/firestore";


const operationsCollection = db.collection("operations");

function toOperationDocument(id: string, operation: OperationDocument) {
  return {
    id,
    authorUid: operation.authorUid,
    amountCents: operation.amountCents,
    typeOfOperation: operation.typeOfOperation,
    status: operation.status,
    targetUserId: operation.targetUserId,
    text: operation.text,
    createdAt: operation.createdAt,
    completedAt: operation.completedAt,
  };
}

export async function listOperations(uid: string): Promise<Array<OperationDocument & {id: string}>> {
  const snapshot = await operationsCollection
  .where("authorUid", "==", uid)
  .orderBy("createdAt", "desc")
  .limit(100)
  .get();

  return snapshot.docs.map((doc) =>
    toOperationDocument(doc.id, doc.data() as OperationDocument)
  );
}

export async function addOperation(
    operation: OperationDocument
): Promise<string> {
    const newRef = await operationsCollection.add(operation);

    return newRef.id;
}

export async function incrementUserBalance(uid: string, amount: number) {
    const userRef = db.collection("users").doc(uid);
    const userDoc = await userRef.get();
    const currentBalance = Number(userDoc.data()?.balance ?? userDoc.data()?.saldo ?? 0);
    
    await userRef.set({
        balance: currentBalance + amount
    }, { merge: true });
}

export async function decrementUserBalance(uid: string, amount: number) {
    const userRef = db.collection("users").doc(uid);
    const userDoc = await userRef.get();
    const currentBalance = Number(userDoc.data()?.balance ?? userDoc.data()?.saldo ?? 0);
    
    await userRef.set({
        balance: currentBalance - amount
    }, { merge: true });
}

export async function getUserBalance(uid: string): Promise<number> {
    const userDoc = await db.collection("users").doc(uid).get();

    if (!userDoc.exists) return 0;

    const data = userDoc.data();
    const balance = data?.balance ?? data?.saldo ?? 0;
    
    return Number(balance);
}

export async function updateOperationStatus( 
    operationId: string, 
    status: OperationStatus
): Promise<void> {
    await operationsCollection.doc(operationId).update({
        status: status,
        completedAt: status === "aprovada" ? FieldValue.serverTimestamp() : null
    });
}
