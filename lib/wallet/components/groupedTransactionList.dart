// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/wallet/components/statementTransactionTile.dart';

/// Lista de transações agrupada por data com separadores estilo Nubank.
/// Exibe as transações organizadas por dia com labels como "HOJE", "ONTEM", etc.
class GroupedTransactionList extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  // Cor principal da aplicação
  static const Color primaryGreen = Color(0xFF107649);

  const GroupedTransactionList({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate(transactions);
    final dateKeys = grouped.keys.toList();

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 4,
      ),
      itemCount: dateKeys.length,
      itemBuilder: (context, groupIndex) {
        final dateKey = dateKeys[groupIndex];
        final items = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Separador de data (estilo Nubank)
            Padding(
              padding: const EdgeInsets.only(
                top: 16,
                bottom: 8,
              ),
              child: Row(
                children: [
                  Text(
                    _formatDateLabel(dateKey),
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.4,
                      ),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(
                        alpha: 0.06,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Lista de transações daquele dia
            ...items.map((tx) => StatementTransactionTile(tx: tx)),
          ],
        );
      },
    );
  }

  /// Agrupa transações por data (dd/MM/yyyy) para exibir com separadores
  Map<String, List<Map<String, dynamic>>> _groupByDate(
    List<Map<String, dynamic>> transactions,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final tx in transactions) {
      // Pega só a parte da data (sem hora), ex: "14/05/2026"
      final dateStr = (tx['date'] as String).split(' ').first;
      grouped.putIfAbsent(dateStr, () => []);
      grouped[dateStr]!.add(tx);
    }
    return grouped;
  }

  /// Formata a label da data para exibir "Hoje", "Ontem" ou a data formatada
  String _formatDateLabel(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length >= 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final date = DateTime(year, month, day);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));

        if (date == today) return 'HOJE';
        if (date == yesterday) return 'ONTEM';

        const months = [
          '',
          'JAN',
          'FEV',
          'MAR',
          'ABR',
          'MAI',
          'JUN',
          'JUL',
          'AGO',
          'SET',
          'OUT',
          'NOV',
          'DEZ',
        ];
        return '${day.toString().padLeft(2, '0')} ${months[month]} $year';
      }
    } catch (_) {}
    return dateStr;
  }
}
