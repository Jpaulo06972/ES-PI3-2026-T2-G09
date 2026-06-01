// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684


// Tipos TypeScript que definem a estrutura dos documentos de operação e os possíveis status.
import {
  OperationDocument,
  OperationStatus
} from "../types";

// Instância do Firestore compartilhada por toda a aplicação.
import {db} from "../../shared/firebase";

// `FieldValue` permite usar valores especiais do Firestore como `serverTimestamp()`.
import {FieldValue} from "firebase-admin/firestore";


// Referência à coleção `operations` no Firestore — centralizar aqui evita
// repetir a string "operations" espalhada pelo código, prevenindo erros de digitação.
const operationsCollection = db.collection("operations");

/**
 * Converte um documento bruto do Firestore em um objeto tipado com o ID incluído.
 * Separar essa lógica de mapeamento facilita a manutenção: se a estrutura do documento
 * mudar, só precisamos alterar aqui.
 */
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

/**
 * Lista todas as operações de um usuário — tanto as que ele iniciou quanto as que recebeu.
 * Retorna os documentos já ordenados por data, do mais recente ao mais antigo.
 */
export async function listOperations(uid: string): Promise<Array<OperationDocument & {id: string}>> {
  // Lista de variações do UID para busca (corrige inconsistência de I/l)
  // Alguns UIDs do Firebase Authentication têm caracteres visualmente parecidos
  // ('l' minúsculo vs 'I' maiúsculo). Esta lógica garante que dados antigos,
  // que possam ter sido salvos com o UID "errado", ainda sejam encontrados.
  const uidsToSearch = [uid];
  if (uid.includes("KTlZNT2")) uidsToSearch.push(uid.replace("KTlZNT2", "KTIZNT2"));
  else if (uid.includes("KTIZNT2")) uidsToSearch.push(uid.replace("KTIZNT2", "KTlZNT2"));

  // Realiza a busca para todas as variações e todos os campos em paralelo
  // `Promise.all` executa todas as queries simultaneamente, reduzindo o tempo de espera.
  // Buscamos em 4 campos diferentes porque documentos legados podem usar nomes de campo distintos
  // ("authorUid" vs "authorID", "targetUserId" vs "targetID").
  const allResults = await Promise.all(uidsToSearch.map(async (u) => {
    return await Promise.all([
      operationsCollection.where("authorUid", "==", u).get(),
      operationsCollection.where("authorID", "==", u).get(),
      operationsCollection.where("targetUserId", "==", u).get(),
      operationsCollection.where("targetID", "==", u).get(),
    ]);
  }));

  // Achata os resultados em uma única lista de documentos
  // `combinedDocs` pode ter documentos duplicados se o mesmo doc apareceu em múltiplas queries.
  const combinedDocs: any[] = [];
  allResults.forEach(resultSet => {
    resultSet.forEach(snap => combinedDocs.push(...snap.docs));
  });

  // Remove duplicatas baseadas no ID do documento
  // `Map` com o ID como chave garante que cada documento apareça apenas uma vez.
  const uniqueDocs = Array.from(new Map(combinedDocs.map(doc => [doc.id, doc])).values());

  // Mapeia para o formato de documento
  // Converte cada snapshot bruto do Firestore no objeto tipado usando a função auxiliar.
  const operations = uniqueDocs.map((doc) =>
    toOperationDocument(doc.id, doc.data() as OperationDocument)
  );

  // Enriquecimento de dados: Busca o e-mail do autor para transferências recebidas
  // Quando o usuário recebeu uma transferência (ele é o `targetUserId`),
  // buscamos o e-mail de quem enviou para exibir uma mensagem mais informativa no app.
  for (const op of operations) {
    if (op.typeOfOperation === "transferencia" && op.targetUserId === uid) {
      try {
        const authorDoc = await db.collection("users").doc(op.authorUid).get();
        if (authorDoc.exists) {
          const authorData = authorDoc.data();
          if (authorData && authorData.email) {
            // Sobrescreve o texto padrão com o e-mail de quem fez a transferência.
            op.text = `Transferência recebida de: ${authorData.email}`;
          }
        }
      } catch (e) {
        // Se falhar a busca do user, mantém o texto original
        // Tratamento silencioso: se o usuário remetente foi deletado ou houve erro de rede,
        // o app ainda funciona — só sem o e-mail enriquecido.
      }
    }
  }

  // Ordena manualmente por data (createdAt) - Decrescente (mais novo primeiro)
  // O Firestore retorna os documentos sem ordenação garantida quando combinamos múltiplas queries.
  // Por isso ordenamos aqui, usando `_seconds` ou `seconds` do Timestamp do Firestore.
  // Fallback para 0 garante que documentos sem data não quebrem a ordenação.
  return operations.sort((a, b) => {
    const timeA = (a.createdAt as any)?._seconds || (a.createdAt as any)?.seconds || 0;
    const timeB = (b.createdAt as any)?._seconds || (b.createdAt as any)?.seconds || 0;
    return timeB - timeA;
  });
}

