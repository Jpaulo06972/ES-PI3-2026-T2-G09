// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:flutter/material.dart';

/// Exibição visual para quando não há transações encontradas.
class EmptyTransactions extends StatelessWidget {
  const EmptyTransactions({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              color: Colors.white24,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Nenhuma transação encontrada.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
