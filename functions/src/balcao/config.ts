// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

/**
 * Arquivo de configuração centralizada do motor de preço do Balcão.
 *
 * Por que centralizar aqui? Porque se precisarmos ajustar os parâmetros
 * do comportamento de preço (por exemplo, tornar o mercado mais ou menos
 * volátil), basta mudar este arquivo — sem precisar tocar no algoritmo.
 * É o princípio de "configuração separada de lógica".
 */
export const PRICE_ENGINE_CONFIG = {
  /**
   * Volume mínimo de tokens negociados (em 24h) para o preço começar a se mover.
   * Abaixo de 100 tokens, o mercado é considerado "quieto" e o preço não varia.
   * Isso evita que uma única compra pequena distorça o preço da startup.
   */
  V_MIN: 100,            // Volume mínimo para o preço começar a se mover (tokens)

  /**
   * Volume máximo considerado pelo algoritmo.
   * Mesmo que o volume de negociação seja de 50.000 tokens, o motor trata
   * como se fossem 10.000 — o excesso é "clampado". Isso limita a volatilidade
   * máxima e evita manipulações de mercado por grandes volumes atípicos.
   */
  V_MAX: 10000,          // Volume máximo para variação máxima (tokens)

  /**
   * Variação percentual máxima que o preço pode sofrer em uma única operação.
   * O valor 0.05 representa 5%. Ou seja, mesmo com pressão de compra ou venda
   * máxima, o preço só vai subir ou cair no máximo 5% por vez.
   */
  DELTA_MAX: 0.05,       // Variação percentual máxima por operação (5%)

  /**
   * Fator que define o preço mínimo (piso) do token como porcentagem do
   * preço inicial de emissão. Com FLOOR_FACTOR = 0.10, se o token foi
   * lançado a R$ 10,00, ele nunca pode cair abaixo de R$ 1,00 — protegendo
   * os investidores de uma desvalorização total.
   */
  FLOOR_FACTOR: 0.10     // Piso do preço: 10% do preço inicial de emissão
};
