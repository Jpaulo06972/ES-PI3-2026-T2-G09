// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:flutter/material.dart';

/// Linha de detalhe chave-valor com ícone à direita.
/// Usada na tela de ação de transação para exibir informações como
/// "Quando", "Via" e "Mensagem".
class TransactionDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const TransactionDetailRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Icon(icon, color: Colors.white54, size: 22),
      ],
    );
  }
}
