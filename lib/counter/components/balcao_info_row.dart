// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/startups/components/startup_colors.dart';

/// Uma linhazinha de informação muito elegante que usamos no painel do Balcão.
/// Ele pega um rótulo (ex: "Saldo Disponível") e um valor (ex: "R$ 1.500,00")
/// e joga cada um pra um lado da tela (Row com spaceBetween).
///
/// Como a gente repete muito esse padrão (para Saldo, Preço, Custo, etc),
/// criar um componente separado deixa o código limpo e garante que todas
/// as métricas fiquem alinhadas perfeitamente.
class BalcaoInfoRow extends StatelessWidget {
  // O nome da métrica que vai na esquerda.
  final String label;

  // O número formatado que vai na direita.
  final String value;

  // Parâmetro visual 1: Devo pintar de verde pra chamar a atenção do usuário?
  // Geralmente a gente usa isso pra mostrar lucros ou valores positivos.
  final bool highlight;

  // Parâmetro visual 2: É o número MAIS importante da tela?
  // Se for true, a gente dá uma "bombada" no tamanho da fonte.
  final bool big;

  const BalcaoInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false, // Por padrão, não destaca nada (fica branquinho).
    this.big = false, // Por padrão, tamanho de fonte normal.
  });

  @override
  Widget build(BuildContext context) {
    // Definindo a cor: se o programador pediu highlight, pinta de verde. Se não, branco normal.
    Color valColor = highlight ? StartupColors.green : Colors.white;

    // A mágica da hierarquia visual: quanto mais importante a métrica, maior a fonte.
    double fontSize;
    if (big) {
      fontSize = 17; // Pra métricas principais (ex: Total da Carteira).
    } else if (highlight) {
      fontSize = 15; // Pra métricas em destaque mas que não são a principal.
    } else {
      fontSize =
          14; // O tamanho padrão pra "encher linguiça" (brincadeira, pra informações secundárias).
    }

    // Se a fonte for big ou highlight, a gente engrossa a letra pra dar mais peso visual (w800).
    // Senão, fica só um semi-bold (w600).
    FontWeight fontWeight = (highlight || big)
        ? FontWeight.w800
        : FontWeight.w600;

    return Row(
      // Esse cara é o responsável por empurrar o 'label' pra extrema esquerda
      // e o 'value' pra extrema direita. Típico de app financeiro!
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // --- O LABEL (Rótulo) ---
        // Fica sempre com a cor branquinha e fonte 13 pra não ofuscar o valor.
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),

        // --- O VALOR ---
        // Aqui a gente aplica toda aquela lógica de cor e tamanho que calculamos lá em cima.
        Text(
          value,
          style: TextStyle(
            color: valColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
      ],
    );
  }
}
