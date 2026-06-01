// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

// Importamos as constantes de configuração centralizadas (V_MIN, V_MAX, DELTA_MAX, FLOOR_FACTOR)
import { PRICE_ENGINE_CONFIG } from "../config";

/**
 * Motor de precificação dinâmica do Balcão MesclaInvest.
 *
 * Calcula o novo preço do token de uma startup com base na pressão
 * de mercado das últimas 24 horas, usando interpolação linear (lerp).
 *
 * A ideia central é simples: se mais pessoas estão comprando do que vendendo,
 * o preço sobe. Se mais estão vendendo, o preço cai. A magnitude da variação
 * é proporcional ao volume líquido de negociação.
 *
 * @param currentPrice     Preço atual do token em BRL (ex: 10.50)
 * @param recentBuyVolume  Total de tokens comprados nas últimas 24h
 * @param recentSellVolume Total de tokens vendidos nas últimas 24h
 * @param initialPrice     Preço inicial de emissão do token em BRL (usado para calcular o piso)
 * @returns Novo preço recalculado do token em BRL
 */
export function calculateNewPrice(
  currentPrice: number,
  recentBuyVolume: number,
  recentSellVolume: number,
  initialPrice: number
): number {
  // Desestrutura os parâmetros de configuração para uso local
  const { V_MIN, V_MAX, DELTA_MAX, FLOOR_FACTOR } = PRICE_ENGINE_CONFIG;

  // Pressão líquida: positiva = mais compras, negativa = mais vendas.
  // Exemplo: 800 compras e 300 vendas → netPressure = +500 (pressão de alta)
  const netPressure = recentBuyVolume - recentSellVolume;

  // Se o valor absoluto da pressão não atingir V_MIN (100 tokens), o mercado
  // é considerado inativo e o preço permanece inalterado. Isso evita que
  // operações pontuais e de baixo volume causem flutuações desnecessárias.
  if (Math.abs(netPressure) < V_MIN) {
    return currentPrice;
  }

  // Limita (clamp) a pressão líquida ao intervalo [-V_MAX, V_MAX].
  // Se o volume for absurdamente alto (ex: 50.000 tokens), tratamos como V_MAX.
  // Isso torna o comportamento do preço previsível e evita manipulações.
  const clampedPressure = Math.max(-V_MAX, Math.min(V_MAX, netPressure));

  // Normaliza a pressão clampada para um valor t ∈ [0, 1].
  // Quando clampedPressure = -V_MAX → t = 0 (máxima pressão de venda)
  // Quando clampedPressure =  0     → t = 0.5 (mercado neutro)
  // Quando clampedPressure = +V_MAX → t = 1 (máxima pressão de compra)
  const t = (clampedPressure + V_MAX) / (2 * V_MAX);

  // Interpola linearmente o delta de variação entre -DELTA_MAX e +DELTA_MAX.
  // t=0  → delta = -0.05 (queda de 5%)
  // t=0.5 → delta = 0.00 (sem variação — este caso já seria bloqueado pelo V_MIN)
  // t=1  → delta = +0.05 (alta de 5%)
  const delta = -DELTA_MAX + t * (2 * DELTA_MAX);

  // Aplica a variação percentual ao preço atual.
  // Exemplo: currentPrice=10, delta=0.025 → newPrice = 10 * 1.025 = R$ 10,25
  let newPrice = currentPrice * (1 + delta);

  // Garante que o preço nunca caia abaixo do piso definido (FLOOR_FACTOR do preço inicial).
  // Se initialPrice = R$ 10,00 e FLOOR_FACTOR = 0.10 → piso = R$ 1,00
  // Isso protege startups em queda livre de chegar a R$ 0,00
  const floorPrice = initialPrice * FLOOR_FACTOR;
  if (newPrice < floorPrice) {
    newPrice = floorPrice;
  }

  // Retorna o novo preço calculado em BRL
  return newPrice;
}
