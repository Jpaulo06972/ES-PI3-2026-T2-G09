// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

/// Enum que mapeia a "idade" ou maturidade da startup no nosso ecossistema.
///
/// Saber o estágio é muito importante pro investidor entender o nível de risco.
/// Uma startup 'nova' tem muito risco mas pode multiplicar o capital várias vezes,
/// já uma 'em_expansao' é mais segura, mas cresce num ritmo diferente.
/// Dica de ouro: Usar enums garante que o banco de dados e o app falem a mesma língua.
/// 
/// Nota do sênior: Você deve estar se perguntando por que usamos snake_case
/// (ex: em_operacao) aqui ao invés do camelCase (emOperacao) que é o padrão do Dart, certo?
/// Isso acontece porque esses valores já estão salvos no Firestore exatamente com essa grafia.
/// Se a gente mudar aqui, quebramos a leitura dos dados legados no app. Cuidado com isso!
// ignore_for_file: constant_identifier_names
enum StageStartup {
  /// Aquela startup que acabou de sair do forno.
  /// Geralmente está validando o produto (MVP), buscando o primeiro cliente
  /// e o risco de investimento é o mais alto.
  nova,

  /// O produto já está rodando e a empresa fatura.
  /// A montanha-russa ainda é assustadora, mas pelo menos eles já sabem o caminho.
  em_operacao,

  /// A startup já encontrou a fórmula mágica e agora só precisa de combustível (dinheiro)
  /// para escalar, contratar mais gente e abrir novos mercados. Risco mais diluído.
  em_expansao,
}
