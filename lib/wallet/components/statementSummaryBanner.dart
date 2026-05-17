// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';

/// Banner superior verde com resumo de saldo, entradas e saídas.
/// Usado na tela de extrato completo (StatementPage).
class StatementSummaryBanner extends StatelessWidget {
  final double saldo;
  final double totalEntradas;
  final double totalSaidas;

  // Cor principal da aplicação
  static const Color primaryGreen = Color(0xFF107649);

  const StatementSummaryBanner({
    super.key,
    required this.saldo,
    required this.totalEntradas,
    required this.totalSaidas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 20,
      ),
      decoration: const BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saldo atual
          Text(
            'Saldo disponível',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyInputFormatter.formatValue(saldo),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),

          // Resumo entradas/saídas
          Row(
            children: [
              // Entradas
              Expanded(
                child: _buildSummaryCard(
                  label: 'Entradas',
                  value: totalEntradas,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 10),
              // Saídas
              Expanded(
                child: _buildSummaryCard(
                  label: 'Saídas',
                  value: totalSaidas,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói um card de resumo (entradas ou saídas)
  Widget _buildSummaryCard({
    required String label,
    required double value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.7,
                    ),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  CurrencyInputFormatter.formatValue(value),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
