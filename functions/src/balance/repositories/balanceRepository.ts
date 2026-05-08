// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684


import {
  OperationDocument,
  OperationStatus
} from "../types";

import {db} from "../../shared/firebase";
import {FieldValue, Filter} from "firebase-admin/firestore";


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
  // Lista de variações do UID para busca (corrige inconsistência de I/l)
  const uidsToSearch = [uid];
  if (uid.includes("KTlZNT2")) uidsToSearch.push(uid.replace("KTlZNT2", "KTIZNT2"));
  else if (uid.includes("KTIZNT2")) uidsToSearch.push(uid.replace("KTIZNT2", "KTlZNT2"));

  // Realiza a busca para todas as variações e todos os campos em paralelo
  const allResults = await Promise.all(uidsToSearch.map(async (u) => {
    return await Promise.all([
      operationsCollection.where("authorUid", "==", u).get(),
      operationsCollection.where("authorID", "==", u).get(),
      operationsCollection.where("targetUserId", "==", u).get(),
      operationsCollection.where("targetID", "==", u).get(),
    ]);
  }));

  // Achata os resultados em uma única lista de documentos
  const combinedDocs: any[] = [];
  allResults.forEach(resultSet => {
    resultSet.forEach(snap => combinedDocs.push(...snap.docs));
  });

  // Remove duplicatas baseadas no ID do documento
  const uniqueDocs = Array.from(new Map(combinedDocs.map(doc => [doc.id, doc])).values());

  // Mapeia para o formato de documento
  const operations = uniqueDocs.map((doc) =>
    toOperationDocument(doc.id, doc.data() as OperationDocument)
  );

  // Enriquecimento de dados: Busca o e-mail do autor para transferências recebidas
  for (const op of operations) {
    if (op.typeOfOperation === "transferencia" && op.targetUserId === uid) {
      try {
        const authorDoc = await db.collection("users").doc(op.authorUid).get();
        if (authorDoc.exists) {
          const authorData = authorDoc.data();
          if (authorData && authorData.email) {
            op.text = `Transferência recebida de: ${authorData.email}`;
          }
        }
      } catch (e) {
        // Se falhar a busca do user, mantém o texto original
      }
    }
  }

  // Ordena manualmente por data (createdAt) - Decrescente (mais novo primeiro)
  return operations.sort((a, b) => {
    const timeA = (a.createdAt as any)?._seconds || (a.createdAt as any)?.seconds || 0;
    const timeB = (b.createdAt as any)?._seconds || (b.createdAt as any)?.seconds || 0;
    return timeB - timeA;
  });
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
