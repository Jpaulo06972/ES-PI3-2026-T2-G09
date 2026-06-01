// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

import {FieldValue, Timestamp} from "firebase-admin/firestore";

/**
 * Representa os estágios de maturidade aceitos para uma startup.
 *
 * Esses valores implementam a classificação descrita no item 5.2:
 *
 * - `nova`: ideia recentemente publicada.
 * - `em_operacao`: projeto já operando ou em validação prática.
 * - `em_expansao`: projeto em crescimento, com maior maturidade simulada.
 *
 * Os valores usam snake_case para facilitar armazenamento, filtros e
 * comparação direta no Firestore e nas chamadas callable.
*/
export type StartupStage = "nova" | "em_operacao" | "em_expansao";

/**
 * Define o nível de visibilidade de uma pergunta enviada à startup.
 *
 * - `publica`: aparece na área pública de perguntas e respostas da startup.
 * - `privada`: fica restrita a investidores, conforme regra do item 5.2.
*/
export type QuestionVisibility = "publica" | "privada";

/**
 * Representa um sócio, fundador ou participação societária da startup.
 *
 * Este tipo atende ao requisito de exibir estrutura societária e percentual de
 * participação dos sócios. Também permite registrar reservas e pools de
 * incentivo como linhas da composição societária simulada.
 *
 * O campo `bio` é opcional porque nem todos os sócios precisam ter uma
 * descrição pública — por exemplo, uma linha de "Reserva estratégica" não
 * tem bio, mas ainda compõe o cap table.
*/
export type Founder = {
  // Nome completo do sócio ou participante (ex: "Ana Ribeiro")
  name: string;
  // Papel na empresa (ex: "CEO", "CTO", "Pool de incentivos")
  role: string;
  // Percentual de participação acionária — soma dos sócios deve ser 100%
  equityPercent: number;
  // Breve descrição do perfil do sócio (opcional)
  bio?: string;
};

/**
 * Representa conselheiros, mentores ou participantes externos.
 *
 * O item 5.2 pede que a aplicação exiba membros do conselho, mentores ou
 * pessoas externas quando aplicável. Ele modela essas participações sem
 * misturá-las com a estrutura societária.
 *
 * `organization` é opcional porque alguns mentores atuam de forma
 * independente, sem vínculo institucional declarado.
*/
export type ExternalMember = {
  // Nome do membro externo
  name: string;
  // Papel que exerce na startup (ex: "Mentora", "Conselheiro")
  role: string;
  // Instituição ou empresa à qual o membro pertence (opcional)
  organization?: string;
};

/**
 * Documento completo de uma startup no Firestore.
 *
 * Este é o contrato principal do catálogo. Ele concentra os dados para
 * listagem, página detalhada, apresentação dos sócios, capital simulado e
 * materiais públicos do projeto.
 *
 * Os campos de token (`availableTokens`, `tokensSold`, `currentTokenPrice`,
 * `tokenSymbol`) são opcionais para manter compatibilidade com documentos
 * gravados antes dessas colunas existirem no schema. O repositório trata
 * cada um desses campos com fallback em caso de ausência.
*/
export type StartupDocument = {
  // Nome da startup exibido no catálogo
  name: string;
  // Estágio de maturidade (nova / em_operacao / em_expansao)
  stage: StartupStage;
  // Descrição curta usada em cards e listas
  shortDescription: string;
  // Descrição longa exibida na página de detalhes
  description: string;
  // Resumo executivo — apresenta a proposta de valor de forma concisa
  executiveSummary: string;
  // Capital captado pela startup, armazenado em centavos para evitar arredondamento de ponto flutuante
  capitalRaisedCents: number;
  // Quantidade total de tokens emitidos pela startup
  totalTokensIssued: number;
  // Preço atual por token em centavos (ex: 125 = R$ 1,25)
  currentTokenPriceCents: number;
  // Tokens ainda disponíveis para compra (opcional — calculado quando ausente)
  availableTokens?: number;
  // Tokens já vendidos (opcional — calculado quando ausente)
  tokensSold?: number;
  // Preço por token em reais (opcional — calculado a partir de currentTokenPriceCents)
  currentTokenPrice?: number;
  // Símbolo do token (ex: "BCHP") — gerado automaticamente se omitido
  tokenSymbol?: string;
  // Lista de sócios e sua participação societária
  founders: Founder[];
  // poderia ser enderecos URLs no Youtube ou firebase storage.
  // Lista de membros externos (conselheiros, mentores)
  externalMembers: ExternalMember[];
  // URLs dos vídeos demonstrativos da startup
  demoVideos: string[];
  // URL do pitch deck (apresentação de investimento), se disponível
  pitchDeckUrl?: string;
  // URL da imagem de capa exibida no card do catálogo
  coverImageUrl?: string;
  // Tags de categoria usadas para busca e filtragem (ex: "edtech", "ia")
  tags: string[];
  // Timestamp de criação gravado pelo Firestore via serverTimestamp()
  createdAt?: Timestamp;
  // Timestamp da última atualização do documento
  updatedAt?: Timestamp;
};

