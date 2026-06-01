// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// `onCall` cria uma Cloud Function invocável diretamente pelo SDK do Firebase no Flutter.
import {onCall} from "firebase-functions/https";

// Utilitário que valida se o usuário está autenticado e retorna seus dados (uid, email).
import {requireAuthenticatedUser} from "../../shared/auth";

// Função do repositório que busca todas as operações associadas a um UID no Firestore.
import {listOperations} from "../repositories/balanceRepository";

// `invoker: "public"` permite que clientes não autenticados tecnicamente chamem a função,
// mas a autenticação real é verificada manualmente via `requireAuthenticatedUser`.
export const listMyOperations = onCall({ invoker: "public" }, async (request) => {
    // Log útil para depuração no Firebase Console — mostra qual usuário fez a requisição.
    console.log(`listMyOperations chamado pelo UID: ${request.auth?.uid}`);

    // Verifica autenticação e extrai os dados do usuário logado.
    const user = requireAuthenticatedUser(request);

    // Busca todas as operações onde o usuário é autor ou destinatário.
    const operations = await listOperations(user.uid);

    // Retorna a contagem total e o array de operações — assim o app sabe quantos itens
    // existem sem precisar calcular no lado do cliente.
    return {
        count: operations.length,
        data: operations,
    };
});
