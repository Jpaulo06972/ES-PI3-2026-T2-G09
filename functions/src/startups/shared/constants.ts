// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

// Importa os tipos definidos no módulo de tipos da startup para garantir
// consistência entre as constantes e os valores aceitos pelas funções
import {QuestionVisibility, StartupStage} from "../types";

/**
 * Lista de estágios de startup válidos para uso como filtro na listagem.
 *
 * Centralizar esses valores aqui evita "strings mágicas" espalhadas pelo código.
 * Ao usar `allowedStages.includes(value)`, qualquer handler consegue validar
 * rapidamente se o estágio recebido do cliente é um valor esperado.
 *
 * O tipo `StartupStage[]` garante que nenhum valor inválido seja adicionado
 * acidentalmente — se o tipo mudar, o TypeScript vai apontar o erro aqui.
 */
export const allowedStages: StartupStage[] = [
  "nova",         // Startup recém-publicada, fase de ideia ou protótipo
  "em_operacao",  // Startup já em funcionamento ou validação prática
  "em_expansao",  // Startup em crescimento, buscando mais investimento
];

/**
 * Lista de visibilidades válidas para perguntas e comentários.
 *
 * Assim como `allowedStages`, essa constante serve de "lista branca" para
 * validação dos campos de visibilidade recebidos via request. Qualquer valor
 * fora dessa lista deve ser rejeitado com erro `invalid-argument`.
 *
 * Usar `QuestionVisibility[]` como tipo mantém o contrato alinhado com
 * o que foi definido em `types/index.ts`.
 */
export const allowedVisibilities: QuestionVisibility[] = [
  "publica",  // Pergunta visível para qualquer usuário autenticado
  "privada",  // Pergunta visível somente ao autor (se não for investidor confirmado)
];
