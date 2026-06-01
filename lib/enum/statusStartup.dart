// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

/// Enum que funciona como o botão de "liga/desliga" da startup no aplicativo.
///
/// Não é porque um empreendedor cadastrou a startup dele que ela já vai 
/// aparecer direto para os investidores comprarem tokens. Nós temos uma etapa 
/// de curadoria/avaliação. Esse status controla justamente isso: quem pode ser visto.
/// Ter esse controle ajuda na qualidade e evita fraudes na plataforma.
enum StatusStartup {
  /// Tudo certo! A startup passou pelo pente-fino da administração,
  /// está liberada no catálogo e já pode receber aportes dos investidores.
  ativa,

  /// Startup escondida. Pode estar assim por vários motivos:
  /// acabou de ser cadastrada (em revisão), foi suspensa por irregularidade
  /// ou o próprio fundador pediu uma pausa. Enquanto estiver aqui, é invisível na vitrine.
  inativa,
}
