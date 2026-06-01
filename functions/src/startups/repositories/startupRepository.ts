// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// FieldValue é necessário para usar `serverTimestamp()` — o Firestore grava o
// horário exato do servidor, evitando inconsistências entre fusos do cliente
import {FieldValue} from "firebase-admin/firestore";

// Importa os tipos que definem o contrato de dados do módulo de startups
import {
  CommentDocument,
  StartupDocument,
  StartupListItem,
  StartupQuestionDocument,
} from "../types";

// Instância do Firestore compartilhada por todo o backend
import {db} from "../../shared/firebase";

/**
 * Referência à coleção raiz `startups` no Firestore.
 *
 * Centralizar a referência aqui garante que todos os métodos do repositório
 * usem o mesmo caminho e facilita refatorações futuras — se o nome da coleção
 * mudar, só precisa alterar nesta linha.
 */
const startupsCollection = db.collection("startups");

/**
 * Dados de startups demonstrativas utilizados pela função `seedDemoStartups`.
 *
 * Cada objeto representa um documento completo de startup com `id` explícito,
 * que é separado dos demais campos antes de gravar no Firestore (porque o id
 * vai como chave do documento, não como campo interno).
 *
 * As três startups cobrem os três estágios possíveis:
 * - "nova"         → BioChip Campus
 * - "em_operacao"  → Rota Verde
 * - "em_expansao"  → MentorAI
 *
 * Os valores de capital, preço e tokens são simulados para fins educacionais.
 */
const demoStartups: Array<StartupDocument & {id: string}> = [
  {
    // ID do documento no Firestore — usado como chave primária
    id: "biochip-campus",
    name: "BioChip Campus",
    // Estágio "nova": ideia recém-publicada, sem operação validada
    stage: "nova",
    shortDescription: "Sensores portateis para analises laboratoriais " +
      "didaticas.",
    description: "A BioChip Campus simula kits de diagnostico rapido para " +
      "laboratorios universitarios, conectando sensores de baixo custo a um " +
      "aplicativo de acompanhamento.",
    executiveSummary: "Startup em fase de ideacao com foco em prototipagem " +
      "de sensores educacionais e validacao com cursos da area de saude.",
    // Capital em centavos: R$ 18.500,00 — evita imprecisão de float
    capitalRaisedCents: 1850000,
    // 100.000 tokens emitidos no total
    totalTokensIssued: 100000,
    // Preço atual por token: R$ 1,25 (125 centavos)
    currentTokenPriceCents: 125,
    // 50% dos tokens ainda disponíveis para compra
    availableTokens: 50000,
    // 50% dos tokens já foram vendidos
    tokensSold: 50000,
    // Valor em reais derivado de currentTokenPriceCents (125 / 100 = 1.25)
    currentTokenPrice: 1.25,
    // Símbolo do token — 4 letras maiúsculas por convenção
    tokenSymbol: "BCHP",
    founders: [
      {
        name: "Ana Ribeiro",
        role: "CEO",
        equityPercent: 48,
        bio: "Responsavel por estrategia e parcerias academicas.",
      },
      {
        name: "Lucas Moreira",
        role: "CTO",
        equityPercent: 37,
        bio: "Responsavel por hardware e integracao mobile.",
      },
      // Linha de reserva estratégica — compõe o cap table sem bio
      {name: "Mescla Labs", role: "Reserva estrategica", equityPercent: 15},
    ],
    externalMembers: [
      {
        name: "Dra. Helena Costa",
        role: "Mentora",
        organization: "PUC-Campinas",
      },
    ],
    demoVideos: ["https://example.com/videos/biochip-campus-demo"],
    pitchDeckUrl: "https://example.com/decks/biochip-campus.pdf",
    coverImageUrl: "https://images.unsplash.com/photo-" +
      "1581093458791-9d15482442f6",
    tags: ["healthtech", "iot", "educacao"],
  },
  {
    id: "rota-verde",
    name: "Rota Verde",
    // Estágio "em_operacao": já possui operação piloto em andamento
    stage: "em_operacao",
    shortDescription: "Otimizacao de rotas sustentaveis para entregas urbanas.",
    description: "A Rota Verde usa dados de distancia, emissao estimada e " +
      "ocupacao de entregadores para sugerir rotas urbanas com menor impacto " +
      "ambiental.",
    executiveSummary: "Startup em operacao piloto com pequenos comercios " +
      "locais e validacao de indicadores de economia de combustivel.",
    // R$ 74.000,00 captados
    capitalRaisedCents: 7400000,
    totalTokensIssued: 250000,
    // R$ 3,10 por token
    currentTokenPriceCents: 310,
    availableTokens: 150000,
    tokensSold: 100000,
    currentTokenPrice: 3.10,
    tokenSymbol: "ROTA",
    founders: [
      {name: "Beatriz Santos", role: "CEO", equityPercent: 42},
      {name: "Rafael Almeida", role: "COO", equityPercent: 28},
      {name: "Carla Nogueira", role: "CTO", equityPercent: 20},
      // Pool de incentivos: reserva para funcionários e futuros parceiros
      {name: "Reserva de incentivos", role: "Pool", equityPercent: 10},
    ],
    externalMembers: [
      {name: "Marcos Lima", role: "Conselheiro", organization: "Mescla"},
      {
        name: "Patricia Gomes",
        role: "Mentora",
        organization: "Rede de Logistica",
      },
    ],
    demoVideos: ["https://example.com/videos/rota-verde-demo"],
    pitchDeckUrl: "https://example.com/decks/rota-verde.pdf",
    coverImageUrl: "https://images.unsplash.com/photo-" +
      "1500530855697-b586d89ba3ee",
    tags: ["logtech", "sustentabilidade", "mobilidade"],
  },
  {
    id: "mentorai",
    name: "MentorAI",
    // Estágio "em_expansao": projeto maduro buscando crescimento acelerado
    stage: "em_expansao",
    shortDescription: "Triagem inteligente para programas de mentoria " +
      "universitarios.",
    description: "A MentorAI organiza perfis de estudantes e mentores para " +
      "recomendar encontros com base em objetivos, disponibilidade e " +
      "historico de acompanhamento.",
    executiveSummary: "Startup em expansao com uso simulado em programas de " +
      "pre-aceleracao e potencial de integracao a plataformas educacionais.",
    // R$ 123.500,00 captados — maior capital por ser a startup mais madura
    capitalRaisedCents: 12350000,
    totalTokensIssued: 500000,
    // R$ 5,25 por token — maior preço reflete maturidade da empresa
    currentTokenPriceCents: 525,
    availableTokens: 300000,
    tokensSold: 200000,
    currentTokenPrice: 5.25,
    tokenSymbol: "MTRA",
    founders: [
      {name: "Diego Martins", role: "CEO", equityPercent: 36},
      {name: "Juliana Vieira", role: "CPO", equityPercent: 24},
      {name: "Felipe Andrade", role: "CTO", equityPercent: 25},
      {
        // Participação externa simulada para representar rodada de investimento
        name: "Investidores simulados",
        role: "Participacao externa",
        equityPercent: 15,
      },
    ],
    externalMembers: [
      {
        name: "Sofia Pereira",
        role: "Conselheira",
        organization: "Ecossistema Mescla",
      },
    ],
    demoVideos: ["https://example.com/videos/mentorai-demo"],
    pitchDeckUrl: "https://example.com/decks/mentorai.pdf",
    coverImageUrl: "https://images.unsplash.com/photo-1552664730-d307ca884978",
    tags: ["edtech", "ia", "mentoria"],
  },
];

