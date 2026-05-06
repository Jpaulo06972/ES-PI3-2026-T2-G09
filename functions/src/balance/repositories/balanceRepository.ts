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

export async function getUserBalance(uid: string): Promise<number> {
    const userDoc = await db.collection("users").doc(uid).get();

    if (!userDoc.exists) return 0;


    return userDoc.data()?.saldo ?? 0;
}

export async function incrementUserBalance(uid: string, amountCents: number) {
    await db.collection("users").doc(uid).update({
        saldo: FieldValue.increment(amountCents),
    });
}

export async function decrementUserBalance(uid: string, amountCents: number) {
    await db.collection("users").doc(uid).update({
        saldo: FieldValue.increment(-amountCents),
    });
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
