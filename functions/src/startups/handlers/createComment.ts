// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import {FieldValue} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/https";
import * as logger from "firebase-functions/logger";

import {allowedVisibilities} from "../shared/constants";
import {requireAuthenticatedUser} from "../../shared/auth";
import {normalizeString} from "../../shared/validation";
import {
  createComment,
  getStartupById,
  userIsInvestor,
} from "../repositories/startupRepository";
import {CommentDocument, QuestionVisibility} from "../types";

/**
 * Cria uma pergunta na subcoleção `comments` de uma startup.
 *
 * Parâmetros esperados:
 * - `startupId`: identificador da startup.
 * - `text`: texto da pergunta.
 * - `visibility`: `publica` (padrão) ou `privada`.
 *
 * Perguntas privadas exigem que o usuário seja investidor da startup.
 */
export const createStartupComment = onCall(
  {invoker: "public"},
  async (request) => {
    const user = requireAuthenticatedUser(request);

    const startupId = normalizeString(request.data?.startupId);
    const text = normalizeString(request.data?.text);
    const visibility = normalizeString(request.data?.visibility) ?? "publica";

    if (!startupId || !text) {
      throw new HttpsError("invalid-argument", "Informe startupId e text.");
    }

    if (!user.email) {
      throw new HttpsError(
        "unauthenticated",
        "Email do usuario nao disponivel no token."
      );
    }

    if (!allowedVisibilities.includes(visibility as QuestionVisibility)) {
      throw new HttpsError(
        "invalid-argument",
        "Visibility invalida. Use publica ou privada."
      );
    }

    const startup = await getStartupById(startupId);

    if (!startup) {
      throw new HttpsError("not-found", "Startup nao encontrada.");
    }

    if (visibility === "privada") {
      const isInvestor = await userIsInvestor(startupId, user.uid);

      if (!isInvestor) {
        throw new HttpsError(
          "permission-denied",
          "Somente investidores desta startup podem enviar perguntas privadas."
        );
      }
    }

    const comment: CommentDocument = {
      authorUid: user.uid,
      authorEmail: user.email,
      text,
      visibility: visibility as QuestionVisibility,
      createdAt: FieldValue.serverTimestamp(),
    };

    const commentId = await createComment(startupId, comment);

    logger.info("Pergunta criada.", {startupId, commentId, visibility});

    return {
      data: {
        id: commentId,
        startupId,
        visibility,
      },
    };
  }
);
