// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

/**
 * Ponto de entrada (barrel file) do módulo `startups`.
 *
 * Este arquivo re-exporta todas as Firebase Functions relacionadas a startups
 * para que o arquivo raiz `functions/src/index.ts` consiga registrá-las com
 * uma única importação de módulo.
 *
 * Cada linha abaixo aponta para o handler correspondente:
 * - `createStartupQuestion` — cria uma pergunta na subcoleção `questions`
 * - `getStartupDetails`     — retorna os detalhes completos de uma startup
 * - `listStartups`          — lista o catálogo com filtros opcionais
 * - `seedStartupCatalog`    — popula o Firestore com startups de demonstração
 * - `createStartupComment`  — cria um comentário na subcoleção `comments`
 * - `listStartupComments`   — lista os comentários visíveis ao usuário logado
 */

// Função para criar perguntas no módulo de Q&A da startup
export {createStartupQuestion} from "./handlers/createStartupQuestion";

// Função para buscar todos os dados detalhados de uma startup específica
export {getStartupDetails} from "./handlers/getStartupDetails";

// Função para listar o catálogo de startups com filtros de stage e busca textual
export {listStartups} from "./handlers/listStartups";

// Função utilitária para popular o Firestore com dados de startups demonstrativas
export {seedStartupCatalog} from "./handlers/seedStartupCatalog";

// Função para criar comentários/perguntas na subcoleção `comments` de uma startup
export {createStartupComment} from "./handlers/createComment";

// Função para listar os comentários visíveis ao usuário autenticado
export {listStartupComments} from "./handlers/listComments";
