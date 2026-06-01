// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

// `CallableRequest` é o tipo do objeto de requisição recebido por uma Cloud Function `onCall`.
// `HttpsError` é usado para lançar erros padronizados com código e mensagem legível.
import {CallableRequest, HttpsError} from "firebase-functions/https";

// Tipo local que representa um usuário autenticado com os campos que nos interessam.
import {AuthenticatedUser} from "./types";

/**
 * Verifica se a requisição veio de um usuário autenticado e retorna seus dados básicos.
 * Essa função é usada como "guarda de entrada" em todas as Cloud Functions que exigem login.
 *
 * Se o usuário não estiver autenticado, lança um erro com código "unauthenticated",
 * que o Firebase SDK traduz automaticamente em uma exceção no lado do app Flutter.
 */
export function requireAuthenticatedUser(
  request: CallableRequest
): AuthenticatedUser {
  // `request.auth` é preenchido automaticamente pelo Firebase se o usuário estiver logado.
  // Se for `null` ou `undefined`, o token de autenticação não foi enviado ou é inválido.
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Usuario precisa estar autenticado para acessar esta funcao."
    );
  }

  // Retorna apenas os campos necessários do token — princípio do menor privilégio:
  // handlers downstream só recebem o que precisam, não o token completo.
  return {
    uid: request.auth.uid,
    // `email` pode não existir em todos os provedores de login (ex: anônimo), por isso é opcional.
    email: request.auth.token.email as string | undefined,
  };
}
