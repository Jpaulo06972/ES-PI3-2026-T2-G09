// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

// HttpsError padroniza os erros retornados ao app; onCall registra a função callable
import {HttpsError, onCall} from "firebase-functions/https";

// Utilitário de autenticação — lança erro se o usuário não estiver logado
import {requireAuthenticatedUser} from "../../shared/auth";

// normalizeString limpa o valor recebido (espaços, undefined, null)
import {normalizeString} from "../../shared/validation";

// Funções do repositório que encapsulam acesso ao Firestore
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
  // Valida que o usuário está autenticado — lança "unauthenticated" se não estiver
  const user = requireAuthenticatedUser(request);

  // Extrai e normaliza o id da startup enviado pelo app
  const startupId = normalizeString(request.data?.id);

  // Sem o id não é possível localizar o documento — rejeita imediatamente
  if (!startupId) {
    throw new HttpsError(
      "invalid-argument",
      "Informe o parametro id da startup."
    );
  }

  // Busca o documento completo da startup no Firestore
  const startup = await getStartupById(startupId);

  // Se o documento não existir, retorna 404 ao cliente
  if (!startup) {
    throw new HttpsError("not-found", "Startup nao encontrada.");
  }

  // Verifica se o usuário logado é investidor desta startup — usado para controlar acesso
  const isInvestor = await userIsInvestor(startupId, user.uid);

  // Busca as perguntas públicas da startup para exibir na aba de Q&A
  const questions = await listPublicQuestions(startupId);

  // Monta e retorna o objeto de resposta com todos os dados detalhados da startup
  return {
    data: {
      // Inclui o id explicitamente e também como `startupId` para compatibilidade com o app
      id: startupId,
      startupId: startupId,

      // Spread do documento — inclui todos os campos como name, stage, founders, etc.
      ...startup,

      // availableTokens: usa o valor do documento ou assume que todos os tokens estão disponíveis
      availableTokens: startup.availableTokens !== undefined ? startup.availableTokens : startup.totalTokensIssued,

      // tokensSold: usa o campo do documento ou calcula como (total - disponíveis)
      // Math.max(0, ...) previne valores negativos em caso de dados inconsistentes
      tokensSold: startup.tokensSold !== undefined ? startup.tokensSold : Math.max(0, startup.totalTokensIssued - (startup.availableTokens !== undefined ? startup.availableTokens : startup.totalTokensIssued)),

      // currentTokenPrice em reais: usa o campo se existir ou converte de centavos
      currentTokenPrice: startup.currentTokenPrice !== undefined ? startup.currentTokenPrice : (startup.currentTokenPriceCents ?? 0) / 100,

      // tokenSymbol: usa o campo ou gera automaticamente com as 4 primeiras letras do id em maiúsculas
      tokenSymbol: startup.tokenSymbol || startupId.toUpperCase().slice(0, 4),

      // Converte Timestamps do Firestore para strings ISO (serializáveis em JSON)
      createdAt: startup.createdAt?.toDate().toISOString() ?? null,
      updatedAt: startup.updatedAt?.toDate().toISOString() ?? null,

      // Lista de perguntas e respostas públicas da startup
      publicQuestions: questions,

      // Flags de acesso baseadas no status de investidor do usuário logado
      access: {
        isInvestor,                           // true se o usuário tiver documento na subcoleção investors
        canTradeTokens: isInvestor,           // Apenas investidores podem negociar tokens
        canSendPrivateQuestions: isInvestor,  // Apenas investidores podem enviar perguntas privadas
      },
    },
  };
});
