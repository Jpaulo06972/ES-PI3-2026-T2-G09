import {HttpsError, onCall} from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import {requireAuthenticatedUser} from "../shared/auth";
import {normalizeString} from "../shared/validation";
import {insertStartup} from "../repositories/startupRepository";
import {StartupDocument, StartupStage} from "../types";

/**
 * Cria uma nova startup no banco de dados.
 *
 * Esta Firebase Function é callable e deve ser chamada pelo app com:
 * - name
 * - stage
 * - shortDescription
 * - description
 * - executiveSummary
 * - capitalRaisedCents
 * - totalTokensIssued
 * - currentTokenPriceCents
 * - founders
 * - externalMembers
 * - demoVideos
 * - tags
 */
export const createStartup = onCall({invoker: "public"}, async (request) => {
  // 1. Garante que o usuário está autenticado
  const user = requireAuthenticatedUser(request);

  const data = request.data;

  // 2. Normaliza e extrai os dados
  const name = normalizeString(data?.name);
  const stage = normalizeString(data?.stage) as StartupStage;
  const shortDescription = normalizeString(data?.shortDescription);
  const description = normalizeString(data?.description);
  const executiveSummary = normalizeString(data?.executiveSummary);
  
  // Tratamento de valores numéricos
  const capitalRaisedCents = typeof data?.capitalRaisedCents === "number" ? data.capitalRaisedCents : 0;
  const totalTokensIssued = typeof data?.totalTokensIssued === "number" ? data.totalTokensIssued : 0;
  const currentTokenPriceCents = typeof data?.currentTokenPriceCents === "number" ? data.currentTokenPriceCents : 0;
  
  // Arrays
  const founders = Array.isArray(data?.founders) ? data.founders : [];
  const externalMembers = Array.isArray(data?.externalMembers) ? data.externalMembers : [];
  const demoVideos = Array.isArray(data?.demoVideos) ? data.demoVideos : [];
  const tags = Array.isArray(data?.tags) ? data.tags : [];
  
  // 3. Valida os campos obrigatórios
  if (!name || !stage || !shortDescription || !description || !executiveSummary) {
    logger.warn("Tentativa de criar startup com dados incompletos.", {uid: user.uid});
    throw new HttpsError(
      "invalid-argument",
      "Nome, estágio, descrição curta, descrição longa e resumo executivo são obrigatórios."
    );
  }

  // 4. Monta o objeto da startup conforme a interface StartupDocument
  const newStartup: StartupDocument = {
    name,
    stage,
    shortDescription,
    description,
    executiveSummary,
    capitalRaisedCents,
    totalTokensIssued,
    currentTokenPriceCents,
    founders,
    externalMembers,
    demoVideos,
    tags,
    // coverImageUrl e pitchDeckUrl podem ser adicionados depois (quando houver upload de mídia)
  };

  // 5. Salva no banco de dados através do repository
  const startupId = await insertStartup(newStartup);

  logger.info("Nova startup criada com sucesso.", {startupId, uid: user.uid});

  // 6. Retorna o ID da startup criada para o aplicativo
  return {
    data: {
      id: startupId,
    },
  };
});
