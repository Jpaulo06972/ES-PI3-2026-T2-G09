// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote básico de UI do Flutter
import 'package:flutter/material.dart';

// Importa a paleta de cores oficial para manter consistência visual
import 'package:mesclainvest_f/startups/components/startup_colors.dart';

/// Card que exibe o saldo disponível do usuário com opção de ocultar o valor.
/// Usa verde sólido (sem degradê) no estilo premium das telas de startups.
class SaldoCard extends StatelessWidget {
  // Saldo atual do usuário em reais
  final double saldo;

  // Controla se o valor do saldo está visível ou oculto (••••••)
  final bool isVisible;

  // Callback disparado ao tocar no ícone de visibilidade (olho)
  final VoidCallback onToggleVisibility;

  const SaldoCard({
    super.key,
    required this.saldo,
    required this.isVisible,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // Verde sólido — cor principal da aplicação, sem degradê
        color: StartupColors.green,
        borderRadius: BorderRadius.circular(20),
        // Sombra verde sutil para dar profundidade e destaque premium
        boxShadow: [
          BoxShadow(
            color: StartupColors.green.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Linha superior: label + botão de visibilidade ──────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Label com ícone de carteira ao lado
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Saldo disponível",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              // Botão que alterna a visibilidade do saldo (olho)
              GestureDetector(
                onTap: onToggleVisibility,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isVisible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Valor do saldo ────────────────────────────────────────────
          Text(
            isVisible
                ? "R\$ ${saldo.toStringAsFixed(2)}"
                : "R\$ ••••••",
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),

          const SizedBox(height: 16),

          // ── Separador sutil ────────────────────────────────────────────
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.15),
          ),

          const SizedBox(height: 14),

          // ── Indicadores de rendimento ─────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Rendimento CDI — badge translúcido
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 5),
                    Text(
                      "102% do CDI",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Indicador de variação positiva
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 3),
                    Text(
                      "+0,84%",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
