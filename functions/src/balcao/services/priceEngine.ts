// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import { PRICE_ENGINE_CONFIG } from "../config";

/**
 * Calcula o novo preço do token usando interpolação linear com base no volume recente de compra e venda.
 * 
 * @param currentPrice Preço atual do token (em BRL, simulado)
 * @param recentBuyVolume Volume de compras nas últimas 24 horas (em quantidade de tokens)
 * @param recentSellVolume Volume de vendas nas últimas 24 horas (em quantidade de tokens)
 * @param initialPrice Preço inicial de emissão do token (em BRL, simulado)
 * @returns Novo preço recalculado do token em BRL
 */
export function calculateNewPrice(
  currentPrice: number,
  recentBuyVolume: number,
  recentSellVolume: number,
  initialPrice: number
): number {
  const { V_MIN, V_MAX, DELTA_MAX, FLOOR_FACTOR } = PRICE_ENGINE_CONFIG;

  const netPressure = recentBuyVolume - recentSellVolume;

  // Se a pressão líquida de volume não atingir o limiar mínimo, o preço permanece o mesmo
  if (Math.abs(netPressure) < V_MIN) {
    return currentPrice;
  }

  // Clampa a pressão líquida no intervalo [-V_MAX, V_MAX]
  const clampedPressure = Math.max(-V_MAX, Math.min(V_MAX, netPressure));

  // Calcula o parâmetro t no intervalo [0, 1]
  const t = (clampedPressure + V_MAX) / (2 * V_MAX);

  // Executa o lerp entre [-delta_max, delta_max]
  const delta = -DELTA_MAX + t * (2 * DELTA_MAX);

  // Calcula o novo preço
  let newPrice = currentPrice * (1 + delta);

  // Aplica o preço de piso (floor price) de modo que não caia abaixo da fração estipulada do preço inicial
  const floorPrice = initialPrice * FLOOR_FACTOR;
  if (newPrice < floorPrice) {
    newPrice = floorPrice;
  }

  return newPrice;
}
