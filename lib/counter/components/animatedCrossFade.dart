// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote básico de UI do Flutter
import 'package:flutter/material.dart';

// Importa a paleta de cores oficial do módulo de startups para manter consistência visual
import 'package:mesclainvest_f/startups/components/startup_colors.dart';

class FilterCrossFade extends StatelessWidget {
  final bool showFilters;
  final Map<String?, String> filterOptions;
  final String? selectedFilter;
  final Function(String?) onFilterSelected;

  const FilterCrossFade({
    super.key,
    required this.showFilters,
    required this.filterOptions,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 250),
      crossFadeState: showFilters
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      firstChild: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filterOptions.entries.map((entry) {
            final key = entry.key;
            final label = entry.value;
            final isSelected = selectedFilter == key;

            // Cores temáticas para cada tipo de transação
            Color chipColor;
            if (key == null) {
              chipColor = const Color(0xFF4A90E2);
            } else if (key == 'deposito') {
              chipColor = StartupColors.green;
            } else if (key == 'investimento') {
              chipColor = const Color(0xFFF5A623);
            } else {
              chipColor = const Color(0xFF00B4D8);
            }

            return GestureDetector(
              onTap: () => onFilterSelected(key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? chipColor.withOpacity(0.2)
                      : const Color(0xFF2C2C30),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? chipColor
                        : Colors.white.withOpacity(0.08),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: chipColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? chipColor : Colors.white60,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      secondChild: const SizedBox.shrink(),
    );
  }
}
