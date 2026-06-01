// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

/// Enum que representa o estado atual de uma operação financeira no sistema.
///
/// Imagina esse enum como o semáforo da nossa transação financeira.
/// Toda transação (seja um PIX entrando ou um investimento saindo) passa por um ciclo de vida.
/// Ela sempre começa como [pendente] e depois evolui para [aprovada] ou [recusada].
/// Por que usar um enum e não simplesmente String? Porque Strings aceitam qualquer coisa e 
/// facilitam os famosos erros de digitação (ex: digitar "pendeente"). O enum "trava" as opções,
/// deixando nosso código mais seguro e previsível, ótimo para montar nossos switch/cases depois.
enum OperationStatus {
  /// Estado inicial de toda transação. É como o "aguarde na fila".
  /// Pode estar esperando o processamento do banco ou uma aprovação manual de um admin.
  pendente,

  /// O sinal verde! A operação foi processada com sucesso.
  /// Aqui o saldo do usuário já foi creditado ou debitado de fato no backend.
  aprovada,

  /// O sinal vermelho. Algo deu errado ou a operação foi bloqueada.
  /// Pode ser falta de saldo, dados inválidos no banco, ou um bloqueio de segurança.
  recusada,
}
