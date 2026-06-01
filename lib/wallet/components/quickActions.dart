// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/startups/components/startup_colors.dart';

/// Barra de botões de Ações Rápidas ("Depositar", "Sacar", "Transferir").
///
/// Por que criamos um componente separado para isso?
/// Na tela principal (Home/Carteira), queremos manter o código principal enxuto.
/// Se a lógica visual desses três botõezinhos estivesse misturada lá no arquivo
/// principal, ele ficaria com centenas de linhas a mais só de código visual (padding, cores).
/// Separando aqui, deixamos a tela principal limpa e este componente fica reutilizável!
class QuickActions extends StatelessWidget {
  // Passamos as funções por parâmetro (callbacks).
  // Imagine que os botões aqui são como interruptores na parede: eles não sabem
  // *como* acender a lâmpada, eles só mandam o sinal "fui apertado!" para o
  // quadro de energia (a tela pai), que é quem realmente tem a lógica.
  final VoidCallback onDepositar;
  final VoidCallback onSacar;
  final VoidCallback onTransferir;

  const QuickActions({
    super.key,
    required this.onDepositar,
    required this.onSacar,
    required this.onTransferir,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Espaçamento nas laterais para a barra de botões não grudar na borda do celular.
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        // spaceBetween empurra o primeiro botão pro começo, o último pro final,
        // e centraliza o do meio. Fica perfeitamente distribuído!
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionButton(
            icon: Icons.add_circle_outline_rounded,
            label: "Depositar",
            color: const Color(0xFF107649), // Nosso verde padrão
            onTap: onDepositar,
          ),
          _buildActionButton(
            icon: Icons.account_balance_wallet_outlined,
            label: "Sacar",
            color: const Color(0xFF107649),
            onTap: onSacar,
          ),
          _buildActionButton(
            icon: Icons.swap_horiz_rounded,
            label: "Transferir",
            color: const Color(0xFF107649),
            onTap: onTransferir,
          ),
        ],
      ),
    );
  }

  /// Método privado que constrói os botõezinhos (cards).
  /// Reutilizamos o código 3 vezes sem ter que copiar e colar!
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    // GestureDetector é o widget mágico que transforma qualquer coisa em clicável.
    return GestureDetector(
      onTap: onTap, // Repassa o clique para quem chamou o widget.
      child: Container(
        // Fixamos a largura para garantir que os três botões tenham exatamente
        // o mesmo tamanho, mesmo que uma palavra seja maior que a outra.
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          // Puxamos a cor de fundo do nosso arquivo de temas centrais (StartupColors)
          color: StartupColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          // Borda quase invisível para dar um efeitinho 3D muito sutil no dark mode
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            // Esse Container interno é a "bolinha" que envolve o ícone.
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                // O fundo da bolinha é o verde, mas com 15% de opacidade (alpha: 0.15).
                // Isso cria aquele efeito "vidro" moderno.
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(child: Icon(icon, color: color, size: 22)),
            ),
            const SizedBox(height: 8),
            // O texto embaixo do ícone
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70, // 70% de branco = cinza claro elegante
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
