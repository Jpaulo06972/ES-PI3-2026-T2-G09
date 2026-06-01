// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

// HttpsError padroniza os erros devolvidos ao app Flutter, com código HTTP e mensagem legível.
// onCall registra a função como callable — o app Flutter pode chamá-la diretamente pelo SDK.
import {HttpsError, onCall} from "firebase-functions/https";

// Logger estruturado do Firebase — envia logs para o Cloud Logging do Google
// com metadados extras (startupId, count) para facilitar o diagnóstico em produção.
import * as logger from "firebase-functions/logger";

// Utilitário de autenticação — lança HttpsError("unauthenticated") se o token estiver ausente/inválido.
import {requireAuthenticatedUser} from "../../shared/auth";

// normalizeString limpa espaços e trata undefined/null, retornando undefined se o valor for vazio.
import {normalizeString} from "../../shared/validation";

// Funções do repositório que isolam o acesso ao Firestore.
// getStartupById verifica se a startup existe; listComments aplica o filtro de visibilidade.
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
 *
 * Walkthrough detalhado:
 * 1. Valida autenticação e extrai o e-mail do token JWT.
 * 2. Confirma que a startup existe no catálogo — evita queries desnecessárias em subcoleções órfãs.
 * 3. Delega a listagem ao repositório, que aplica o filtro de visibilidade em memória
 *    (decisão de design: evitar índices compostos no Firestore que seriam custosos).
 * 4. Retorna os comentários já filtrados e ordenados cronologicamente.
 *
 * Caso de borda importante: se o e-mail do token estiver undefined (login anônimo ou
 * provider sem e-mail verificado), a função rejeita com "unauthenticated" para
 * garantir que o filtro de visibilidade privada funcione corretamente.
 */
export const listStartupComments = onCall(
  {invoker: "public"}, // Qualquer cliente pode chamar, mas a autenticação é verificada internamente
  async (request) => {
    // Valida o token JWT e extrai uid + email do usuário logado
    const user = requireAuthenticatedUser(request);

    // Normaliza o startupId recebido do app — remove espaços acidentais
    const startupId = normalizeString(request.data?.startupId);

    // startupId é obrigatório — sem ele não é possível localizar a subcoleção de comentários
    if (!startupId) {
      throw new HttpsError("invalid-argument", "Informe startupId.");
    }

    // O e-mail é essencial aqui porque o filtro de visibilidade privada compara
    // o authorEmail do comentário com o e-mail do usuário logado.
    // Sem o e-mail, todos os comentários privados seriam incorretamente filtrados.
    if (!user.email) {
      throw new HttpsError(
        "unauthenticated",
        "Email do usuario nao disponivel no token."
      );
    }

    // Verifica se a startup existe antes de buscar comentários.
    // Isso evita queries em subcoleções de documentos que não existem mais
    // (possível se a startup foi removida mas os comentários órfãos persistiram).
    const startup = await getStartupById(startupId);

    if (!startup) {
      throw new HttpsError("not-found", "Startup nao encontrada.");
    }

    // Delega a listagem ao repositório, que:
    // 1. Busca todos os comentários (até 100) da subcoleção
    // 2. Filtra em memória: mostra públicos OU privados do próprio usuário
    // 3. Ordena do mais recente para o mais antigo
    const comments = await listComments(startupId, user.email);

    // Registra o evento no Cloud Logging com contexto para diagnóstico e métricas
    logger.info("Perguntas listadas.", {startupId, count: comments.length});

    // Retorna os comentários filtrados dentro de { data: { comments: [...] } }
    return {data: {comments}};
  }
);
