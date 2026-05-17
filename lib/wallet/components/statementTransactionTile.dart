// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';
import 'package:mesclainvest_f/wallet/pages/operationExtract.dart';

/// Tile individual de transação estilo Nubank para a tela de extrato completo.
/// Mostra ícone, título, subtítulo, valor e horário com navegação ao comprovante.
class StatementTransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;

  const StatementTransactionTile({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    final bool isCredit = tx['isCredit'] as bool;
    final Color valueColor = isCredit
        ? const Color(0xFF2ECC71)
        : const Color(0xFFE74C3C);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OperationExtractPage(tx: tx)),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            // Ícone com fundo circular
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: valueColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  tx['icon'] as IconData,
                  color: valueColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Título + subtítulo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((tx['subtitle'] as String).isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      tx['subtitle'] as String,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Valor + horário
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${isCredit ? '+' : '-'} ${CurrencyInputFormatter.formatValue(tx['value'] as double)}",
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _extractTime(tx['date'] as String),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Extrai só a hora da data "dd/MM/yyyy HH:mm" → "HH:mm"
  String _extractTime(String dateStr) {
    final parts = dateStr.split(' ');
    if (parts.length >= 2) {
      return parts[1];
    }
    return '';
  }
}
