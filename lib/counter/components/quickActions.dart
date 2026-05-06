// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote básico de UI do Flutter
import 'package:flutter/material.dart';

// Importa a paleta de cores oficial do módulo de startups para manter consistência visual
import 'package:mesclainvest_f/startups/components/startup_colors.dart';

/// Barra de ações rápidas com botões no estilo das telas de startups.
/// Cada botão usa o padrão de card com borda sutil e ícone centralizado.
class QuickActions extends StatelessWidget {
  // Callbacks para cada ação — a página pai controla o comportamento
  final VoidCallback onDepositar;
  final VoidCallback onPagar;
  final VoidCallback onTransferir;

  const QuickActions({
    super.key,
    required this.onDepositar,
    required this.onPagar,
    required this.onTransferir,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Cada ação ocupa um terço igual da largura disponível
        Expanded(
          child: _buildActionButton(
            icon: Icons.add_circle_outline_rounded,
            label: "Depositar",
            color: StartupColors.green,
            onTap: onDepositar,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.payment_rounded,
            label: "Pagar",
            color: StartupColors.green,
            onTap: onPagar,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.swap_horiz_rounded,
            label: "Transferir",
            color: StartupColors.green,
            onTap: onTransferir,
          ),
        ),
      ],
    );
  }

  // Constrói um card de ação no estilo _StatCard das telas de startups
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          // Mesmo fundo cardBg das telas de startups
          color: StartupColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          // Borda sutil igual às telas de detalhes
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            // Círculo com cor de fundo translúcida — igual aos badges dos cards
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, color: color, size: 22),
              ),
            ),
            const SizedBox(height: 8),
            // Label abaixo do ícone — mesmo estilo de texto dos cards de startups
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
