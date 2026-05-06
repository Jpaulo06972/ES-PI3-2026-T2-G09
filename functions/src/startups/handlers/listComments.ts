// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import {HttpsError, onCall} from "firebase-functions/https";
import * as logger from "firebase-functions/logger";

import {requireAuthenticatedUser} from "../../shared/auth";
import {normalizeString} from "../../shared/validation";
import {
  getStartupById,
  listComments,
} from "../repositories/startupRepository";

/**
 * Lista as perguntas da subcoleção `comments` de uma startup.
 *
 * Parâmetros esperados:
 * - `startupId`: identificador da startup.
 *
 * Regras de visibilidade:
 * - Perguntas públicas: retornadas para qualquer usuário autenticado.
 * - Perguntas privadas: retornadas somente se `authorEmail` do comentário
 *   for igual ao email do usuário autenticado.
 */
export const listStartupComments = onCall(
  {invoker: "public"},
  async (request) => {
    const user = requireAuthenticatedUser(request);

    const startupId = normalizeString(request.data?.startupId);

    if (!startupId) {
      throw new HttpsError("invalid-argument", "Informe startupId.");
    }

    if (!user.email) {
      throw new HttpsError(
        "unauthenticated",
        "Email do usuario nao disponivel no token."
      );
    }

    const startup = await getStartupById(startupId);

    if (!startup) {
      throw new HttpsError("not-found", "Startup nao encontrada.");
    }

    const comments = await listComments(startupId, user.email);

    logger.info("Perguntas listadas.", {startupId, count: comments.length});

    return {data: {comments}};
  }
);
