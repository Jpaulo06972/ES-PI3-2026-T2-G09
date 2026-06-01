// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003
/**
 * Representa um usuário autenticado extraído do token JWT do Firebase.
 * Esse tipo é retornado por `requireAuthenticatedUser` e passado aos handlers
 * que precisam identificar quem está fazendo a requisição.
 */
export type AuthenticatedUser = {
  uid: string;      // Identificador único do usuário no Firebase Authentication
  email?: string;   // E-mail do usuário — opcional, pois pode não existir em todos os métodos de login
};
