// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:flutter/material.dart';

/// Chips de filtro horizontais usados na tela de extrato completo.
/// Cada chip representa uma categoria de transação.
class StatementFilterChips extends StatelessWidget {
  final Map<String?, String> filterOptions;
  final String? selectedFilter;
  final ValueChanged<String?> onFilterSelected;

  // Cor principal da aplicação
  static const Color primaryGreen = Color(0xFF107649);

  const StatementFilterChips({
    super.key,
    required this.filterOptions,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filterOptions.length,
        separatorBuilder: (_, _i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final key = filterOptions.keys.elementAt(index);
          final label = filterOptions.values.elementAt(index);
          final isActive = selectedFilter == key;

          return GestureDetector(
            onTap: () => onFilterSelected(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? primaryGreen
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? primaryGreen
                      : Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: isActive
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
