// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:flutter/material.dart';

/// Componente de cabeçalho da página de carteira, com título e descrição.
class WalletHeader extends StatelessWidget {
  const WalletHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minha Carteira',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Gerencie seu saldo, recarregue e acompanhe seu extrato.',
          style: TextStyle(color: Colors.white60, fontSize: 15, height: 1.4),
        ),
      ],
    );
  }
}