/**
 * Salva um novo documento de operação na coleção `operations` e retorna o ID gerado.
 * O Firestore cria automaticamente um ID único para cada documento adicionado com `.add()`.
 */
export async function addOperation(
    operation: OperationDocument
): Promise<string> {
    const newRef = await operationsCollection.add(operation);

    // Retorna o ID do documento criado — útil para rastreamento e auditoria.
    return newRef.id;
}

/**
 * Incrementa o saldo de um usuário pelo valor informado.
 * Lê o valor atual antes de escrever para garantir que não sobrescrevemos nada inesperado.
 * Usa `merge: true` para não apagar outros campos do documento do usuário.
 */
export async function incrementUserBalance(uid: string, amount: number) {
    const userRef = db.collection("users").doc(uid);
    const userDoc = await userRef.get();
    // Suporta tanto o campo `balance` (novo padrão) quanto `saldo` (nome legado),
    // com fallback para 0 caso nenhum exista ainda.
    const currentBalance = Number(userDoc.data()?.balance ?? userDoc.data()?.saldo ?? 0);

    await userRef.set({
        balance: currentBalance + amount
    }, { merge: true });
}

/**
 * Decrementa o saldo de um usuário pelo valor informado.
 * Mesma lógica de leitura prévia e compatibilidade com campos legados do `incrementUserBalance`.
 */
export async function decrementUserBalance(uid: string, amount: number) {
    const userRef = db.collection("users").doc(uid);
    const userDoc = await userRef.get();
    // Mesma compatibilidade com `balance` e `saldo` descritas acima.
    const currentBalance = Number(userDoc.data()?.balance ?? userDoc.data()?.saldo ?? 0);

    await userRef.set({
        balance: currentBalance - amount
    }, { merge: true });
}

/**
 * Retorna o saldo atual de um usuário.
 * Se o documento não existir, retorna 0 — evita erros em contas recém-criadas.
 */
export async function getUserBalance(uid: string): Promise<number> {
    const userDoc = await db.collection("users").doc(uid).get();

    // Usuário ainda não tem documento de saldo — tratamos como saldo zero.
    if (!userDoc.exists) return 0;

    const data = userDoc.data();
    // Compatibilidade entre `balance` (atual) e `saldo` (legado), com fallback para 0.
    const balance = data?.balance ?? data?.saldo ?? 0;

    // Converte explicitamente para Number para evitar surpresas com strings numéricas.
    return Number(balance);
}

/**
 * Atualiza o status de uma operação existente (ex: de "pendente" para "aprovada").
 * Também registra o timestamp de conclusão quando o status vai para "aprovada".
 */
export async function updateOperationStatus(
    operationId: string,
    status: OperationStatus
): Promise<void> {
    await operationsCollection.doc(operationId).update({
        status: status,
        // Registra o momento da conclusão apenas quando aprovada; para outros status, limpa o campo.
        completedAt: status === "aprovada" ? FieldValue.serverTimestamp() : null
    });
}
