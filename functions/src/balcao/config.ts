// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

export const PRICE_ENGINE_CONFIG = {
  V_MIN: 100,            // Volume mínimo para o preço começar a se mover (tokens)
  V_MAX: 10000,          // Volume máximo para variação máxima (tokens)
  DELTA_MAX: 0.05,       // Variação percentual máxima por operação (5%)
  FLOOR_FACTOR: 0.10     // Piso do preço: 10% do preço inicial de emissão
};