/**
 * Documento de pergunta armazenado na subcoleção da startup.
 *
 * As perguntas ficam em `startups/{startupId}/questions/{questionId}` para
 * manter o histórico associado ao projeto. A resposta é opcional porque a
 * pergunta pode ser criada antes de alguém respondê-la.
 *
 * `authorEmail` é opcional para compatibilidade com tokens de autenticação
 * que, em casos raros, não carregam o e-mail no payload (ex: login anônimo
 * promovido ou provider sem e-mail verificado).
*/
export type StartupQuestionDocument = {
  // UID do Firebase Auth de quem fez a pergunta
  authorUid: string;
  // E-mail do autor — opcional por questões de compatibilidade de provider
  authorEmail?: string;
  // Texto da pergunta enviada pelo usuário
  text: string;
  // Visibilidade da pergunta (publica ou privada)
  visibility: QuestionVisibility;
  // Resposta fornecida pela startup (opcional — preenchida depois)
  answer?: string;
  // Timestamp de quando a resposta foi registrada
  answeredAt?: Timestamp;
  // Timestamp de criação — gerado pelo servidor para garantir consistência
  createdAt: FieldValue;
};

/**
 * Documento de pergunta armazenado na subcoleção `comments` da startup.
 *
 * Fica em `startups/{startupId}/comments/{commentId}`.
 * Perguntas públicas são visíveis a todos os usuários autenticados.
 * Perguntas privadas são visíveis somente a quem as criou (`authorEmail`).
 *
 * Diferente de `StartupQuestionDocument`, aqui `authorEmail` é obrigatório
 * porque o filtro de visibilidade privada depende exatamente desse campo
 * para decidir se o comentário deve ser retornado para o usuário logado.
*/
export type CommentDocument = {
  // UID do Firebase Auth de quem criou o comentário
  authorUid: string;
  // E-mail do autor — obrigatório para filtrar comentários privados
  authorEmail: string;
  // Texto do comentário / pergunta
  text: string;
  // Visibilidade: "publica" ou "privada"
  visibility: QuestionVisibility;
  // Timestamp de criação gravado pelo servidor Firestore
  createdAt: FieldValue;
};

/**
 * Versão resumida de startup usada na listagem do catálogo.
 *
 * Este tipo evita enviar todos os dados da startup para telas que precisam
 * apenas de cards ou linhas de lista. A tela detalhada deve usar
 * `StartupDocument`, mas a listagem usa `StartupListItem` para trafegar menos
 * dados e manter o contrato mais claro.
 *
 * Por isso campos como `founders`, `externalMembers`, `demoVideos`,
 * `executiveSummary` e `description` são propositalmente omitidos aqui —
 * eles só fazem sentido quando o usuário já selecionou uma startup específica.
*/
export type StartupListItem = {
  // ID do documento no Firestore (chave primária)
  id: string;
  // Nome da startup
  name: string;
  // Estágio de maturidade
  stage: StartupStage;
  // Descrição curta para exibição no card
  shortDescription: string;
  // Capital captado em centavos
  capitalRaisedCents: number;
  // Total de tokens emitidos
  totalTokensIssued: number;
  // Preço do token em centavos
  currentTokenPriceCents: number;
  // Tokens ainda disponíveis para compra (opcional)
  availableTokens?: number;
  // Tokens já vendidos (opcional)
  tokensSold?: number;
  // Preço do token em reais (opcional)
  currentTokenPrice?: number;
  // Símbolo do token (opcional)
  tokenSymbol?: string;
  // URL da imagem de capa do card (opcional)
  coverImageUrl?: string;
  // Tags para busca e filtragem no catálogo
  tags: string[];
};
