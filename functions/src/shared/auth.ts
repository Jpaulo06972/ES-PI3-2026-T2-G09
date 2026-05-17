// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import {CallableRequest, HttpsError} from "firebase-functions/https";
import {AuthenticatedUser} from "./types";

export function requireAuthenticatedUser(
  request: CallableRequest
): AuthenticatedUser {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Usuario precisa estar autenticado para acessar esta funcao."
    );
  }
  
  return {
    uid: request.auth.uid,
    email: request.auth.token.email as string | undefined,
  };
}
