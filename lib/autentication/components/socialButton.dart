// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote do Flutter pra montar a interface
import 'package:flutter/material.dart';

// Botão de login social no estilo Google
// Tem fundo transparente com borda cinza, o ícone colorido do Google e um texto
// Mantém um visual clean e moderno, diferente do botão primário (verde sólido)
// É StatelessWidget porque não tem nenhum estado interno que mude
class SocialButton extends StatelessWidget {
  // label = texto que aparece no botão
  // Exemplos: "Entrar com Google", "Cadastrar com Google"
  final String label;

  // onPressed = função que roda quando o usuário clica
  // VoidCallback = tipo do Dart para função sem parâmetros e sem retorno
  final VoidCallback onPressed;

  // Construtor — os dois parâmetros são obrigatórios
  const SocialButton({super.key, required this.label, required this.onPressed});

  // Monta o botão na tela
  @override
  Widget build(BuildContext context) {
    // OutlinedButton = botão com borda e fundo transparente
    // É a escolha certa aqui porque o botão social deve ser visualmente diferente
    // do botão principal (que é sólido e verde)
    return OutlinedButton(
      // A função que roda quando o usuário clica no botão
      onPressed: onPressed,

      // Estilo visual do botão
      style: OutlinedButton.styleFrom(
        // Padding vertical para dar altura confortável ao botão
        padding: const EdgeInsets.symmetric(vertical: 12),

        // Cor da borda: cinza escuro, fica elegante no tema escuro do app
        side: BorderSide(color: Colors.grey.shade700),

        // Cantos arredondados (8 pixels) — mesmo raio do botão primário para consistência
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

        // Fundo completamente transparente para mostrar a cor da tela por baixo
        backgroundColor: Colors.transparent,
      ),

      // Conteúdo do botão: ícone do Google + texto, lado a lado
      child: Row(
        // Centraliza o conteúdo (ícone + texto) horizontalmente dentro do botão
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone oficial do Google carregado da internet
          // Usamos Image.network porque manter a imagem no assets aumentaria o tamanho do app
          Image.network(
            // URL oficial do logo Google no Wikimedia Commons
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',

            // Tamanho 24x24 é o padrão recomendado para ícones de botão
            height: 24,

            // loadingBuilder = controla o que aparece enquanto a imagem está carregando
            // Isso evita que o botão fique com um espaço em branco no lugar do ícone
            loadingBuilder: (context, child, loadingProgress) {
              // Se loadingProgress é null, significa que já terminou de carregar
              // Então mostra a imagem de verdade
              if (loadingProgress == null) return child;

              // Enquanto ainda está baixando, mostra uma bolinha de loading
              // do mesmo tamanho que o ícone para não deslocar o layout
              return const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            },

            // errorBuilder = o que mostrar se a imagem não carregar
            // (por exemplo, sem internet ou URL quebrada)
            errorBuilder: (context, error, stackTrace) {
              // Fallback: ícone genérico de login — o botão ainda funciona visualmente
              return const Icon(Icons.login, color: Colors.white, size: 24);
            },
          ),

          // Espaço horizontal entre o ícone do Google e o texto
          const SizedBox(width: 12),

          // O texto do botão
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white, // Texto branco para contraste no tema escuro
              fontWeight: FontWeight.w500, // Peso médio (nem fino nem negrito)
            ),
          ),
        ],
      ),
    );
  }
}
