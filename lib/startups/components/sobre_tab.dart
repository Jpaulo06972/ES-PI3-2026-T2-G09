// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684
// Feito originalmente por: Tomás Toniato RA: 25004211

import 'package:flutter/material.dart';
import 'startup_colors.dart';

/// Aba que exibe a tese de investimento, o problema e as métricas da startup.
class SobreTab extends StatelessWidget {
  // Mapa contendo os dados detalhados da startup
  final Map<String, dynamic> details;

  const SobreTab({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        // Tese de Investimento
        const _SectionTitle('TESE DE INVESTIMENTO'),
        const SizedBox(height: 16),
        Text(
          (details['description'] ?? 'Sem descrição disponível.').toString(),
          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6),
        ),
        
        const SizedBox(height: 32),
        
        // O Problema
        const _SectionTitle('O PROBLEMA'),
        const SizedBox(height: 16),
        _ProblemCard(text: (details['problemDescription'] ?? 'Informação não disponível.').toString()),
        
        const SizedBox(height: 32),
        
        // Métricas e Mercado
        const _SectionTitle('MÉTRICAS E MERCADO'),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _StatCard(
              label: 'Mercado Total',
              value: (details['marketSize'] ?? 'N/A').toString(),
              icon: Icons.public_rounded,
            ),
            _StatCard(
              label: 'Base de Clientes',
              value: (details['clientBase'] ?? 'N/A').toString(),
              icon: Icons.people_alt_rounded,
            ),
            _StatCard(
              label: 'Receita Mensal',
              value: (details['monthlyRevenue'] ?? 'N/A').toString(),
              icon: Icons.payments_rounded,
            ),
            _StatCard(
              label: 'Preço/Token',
              value: 'R\$ ${((details['currentTokenPriceCents'] ?? 0) / 100).toStringAsFixed(2)}',
              icon: Icons.token_rounded,
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

/// Card para exibição do problema que a startup resolve.
class _ProblemCard extends StatelessWidget {
  final String text;
  const _ProblemCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StartupColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: StartupColors.green, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card para exibição de métricas individuais.
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StartupColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: StartupColors.green, size: 14),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Título de seção padronizado.
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: StartupColors.green,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }
}
