// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:flutter/material.dart';

/// Cabeçalho da seção de extrato com contador de itens e botão de filtro.
class StatementHeader extends StatelessWidget {
  final int count;
  final bool showFilters;
  final bool hasActiveFilter;
  final VoidCallback onToggleFilters;

  const StatementHeader({
    super.key,
    required this.count,
    required this.showFilters,
    required this.hasActiveFilter,
    required this.onToggleFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              'Extrato',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            // Badge com a contagem de itens visíveis
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF107649).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        // Botão que expande os filtros
        GestureDetector(
          onTap: onToggleFilters,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: showFilters || hasActiveFilter
                  ? const Color(0xFF107649)
                  : const Color(0xFF3A3A3D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: showFilters || hasActiveFilter
                  ? Colors.white
                  : Colors.white70,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}
