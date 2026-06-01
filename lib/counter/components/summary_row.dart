// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

import 'package:flutter/material.dart';

/// Linha de resumo financeiro.
/// É aquele clássico formato de extrato: "Total ............ R$ 100,00".
/// Útil para mostrar o custo total ou saldo disponível antes de confirmar compras.
class SummaryRow extends StatelessWidget {
  /// O texto da esquerda (ex: 'Saldo disponível')
  final String label;
  
  /// O texto da direita (ex: 'R$ 5.000,00')
  final String value;
  
  /// Se true, pinta o valor da direita de verde e deixa negrito.
  /// Ideal pro "Total", pra chamar a atenção.
  final bool highlight;

  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      // spaceBetween joga o label pra extrema esquerda e o value pra extrema direita
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // O rótulo (Label) fica sempre cinza clarinho pra não roubar a cena
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        
        // O Valor financeiro
        Text(
          value,
          style: TextStyle(
            // Se highlight for true, usa o verde do sistema. Se não, usa branco.
            color: highlight ? const Color(0xFF1A9B5F) : Colors.white,
            fontSize: 13,
            // Destaca o peso da fonte também se for o "Total"
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
