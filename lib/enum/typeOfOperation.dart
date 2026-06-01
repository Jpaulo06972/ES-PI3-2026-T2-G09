// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684
// Valores que o backend nos manda hoje: "deposito" | "pagar" | "transferencia" | "investimento"

/// Enum que lista os sabores possíveis de uma transação financeira no nosso app.
///
/// Pensa nesse enum como a categoria de um lançamento no seu extrato bancário.
/// É muito importante tipar isso bem, porque o comportamento muda de acordo com o tipo:
/// - Se for [deposito] ou recebimento de [transferencia], entra dinheiro (soma no saldo).
/// - Se for [saque], [pagar], enviar [transferencia] ou fazer um [investimento], sai dinheiro (subtrai do saldo).
/// Dica de dev: Se a gente usasse String, e alguém digitasse "invetimento" no backend,
/// nosso app não ia reconhecer e poderia quebrar a tela de extrato. Enums salvam vidas.
enum TypeOfOperation {
  /// Quando o usuário adiciona dinheiro real na carteira do app.
  /// Pode vir via PIX, TED, Boleto, etc. O saldo sobe!
  deposito,

  /// O oposto do depósito. O usuário está retirando fundos do app 
  /// de volta para a conta bancária pessoal dele. O saldo desce.
  saque,

  /// Pagamento de alguma despesa, boleto ou serviço direto pelo app.
  pagar,

  /// Envio de grana de um usuário para outro dentro do nosso próprio ecossistema (P2P).
  transferencia,

  /// A cereja do bolo: quando o usuário pega o dinheiro e compra tokens de uma startup.
  /// Aqui o dinheiro sai do saldo livre e vira um ativo no portfólio.
  investimento,
}
