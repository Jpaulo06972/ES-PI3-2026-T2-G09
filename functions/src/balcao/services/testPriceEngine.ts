// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

// Importa a função principal do motor de preço que será testada
import { calculateNewPrice } from "./priceEngine";
// Importa as configurações para usar os mesmos parâmetros nos valores esperados
import { PRICE_ENGINE_CONFIG } from "../config";

/**
 * Conjunto de testes manuais (não usa framework de testes como Jest/Mocha)
 * para validar o comportamento do motor de precificação dinâmica.
 *
 * Cada caso de teste cobre um cenário específico, verificando se o
 * algoritmo de interpolação linear responde corretamente a diferentes
 * pressões de mercado.
 *
 * Para executar: `ts-node testPriceEngine.ts` na pasta services/
 */
function runTests() {
  console.log("=== INICIANDO TESTES DO MOTOR DE PREÇO (LINEAR INTERPOLATION) ===");
  // Imprime as constantes carregadas para confirmar que a configuração está correta
  console.log("Configurações Carregadas:", PRICE_ENGINE_CONFIG);

  // Preço base e inicial para todos os testes: R$ 10,00
  const currentPrice = 10.0; // R$ 10,00
  const initialPrice = 10.0; // R$ 10,00
  // O piso é 10% do preço inicial → R$ 1,00
  const floorPrice = initialPrice * PRICE_ENGINE_CONFIG.FLOOR_FACTOR; // R$ 1,00

  // ─── Caso 1: Pressão Neutra ──────────────────────────────────────────────────
  // Sem nenhuma negociação (0 compras, 0 vendas).
  // netPressure = 0 → abaixo de V_MIN → preço deve ser mantido em R$ 10,00
  const p1 = calculateNewPrice(currentPrice, 0, 0, initialPrice);
  console.log(`Teste 1 - Pressão Neutra: Esperado 10.00, Obtido ${p1.toFixed(2)} [${p1 === 10.0 ? "PASSED" : "FAILED"}]`);

  // ─── Caso 2: Volume abaixo do limiar mínimo ───────────────────────────────────
  // Com apenas 50 tokens comprados, estamos abaixo de V_MIN=100.
  // O algoritmo ignora esse volume e mantém o preço inalterado.
  const p2 = calculateNewPrice(currentPrice, 50, 0, initialPrice);
  console.log(`Teste 2 - Volume < V_MIN (50 < 100): Esperado 10.00, Obtido ${p2.toFixed(2)} [${p2 === 10.0 ? "PASSED" : "FAILED"}]`);

  // ─── Caso 3: Pressão máxima de compra ────────────────────────────────────────
  // Volume de compra = 12.000, mas clampado a V_MAX = 10.000.
  // t = 1, delta = +DELTA_MAX (+5%) → novo preço = R$ 10,50
  const p3 = calculateNewPrice(currentPrice, 12000, 0, initialPrice);
  const expectedP3 = currentPrice * (1 + PRICE_ENGINE_CONFIG.DELTA_MAX);
  console.log(`Teste 3 - Pressão Máxima Compra (12k >= 10k): Esperado ${expectedP3.toFixed(2)}, Obtido ${p3.toFixed(2)} [${Math.abs(p3 - expectedP3) < 1e-9 ? "PASSED" : "FAILED"}]`);

  // ─── Caso 4: Pressão máxima de venda ─────────────────────────────────────────
  // Volume de venda = 15.000, mas clampado a V_MAX = 10.000.
  // t = 0, delta = -DELTA_MAX (-5%) → novo preço = R$ 9,50
  const p4 = calculateNewPrice(currentPrice, 0, 15000, initialPrice);
  const expectedP4 = currentPrice * (1 - PRICE_ENGINE_CONFIG.DELTA_MAX);
  console.log(`Teste 4 - Pressão Máxima Venda (-15k <= -10k): Esperado ${expectedP4.toFixed(2)}, Obtido ${p4.toFixed(2)} [${Math.abs(p4 - expectedP4) < 1e-9 ? "PASSED" : "FAILED"}]`);

  // ─── Caso 5: Ativação do preço de piso (Floor Price) ─────────────────────────
  // Preço atual muito baixo (R$ 1,02) com pressão máxima de venda.
  // O cálculo resultaria em R$ ~0,97, mas o piso é R$ 1,00.
  // O motor deve retornar exatamente o floorPrice = R$ 1,00.
  const p5 = calculateNewPrice(1.02, 0, 10000, initialPrice);
  console.log(`Teste 5 - Preço de Piso (Floor Price limit): Esperado ${floorPrice.toFixed(2)}, Obtido ${p5.toFixed(2)} [${p5 === floorPrice ? "PASSED" : "FAILED"}]`);

  // ─── Caso 6: Pressão parcial de compra ───────────────────────────────────────
  // netPressure = 5.000 → metade de V_MAX.
  // t = (5000 + 10000) / 20000 = 0.75
  // delta = -0.05 + 0.75 * 0.10 = +0.025 (+2,5%)
  // novo preço = R$ 10,25
  const p6 = calculateNewPrice(currentPrice, 5000, 0, initialPrice);
  const expectedP6 = currentPrice * 1.025;
  console.log(`Teste 6 - Pressão Parcial Compra (5k / 10k): Esperado ${expectedP6.toFixed(2)}, Obtido ${p6.toFixed(2)} [${Math.abs(p6 - expectedP6) < 1e-9 ? "PASSED" : "FAILED"}]`);

  console.log("================ TESTS COMPLETED ================");
}

// Executa a suíte de testes imediatamente ao chamar o arquivo
runTests();
