// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

// FieldValue permite gravar timestamps gerados pelo servidor Firestore
import {FieldValue} from "firebase-admin/firestore";

// HttpsError padroniza erros retornados ao cliente; onCall registra a função callable
import {HttpsError, onCall} from "firebase-functions/https";

// Logger estruturado para o Cloud Logging do Google
import * as logger from "firebase-functions/logger";

// Lista branca de visibilidades válidas — centralizada para facilitar manutenção
import {allowedVisibilities} from "../shared/constants";

// Utilitário que valida autenticação e lança erro se o usuário não estiver logado
import {requireAuthenticatedUser} from "../../shared/auth";

// normalizeString trata espaços, undefined e null de forma uniforme
import {normalizeString} from "../../shared/validation";

// Funções de acesso ao Firestore para criar pergunta, buscar startup e verificar investidor
import {
  createQuestion,
  getStartupById,
  userIsInvestor,
} from "../repositories/startupRepository";

// Tipos de dado que definem o contrato do documento de pergunta e sua visibilidade
import {QuestionVisibility, StartupQuestionDocument} from "../types";

/**
  * Cria uma pergunta para uma startup.
  *
  * Esta Firebase Function é callable e deve ser chamada pelo app com:
  *
  * - `startupId`: identificador da startup.
  * - `text`: texto da pergunta.
  * - `visibility`: visibilidade opcional (`publica` ou `privada`).
  *
  * Perguntas públicas podem ser enviadas por qualquer usuário autenticado.
  * Perguntas privadas exigem que o usuário tenha um documento em:
  * `startups/{startupId}/investors/{uid}`.
  */
export const createStartupQuestion = onCall(
  {invoker: "public"}, // Acessível por qualquer usuário autenticado
  async (request) => {
  // Verifica autenticação e extrai os dados do token do usuário logado
  const user = requireAuthenticatedUser(request);

  // Normaliza o ID da startup para evitar valores com espaços ou undefined
  const startupId = normalizeString(request.data?.startupId);

  // Normaliza o texto da pergunta enviado pelo cliente
  const text = normalizeString(request.data?.text);

  // Usa "publica" como padrão quando visibility não é informado
  const visibility = normalizeString(request.data?.visibility) ?? "publica";

  // Ambos são obrigatórios — sem eles não há como criar a pergunta
  if (!startupId || !text) {
    throw new HttpsError("invalid-argument", "Informe startupId e text.");
  }

  // Valida que o valor de visibility é um dos aceitos pelo sistema
  if (!allowedVisibilities.includes(visibility as QuestionVisibility)) {
    throw new HttpsError(
      "invalid-argument",
      "Visibility invalida. Use publica ou privada."
    );
  }

  // Confirma que a startup existe no Firestore antes de prosseguir
  const startup = await getStartupById(startupId);

  if (!startup) {
    throw new HttpsError("not-found", "Startup nao encontrada.");
  }

  // Perguntas privadas são um privilégio de investidores — verifica o vínculo
  if (visibility === "privada") {
    const isInvestor = await userIsInvestor(startupId, user.uid);

    if (!isInvestor) {
      throw new HttpsError(
        "permission-denied",
        "Somente investidores desta startup podem enviar perguntas privadas."
      );
    }
  }

  // Monta o documento que será gravado na subcoleção `questions`
  const question: StartupQuestionDocument = {
    authorUid: user.uid,           // UID do autor para rastreabilidade
    authorEmail: user.email,       // E-mail do autor (pode ser undefined em alguns providers)
    text,                          // Texto da pergunta já normalizado
    visibility: visibility as QuestionVisibility, // Visibilidade validada
    createdAt: FieldValue.serverTimestamp(), // Timestamp do servidor para ordenação confiável
  };

  // Persiste a pergunta no Firestore e obtém o ID gerado automaticamente
  const questionId = await createQuestion(startupId, question);

  // Registra o evento no Cloud Logging com contexto para diagnóstico
  logger.info("Pergunta criada para startup.", {
    startupId,
    questionId,
    visibility,
  });

  // Retorna os identificadores para que o app possa referenciar a pergunta criada
  return {
    data: {
      id: questionId,
      startupId,
      visibility,
    },
  };
});
