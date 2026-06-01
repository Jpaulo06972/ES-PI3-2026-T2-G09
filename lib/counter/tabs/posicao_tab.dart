// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

// Aba "Posição".
// Fica embutida na tela de ordens de uma startup específica (BalcaoOrdersScreen).
// Mostra o saldo de tokens que ele tem e o principal: o Lucro/Prejuízo dele (P&L) naquela startup.

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/counter/components/balcao_info_row.dart';
import 'package:mesclainvest_f/startups/components/startup_colors.dart';

/// Aba que cospe um resumão estatístico da carteira do usuário focada em 1 startup.
/// É burra (Stateless), só pega os dados matemáticos que já foram calculados ou lidos lá em cima.
class PosicaoTab extends StatelessWidget {
  final int userTokenHolding;
  final int averagePriceCents;
  final double currentMarketPrice;
  final String Function(double) fmtBRL;

  const PosicaoTab({
    super.key,
    required this.userTokenHolding,
    required this.averagePriceCents,
    required this.currentMarketPrice,
    required this.fmtBRL,
  });

  @override
  Widget build(BuildContext context) {
    // Se o maluco não tem nada investido aqui, exibe a tela de aviso nua e crua.
    if (userTokenHolding == 0) {
      return const Center(
        child: Text(
          'Você não possui tokens desta startup.',
          style: TextStyle(color: Colors.white, fontSize: 13),
        ),
      );
    }

    // Traz de centavos pra reais pra não fundir o cérebro com matemática básica.
    final avgBRL = averagePriceCents / 100.0;
    
    // Valor total HOJE (se ele vender tudo nesse segundo).
    final positionValue = userTokenHolding * currentMarketPrice;
    
    // Valor total PAGO (o custo histórico da brincadeira).
    final investedValue = userTokenHolding * avgBRL;

    // Cálculo do P&L Absoluto (R$).
    final pl = userTokenHolding * (currentMarketPrice - avgBRL);
    
    // Cálculo do P&L Relativo (%). Cuidado com divisão por zero!
    final plPct = avgBRL > 0
        ? ((currentMarketPrice - avgBRL) / avgBRL) * 100
        : 0.0;
        
    // Regra clássica de homebroker: Deu bom = Verde. Deu ruim = Vermelho.
    final plColor = pl >= 0 ? StartupColors.green : const Color(0xFFE74C3C);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      // Container com cantos curvos e fundo estilo Black Mode.
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141416),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Destaque master: Quanto de grana virtual ele tem agora aqui.
            BalcaoInfoRow(
              label: 'Posição atual',
              value: fmtBRL(positionValue),
              big: true, // Fonte gordinha.
            ),
            const Divider(color: Colors.white, height: 20),
            
            // As entranhas do cálculo descritas detalhadamente.
            BalcaoInfoRow(
              label: 'Quantidade',
              value: '$userTokenHolding tokens',
            ),
            const SizedBox(height: 8),
            BalcaoInfoRow(
              label: 'Preço médio',
              // Se tiver preço médio, formata em reais, se não mete um tracinho '--'.
              value: averagePriceCents > 0 ? fmtBRL(avgBRL) : '--',
            ),
            const SizedBox(height: 8),
            BalcaoInfoRow(
              label: 'Custo total',
              value: investedValue > 0 ? fmtBRL(investedValue) : '--',
            ),
            const SizedBox(height: 8),
            
            // Linha final com a facada ou a glória (Lucro / Perda).
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lucro / Perda',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                Text(
                  // Coloca os sinaizinhos (+ ou -) na frente dependendo se ele tá bem na fita ou não.
                  '${pl >= 0 ? '+' : ''}${fmtBRL(pl)} | '
                  '${plPct >= 0 ? '+' : ''}${plPct.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: plColor, // A mágica da cor dinâmica rolando aqui.
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
