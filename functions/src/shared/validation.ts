// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

/**
 * Normaliza uma string recebida como entrada do usuário ou payload de requisição.
 * Remove espaços nas extremidades e retorna `undefined` se o valor for vazio ou não for string.
 *
 * Por que retornar `undefined` em vez de string vazia?
 * Porque `undefined` permite usar o operador `??` e verificações simples de falsiness
 * no código chamador — uma string vazia `""` passaria em checagens como `if (value)`.
 */
export function normalizeString(value: unknown): string | undefined {
  // Rejeita qualquer coisa que não seja string — número, null, objeto, etc.
  if (typeof value !== "string") {
    return undefined;
  }

  // Remove espaços do início e fim — dados vindos de formulários frequentemente têm espaços acidentais.
  const trimmed = value.trim();

  // Se após o trim a string ficar vazia, trata como ausente e retorna undefined.
  return trimmed.length > 0 ? trimmed : undefined;
}