/**
 * Converte um documento completo de startup em um item de listagem resumido.
 *
 * Esta função privada separa a responsabilidade de projeção de dados —
 * em vez de expor todos os campos do documento na listagem, ela seleciona
 * apenas os campos necessários para exibir um card no catálogo.
 *
 * @param id - ID do documento no Firestore (chave primária)
 * @param startup - Dados completos do documento StartupDocument
 * @returns Objeto StartupListItem com apenas os campos necessários para listagem
 */
function toListItem(id: string, startup: StartupDocument): StartupListItem {
  // Garante que priceCents nunca seja undefined — usa 0 como fallback seguro
  const priceCents = startup.currentTokenPriceCents ?? 0;

  // Se availableTokens estiver presente no documento, usa diretamente;
  // caso contrário, assume que todos os tokens emitidos ainda estão disponíveis
  const available = startup.availableTokens !== undefined ? startup.availableTokens : startup.totalTokensIssued;

  return {
    id,
    name: startup.name,
    stage: startup.stage,
    shortDescription: startup.shortDescription,
    capitalRaisedCents: startup.capitalRaisedCents,
    totalTokensIssued: startup.totalTokensIssued,
    currentTokenPriceCents: priceCents,
    availableTokens: available,
    // tokensSold: usa o valor do documento ou calcula como (total - disponíveis)
    // Math.max(0, ...) evita que o resultado seja negativo em dados inconsistentes
    tokensSold: startup.tokensSold !== undefined ? startup.tokensSold : Math.max(0, startup.totalTokensIssued - available),
    // currentTokenPrice em reais: usa o campo se existir ou divide centavos por 100
    currentTokenPrice: startup.currentTokenPrice !== undefined ? startup.currentTokenPrice : priceCents / 100,
    // tokenSymbol: usa o campo ou gera um símbolo a partir das 4 primeiras letras do id
    tokenSymbol: startup.tokenSymbol || id.toUpperCase().slice(0, 4),
    coverImageUrl: startup.coverImageUrl,
    tags: startup.tags,
  };
}

