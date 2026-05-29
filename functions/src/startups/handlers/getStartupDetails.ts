// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import {HttpsError, onCall} from "firebase-functions/https";

import {requireAuthenticatedUser} from "../../shared/auth";
import {normalizeString} from "../../shared/validation";
import {
  getStartupById,
  listPublicQuestions,
  userIsInvestor,
} from "../repositories/startupRepository";

/**
  * Busca os dados completos de uma startup específica.
  *
  * Esta Firebase Function é callable e deve ser chamada pelo app com:
  *
  * - `id`: identificador da startup no Firestore.
  *
  * A função exige autenticação e retorna a visão detalhada do item 5.2:
  * sumário executivo, estrutura societária, membros externos, vídeos,
  * perguntas públicas e flags de acesso para investidores.
  */
export const getStartupDetails = onCall({invoker: "public"}, async (request) => {
  const user = requireAuthenticatedUser(request);
  
  const startupId = normalizeString(request.data?.id);
  
  if (!startupId) {
    throw new HttpsError(
      "invalid-argument",
      "Informe o parametro id da startup."
    );
  }
  
  const startup = await getStartupById(startupId);
  
  if (!startup) {
    throw new HttpsError("not-found", "Startup nao encontrada.");
  }
  
  const isInvestor = await userIsInvestor(startupId, user.uid);
  
  const questions = await listPublicQuestions(startupId);
  
  return {
    data: {
      id: startupId,
      startupId: startupId,
      ...startup,
      availableTokens: startup.availableTokens !== undefined ? startup.availableTokens : startup.totalTokensIssued,
      tokensSold: startup.tokensSold !== undefined ? startup.tokensSold : Math.max(0, startup.totalTokensIssued - (startup.availableTokens !== undefined ? startup.availableTokens : startup.totalTokensIssued)),
      currentTokenPrice: startup.currentTokenPrice !== undefined ? startup.currentTokenPrice : (startup.currentTokenPriceCents ?? 0) / 100,
      tokenSymbol: startup.tokenSymbol || startupId.toUpperCase().slice(0, 4),
      createdAt: startup.createdAt?.toDate().toISOString() ?? null,
      updatedAt: startup.updatedAt?.toDate().toISOString() ?? null,
      publicQuestions: questions,
      access: {
        isInvestor,
        canTradeTokens: isInvestor,
        canSendPrivateQuestions: isInvestor,
      },
    },
  };
});
