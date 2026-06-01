// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';

/// O super banner verde que fica no topo da tela de Extrato Completo.
///
/// Por que ele existe? A tela de extrato não pode ser só uma lista infinita.
/// O usuário quer um resumo: "Beleza, de tudo isso aí, quanto entrou e quanto saiu?".
/// Esse banner pega as transações filtradas e exibe um painel executivo com o saldo total
/// e a soma das entradas/saídas.
class StatementSummaryBanner extends StatelessWidget {
  // O saldo que o usuário tem livre na carteira.
  final double saldo;

  // A matemática já vem pronta do componente pai:
  // Soma de todos os dinheiros que entraram (créditos)
  final double totalEntradas;

  // Soma de todos os dinheiros que saíram (débitos)
  final double totalSaidas;

  // Nossa cor marca-registrada salva numa constante bonitinha.
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
      width: double.infinity, // Ocupa toda a largura
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: primaryGreen,
        // Dica de UI: Como este banner fica encostado no topo da tela (perto do AppBar),
        // deixamos os cantos superiores retos e arredondamos só a parte de baixo!
        // Isso dá a sensação de que o banner está "pendurado" no topo.
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── SALDO PRINCIPAL ──
          Text(
            'Saldo disponível',
            style: TextStyle(
              fontSize: 13,
              // Branco com um tiquinho de transparência para não roubar a cena do numerão
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyInputFormatter.formatValue(
              saldo,
            ), // Já formata bonitinho: "R$ 1.250,00"
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800, // Extrabold pra ser o dono da tela
              color: Colors.white,
              letterSpacing: -0.5, // Números grandes pedem espaçamento reduzido
            ),
          ),

          const SizedBox(height: 16), // Aquele respiro bacana
          // ── MINI-CARDS DE RESUMO (Entradas e Saídas) ──
          // Uma Row para botar os dois lado a lado.
          Row(
            children: [
              // O Expanded faz o card ocupar exatamente metade do espaço disponível.
              Expanded(
                child: _buildSummaryCard(
                  label: 'Entradas',
                  value: totalEntradas,
                  icon: Icons
                      .arrow_downward_rounded, // Dinheiro caindo na conta = seta pra baixo
                ),
              ),
              const SizedBox(width: 10), // Espaço entre os dois cards
              // O outro Expanded ocupa a outra metade.
              Expanded(
                child: _buildSummaryCard(
                  label: 'Saídas',
                  value: totalSaidas,
                  icon: Icons
                      .arrow_upward_rounded, // Dinheiro indo embora = seta pra cima
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construtor dos nossos mini-cards.
  /// Em vez de repetir esse monte de Container, Color, Text, Icon duas vezes,
  /// a gente cria uma função privada e só chama ela passando o que muda. DRY na veia!
  Widget _buildSummaryCard({
    required String label,
    required double value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        // O fundo do card é um branco com 12% de opacidade.
        // Como o banner por trás é verde escuro, isso cria um efeito "vidro" incrível.
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // A bolinha do ícone.
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              // Mais branco transparente ainda pra bolinha se destacar
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),

          // O texto dentro do card. Usamos Expanded pro texto não estourar a caixa
          // caso o valor seja gigantesco (tipo 1 bilhão de reais rs).
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label, // "Entradas" ou "Saídas"
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10, // Bem pequenininho, só de guia
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
                  // Se o valor for muito grande, bota "..." no final e não quebra o layout.
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