/**
 * Retorna a lista resumida de até 100 startups do catálogo.
 *
 * O limite de 100 evita leituras excessivas no Firestore em ambientes com muitos
 * documentos. Para paginação futura, este método poderia receber um cursor.
 *
 * @returns Array de StartupListItem prontos para serialização no response
 */
export async function listStartupItems(): Promise<StartupListItem[]> {
  // Busca até 100 documentos da coleção — custo: 1 leitura por documento retornado
  const snapshot = await startupsCollection.limit(100).get();

  // Mapeia cada documento para o tipo resumido usando a função de projeção
  return snapshot.docs.map((doc) =>
    toListItem(doc.id, doc.data() as StartupDocument)
  );
}

/**
 * Busca um documento de startup pelo seu ID no Firestore.
 *
 * Retorna `undefined` quando o documento não existe, permitindo que
 * o handler diferencie "não encontrado" de outros erros.
 *
 * @param startupId - ID do documento na coleção `startups`
 * @returns StartupDocument completo ou undefined se não encontrado
 */
export async function getStartupById(
  startupId: string
): Promise<StartupDocument | undefined> {
  // `.doc(startupId).get()` realiza uma leitura de documento único — custo: 1 leitura
  const startupSnapshot = await startupsCollection.doc(startupId).get();

  // Se o documento não existir no Firestore, retorna undefined explicitamente
  if (!startupSnapshot.exists) {
    return undefined;
  }

  // Cast para StartupDocument porque a coleção só aceita documentos desse tipo
  return startupSnapshot.data() as StartupDocument;
}

/**
 * Verifica se um usuário possui o status de investidor de uma startup específica.
 *
 * A lógica de acesso privilegiado (perguntas privadas, negociação de tokens)
 * depende desta função. Um documento em `startups/{startupId}/investors/{uid}`
 * indica que o usuário é reconhecido como investidor.
 *
 * @param startupId - ID da startup na coleção principal
 * @param uid - UID do Firebase Auth do usuário a verificar
 * @returns `true` se o documento existir, `false` caso contrário
 */
export async function userIsInvestor(
  startupId: string,
  uid: string
): Promise<boolean> {
  // Acessa a subcoleção `investors` dentro do documento da startup
  const investorSnapshot = await startupsCollection
    .doc(startupId)
    .collection("investors")
    .doc(uid) // Usa o UID como chave do documento de investidor
    .get();

  // `.exists` retorna true se o documento foi encontrado no Firestore
  return investorSnapshot.exists;
}

/**
 * Lista as perguntas públicas da subcoleção `questions` de uma startup.
 *
 * Só perguntas com `visibility === "publica"` são retornadas. O limite de 50
 * evita respostas muito grandes em startups com muitas perguntas.
 *
 * As perguntas são ordenadas da mais recente para a mais antiga usando
 * `localeCompare` nas strings ISO de `createdAt`.
 *
 * @param startupId - ID da startup cuja subcoleção será consultada
 * @returns Array de objetos com id, text, answer, answeredAt e createdAt
 */
export async function listPublicQuestions(startupId: string) {
  // Consulta com filtro de visibilidade direto no Firestore — mais eficiente que filtrar em memória
  const questionsSnapshot = await startupsCollection
    .doc(startupId)
    .collection("questions")
    .where("visibility", "==", "publica") // Índice necessário no Firestore para esse filtro
    .limit(50)
    .get();

  return questionsSnapshot.docs
    .map((doc) => ({
      id: doc.id,
      text: doc.get("text"),
      // `answer` pode não existir ainda — retorna null quando ausente
      answer: doc.get("answer") ?? null,
      // `?.toDate?.()?.toISOString?.()` garante que Timestamps do Firestore virem strings ISO para JSON
      answeredAt: doc.get("answeredAt")?.toDate?.()?.toISOString?.() ?? null,
      createdAt: doc.get("createdAt")?.toDate?.()?.toISOString?.() ?? null,
    }))
    // Ordena do mais recente para o mais antigo comparando strings ISO (lexicograficamente compatível)
    .sort((left, right) => String(right.createdAt ?? "")
      .localeCompare(String(left.createdAt ?? "")));
}

/**
 * Cria uma nova pergunta na subcoleção `questions` de uma startup.
 *
 * Usa `.add()` para gerar o ID automaticamente — não é preciso definir um ID
 * manualmente porque perguntas não têm uma chave natural.
 *
 * @param startupId - ID da startup onde a pergunta será criada
 * @param question - Objeto completo do tipo StartupQuestionDocument
 * @returns ID gerado pelo Firestore para o novo documento de pergunta
 */
