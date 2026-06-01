// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// FieldValue é usado para gravar o timestamp no servidor, garantindo consistência de fuso horário
import {FieldValue} from "firebase-admin/firestore";

// HttpsError lança erros padronizados para o cliente Flutter; onCall registra a função callable
import {HttpsError, onCall} from "firebase-functions/https";

// logger do Firebase Functions envia logs estruturados para o Cloud Logging
import * as logger from "firebase-functions/logger";

// Lista de visibilidades válidas centralizada em constants para evitar strings soltas no código
import {allowedVisibilities} from "../shared/constants";

// Utilitário que verifica se o usuário está autenticado e retorna seus dados de forma segura
import {requireAuthenticatedUser} from "../../shared/auth";

// normalizeString elimina espaços extras e trata valores null/undefined de forma uniforme
import {normalizeString} from "../../shared/validation";

// Funções do repositório que encapsulam as operações no Firestore
import {
  createComment,
  getStartupById,
  userIsInvestor,
} from "../repositories/startupRepository";

// Tipos que definem o contrato de dados do documento de comentário e da visibilidade
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
  {invoker: "public"}, // Qualquer usuário autenticado pode chamar esta função
  async (request) => {
    // Garante que a requisição veio de um usuário autenticado e extrai seus dados
    const user = requireAuthenticatedUser(request);

    // Normaliza os parâmetros recebidos — remove espaços e trata undefined como null
    const startupId = normalizeString(request.data?.startupId);
    const text = normalizeString(request.data?.text);

    // Se visibility não for informado, assume "publica" como padrão
    const visibility = normalizeString(request.data?.visibility) ?? "publica";

    // Valida campos obrigatórios — sem startupId ou text não há como criar o comentário
    if (!startupId || !text) {
      throw new HttpsError("invalid-argument", "Informe startupId e text.");
    }

    // O e-mail é obrigatório neste handler porque é usado no filtro de comentários privados
    if (!user.email) {
      throw new HttpsError(
        "unauthenticated",
        "Email do usuario nao disponivel no token."
      );
    }

    // Rejeita valores de visibility fora da lista branca (ex: "secreto", "restrito")
    if (!allowedVisibilities.includes(visibility as QuestionVisibility)) {
      throw new HttpsError(
        "invalid-argument",
        "Visibility invalida. Use publica ou privada."
      );
    }

    // Confirma que a startup existe antes de tentar criar o comentário
    const startup = await getStartupById(startupId);

    if (!startup) {
      throw new HttpsError("not-found", "Startup nao encontrada.");
    }

    // Comentários privados são exclusivos de investidores — verifica o vínculo antes de prosseguir
    if (visibility === "privada") {
      const isInvestor = await userIsInvestor(startupId, user.uid);

      if (!isInvestor) {
        throw new HttpsError(
          "permission-denied",
          "Somente investidores desta startup podem enviar perguntas privadas."
        );
      }
    }

    // Monta o documento que será gravado na subcoleção `comments`
    const comment: CommentDocument = {
      authorUid: user.uid,          // UID do Firebase Auth — identifica o autor
      authorEmail: user.email,      // E-mail usado no filtro de visibilidade privada
      text,                         // Texto do comentário/pergunta
      visibility: visibility as QuestionVisibility, // "publica" ou "privada"
      createdAt: FieldValue.serverTimestamp(), // Timestamp do servidor para consistência
    };

    // Grava o comentário no Firestore e obtém o ID do documento criado
    const commentId = await createComment(startupId, comment);

    // Registra o evento no Cloud Logging para rastreabilidade
    logger.info("Pergunta criada.", {startupId, commentId, visibility});

    // Retorna os dados mínimos para o cliente confirmar a criação
    return {
      data: {
        id: commentId,
        startupId,
        visibility,
      },
    };
  }
);
