// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

import 'package:flutter/material.dart';

/// Um botão quadrado bem bonitão usado naqueles controles de "+ e -".
/// Isolar isso aqui previne repetição de Container e GestureDetector
/// toda vez que a gente for fazer um Stepper.
class StepperButton extends StatelessWidget {
  /// O ícone (normalmente Icons.add ou Icons.remove)
  final IconData icon;
  
  /// O que acontece quando aperta o botão
  final VoidCallback onTap;

  const StepperButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Fica um quadrado perfeito (52x52)
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          // Pega o verde padrão (0xFF107649) e bota 15% de opacidade pra virar o Fundo
          color: const Color(0xFF107649).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(11), // Quase redondo
        ),
        // O Ícone em si usa o verde cheio. Isso cria aquele efeito "tom sobre tom" chique.
        child: Icon(icon, color: const Color(0xFF107649), size: 22),
      ),
    );
  }
}