export async function createQuestion(
  startupId: string,
  question: StartupQuestionDocument
): Promise<string> {
  // `.add()` cria um documento com ID automático e retorna sua referência
  const questionRef = await startupsCollection
    .doc(startupId)
    .collection("questions")
    .add(question);

  // Retorna apenas o ID — o handler usa isso para confirmar a criação ao cliente
  return questionRef.id;
}

/**
 * Cria um novo comentário na subcoleção `comments` de uma startup.
 *
 * Funciona de forma análoga a `createQuestion`, mas grava na subcoleção
 * `comments` em vez de `questions`. As duas subcoleções coexistem para
 * separar os dois fluxos de interação.
 *
 * @param startupId - ID da startup onde o comentário será criado
 * @param comment - Objeto completo do tipo CommentDocument
 * @returns ID gerado pelo Firestore para o novo documento de comentário
 */
export async function createComment(
  startupId: string,
  comment: CommentDocument
): Promise<string> {
  // Cria o documento com ID automático na subcoleção `comments`
  const ref = await startupsCollection
    .doc(startupId)
    .collection("comments")
    .add(comment);

  return ref.id;
}

/**
 * Lista os comentários visíveis para um determinado usuário em uma startup.
 *
 * A regra de visibilidade é aplicada em memória após a leitura:
 * - Comentários "publica" são retornados para qualquer usuário.
 * - Comentários "privada" são retornados somente se o `authorEmail`
 *   do comentário coincidir com o e-mail do usuário autenticado.
 *
 * O limite de 100 é maior que o de perguntas porque comentários tendem
 * a ser mais numerosos em startups ativas.
 *
 * @param startupId - ID da startup cujos comentários serão listados
 * @param userEmail - E-mail do usuário autenticado para filtrar privados
 * @returns Array de comentários filtrados e ordenados do mais recente ao mais antigo
 */
export async function listComments(startupId: string, userEmail: string) {
  // Busca todos os comentários sem filtrar no Firestore — a filtragem é feita em memória
  // porque combinar filtros de visibilidade e e-mail exigiria índices compostos custosos
  const snap = await startupsCollection
    .doc(startupId)
    .collection("comments")
    .limit(100)
    .get();

  return snap.docs
    .map((doc) => ({
      id: doc.id,
      authorEmail: doc.get("authorEmail") as string,
      text: doc.get("text") as string,
      visibility: doc.get("visibility") as string,
      // Converte Timestamp do Firestore para string ISO serializável em JSON
      createdAt: doc.get("createdAt")?.toDate?.()?.toISOString?.() ?? null,
    }))
    // Filtra: mostra todos os públicos OU os privados cujo autor é o usuário atual
    .filter((c) => c.visibility === "publica" || c.authorEmail === userEmail)
    // Ordena do mais recente para o mais antigo
    .sort((a, b) =>
      String(b.createdAt ?? "").localeCompare(String(a.createdAt ?? ""))
    );
}

/**
 * Popula o Firestore com as startups de demonstração definidas em `demoStartups`.
 *
 * Usa um `batch` (gravação em lote) para atomicamente salvar todas as startups
 * de uma vez. Se qualquer gravação falhar, o batch inteiro é revertido —
 * evitando um estado parcialmente populado.
 *
 * A opção `{merge: true}` no `batch.set` garante que documentos já existentes
 * não sejam sobrescritos completamente — apenas os campos fornecidos são
 * atualizados, preservando dados que possam ter sido editados manualmente.
 *
 * `createdAt` e `updatedAt` são definidos pelo servidor (`serverTimestamp()`)
 * para garantir consistência de fuso horário entre diferentes ambientes.
 *
 * @returns Array com os IDs das startups gravadas (na mesma ordem de demoStartups)
 */
export async function seedDemoStartups(): Promise<string[]> {
  // Cria um batch — todas as operações abaixo serão enviadas juntas em uma única requisição
  const batch = db.batch();

  for (const startup of demoStartups) {
    // Desestrutura para separar o id (chave do documento) dos demais campos (dados)
    const {id, ...data} = startup;

    // Referência ao documento que será criado/atualizado
    const startupRef = startupsCollection.doc(id);

    // `merge: true` atualiza apenas os campos fornecidos, não apaga dados existentes
    batch.set(startupRef, {
      ...data,
      // Grava o horário do servidor no momento da execução — não do cliente
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  }

  // Envia todas as gravações para o Firestore em uma única operação atômica
  await batch.commit();

  // Retorna apenas os IDs para que o handler possa confirmar quais foram gravados
  return demoStartups.map((startup) => startup.id);
}
