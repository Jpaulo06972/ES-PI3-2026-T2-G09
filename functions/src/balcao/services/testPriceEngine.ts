// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import { calculateNewPrice } from "./priceEngine";
import { PRICE_ENGINE_CONFIG } from "../config";

function runTests() {
  console.log("=== INICIANDO TESTES DO MOTOR DE PREÇO (LINEAR INTERPOLATION) ===");
  console.log("Configurações Carregadas:", PRICE_ENGINE_CONFIG);
  
  const currentPrice = 10.0; // R$ 10,00
  const initialPrice = 10.0; // R$ 10,00
  const floorPrice = initialPrice * PRICE_ENGINE_CONFIG.FLOOR_FACTOR; // R$ 1,00

  // Caso 1: Pressão Neutra (Sem compras nem vendas)
  // netPressure = 0 -> delta deve ser 0 -> novo preço deve ser R$ 10,00
  const p1 = calculateNewPrice(currentPrice, 0, 0, initialPrice);
  console.log(`Teste 1 - Pressão Neutra: Esperado 10.00, Obtido ${p1.toFixed(2)} [${p1 === 10.0 ? "PASSED" : "FAILED"}]`);

  // Caso 2: Pressão abaixo do Limiar Mínimo (Volume < V_MIN)
  // netPressure = 50 (com V_MIN = 100) -> delta deve ser 0 -> novo preço deve ser R$ 10,00
  const p2 = calculateNewPrice(currentPrice, 50, 0, initialPrice);
  console.log(`Teste 2 - Volume < V_MIN (50 < 100): Esperado 10.00, Obtido ${p2.toFixed(2)} [${p2 === 10.0 ? "PASSED" : "FAILED"}]`);

  // Caso 3: Pressão Máxima de Compra (Volume >= V_MAX)
  // netPressure = 12000 (com V_MAX = 10000) -> clamped a 10000 -> delta deve ser +5% (+0.05) -> novo preço deve ser R$ 10,50
  const p3 = calculateNewPrice(currentPrice, 12000, 0, initialPrice);
  const expectedP3 = currentPrice * (1 + PRICE_ENGINE_CONFIG.DELTA_MAX);
  console.log(`Teste 3 - Pressão Máxima Compra (12k >= 10k): Esperado ${expectedP3.toFixed(2)}, Obtido ${p3.toFixed(2)} [${Math.abs(p3 - expectedP3) < 1e-9 ? "PASSED" : "FAILED"}]`);

  // Caso 4: Pressão Máxima de Venda (Volume >= V_MAX)
  // netPressure = -15000 -> clamped a -10000 -> delta deve ser -5% (-0.05) -> novo preço deve ser R$ 9,50
  const p4 = calculateNewPrice(currentPrice, 0, 15000, initialPrice);
  const expectedP4 = currentPrice * (1 - PRICE_ENGINE_CONFIG.DELTA_MAX);
  console.log(`Teste 4 - Pressão Máxima Venda (-15k <= -10k): Esperado ${expectedP4.toFixed(2)}, Obtido ${p4.toFixed(2)} [${Math.abs(p4 - expectedP4) < 1e-9 ? "PASSED" : "FAILED"}]`);

  // Caso 5: Enforcamento do Preço de Piso (Floor Price)
  // Se o preço atual for R$ 1,02 e houver pressão de venda que o derrubaria para R$ 0,97:
  // Como o piso é 10% do inicial (R$ 1,00), o preço deve ser clampado em R$ 1,00!
  const p5 = calculateNewPrice(1.02, 0, 10000, initialPrice);
  console.log(`Teste 5 - Preço de Piso (Floor Price limit): Esperado ${floorPrice.toFixed(2)}, Obtido ${p5.toFixed(2)} [${p5 === floorPrice ? "PASSED" : "FAILED"}]`);

  // Caso 6: Pressão Parcial de Compra
  // netPressure = 5000 (metade de V_MAX) -> t deve ser 0.75 -> delta deve ser +2.5% (+0.025) -> novo preço deve ser R$ 10,25
  const p6 = calculateNewPrice(currentPrice, 5000, 0, initialPrice);
  const expectedP6 = currentPrice * 1.025;
  console.log(`Teste 6 - Pressão Parcial Compra (5k / 10k): Esperado ${expectedP6.toFixed(2)}, Obtido ${p6.toFixed(2)} [${Math.abs(p6 - expectedP6) < 1e-9 ? "PASSED" : "FAILED"}]`);

  console.log("================ TESTS COMPLETED ================");
}

runTests();
