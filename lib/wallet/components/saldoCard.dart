// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';

/// Aquele clássico "Cartãozão de Saldo" que fica no topo da tela inicial.
///
/// Ele exibe o valor em reais e o botão de "olhinho" para esconder a grana.
/// Privacidade em apps financeiros não é frescura, é exigência básica: o usuário
/// pode estar no ônibus ou no trabalho e não quer ninguém bisbilhotando a tela dele.
class SaldoCard extends StatelessWidget {
  // A quantidade de dinheiro em si. Vem do banco de dados (provavelmente via Provider ou bloc).
  final double saldo;

  // Se true, mostra "R$ 1.500,00". Se false, mostra "R$ ••••••".
  // A gente controla isso lá fora, não aqui dentro.
  final bool isVisible;

  // O botão do olho não muda o estado aqui! Ele apenas avisa o widget pai:
  // "Alguém apertou o olho, troca o boolean aí e me desenha de novo!"
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
      // Estica horizontalmente para ocupar a tela inteira (respeitando o padding do pai)
      width: double.infinity,
      // Padding interno dá "ar" para as coisas não grudarem nas bordas do cartão
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // Cor chapada e forte. Decidimos não usar gradiente aqui para manter
        // um design mais flat e moderno, alinhado ao branding da marca.
        color: const Color(0xFF107649),
        borderRadius: BorderRadius.circular(20),

        // Efeito "Glow" (brilho) em vez de apenas uma sombra preta.
        // Sombras coloridas passam uma vibe muito premium, parecendo neon no Dark Mode.
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF107649,
            ).withValues(alpha: 0.25), // Sombra verde translúcida
            blurRadius: 20, // O quão espalhada ela é
            offset: const Offset(0, 8), // Desloca a sombra para baixo
          ),
        ],
      ),
      // Column empilha as coisas de cima para baixo
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Tudo alinhadinho à esquerda
        children: [
          // ── CABEÇALHO DO CARD ──
          Row(
            // Joga os dois elementos da linha pros cantos opostos (Label na esq, Olho na dir)
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Grupo do texto "Saldo disponível" + ícone
              Row(
                children: [
                  // Íconezinho de carteira dentro de uma bolinha estilosa
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.15,
                      ), // Branco transparente
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 16, // Ícone pequenininho para ficar delicado
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Título da seção
                  const Text(
                    "Saldo disponível",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              // ── BOTÃO DO OLHO ──
              // Envolvemos no GestureDetector para capturar o toque
              GestureDetector(
                onTap: onToggleVisibility,
                child: Container(
                  width: 36,
                  height: 36,
                  // Fundo parecido com o da carteirinha ali de cima
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      // Se está visível, mostra o olho aberto. Se não, olho cortado.
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

          const SizedBox(height: 20), // Respiro antes do numerão
          // ── VALOR EM DINHEIRO ──
          Text(
            // Se isVisible = true, formata os double "1500" para "R$ 1.500,00".
            // Se isVisible = false, mascara tudo com bolinhas.
            isVisible
                ? CurrencyInputFormatter.formatValue(saldo)
                : "R\$ ••••••",
            style: const TextStyle(
              fontSize: 36, // Bem grandão
              fontWeight: FontWeight
                  .w800, // Extrabold pra mostrar que é a info principal da tela
              color: Colors.white,
              // Truque de tipografia: números grandes ficam melhores com letterSpacing negativo,
              // aproxima os dígitos e fica mais "coeso".
              letterSpacing: -0.5,
              height: 1.0, // Altura da linha exata da fonte
            ),
          ),

          const SizedBox(height: 16), // Respiro final no fundo do card
        ],
      ),
    );
  }
}
