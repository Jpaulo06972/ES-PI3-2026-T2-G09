// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote do Flutter pra montar a interface
import 'package:flutter/material.dart';

// Botão de login social no estilo do Google
// Tem fundo transparente com borda cinza, o ícone colorido do Google e um texto
// Combina com o visual clean e moderno do app
// É StatelessWidget porque não tem estado interno
class SocialButton extends StatelessWidget {
  // label = texto que aparece no botão (ex: "Entrar com Google")
  final String label;

  // onPressed = função que roda quando o usuário clica
  // VoidCallback = função que não recebe nem retorna nada
  final VoidCallback onPressed;

  // Construtor - os dois são obrigatórios
  const SocialButton({super.key, required this.label, required this.onPressed});

  // Monta o botão na tela
  @override
  Widget build(BuildContext context) {
    // OutlinedButton = botão com borda e fundo transparente
    // É diferente do ElevatedButton que tem fundo colorido
    return OutlinedButton(
      // A função que roda quando clica
      onPressed: onPressed,

      // Estilo visual do botão
      style: OutlinedButton.styleFrom(
        // Espaçamento interno pra dar uma altura confortável
        padding: const EdgeInsets.symmetric(vertical: 12),

        // Cor da borda = cinza escuro (fica elegante no tema dark)
        side: BorderSide(color: Colors.grey.shade700),

        // Cantos arredondados (8 pixels de raio)
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

        // Fundo transparente pra aparecer a cor da tela atrás
        backgroundColor: Colors.transparent,
      ),

      // Conteúdo do botão: ícone do Google + texto, lado a lado
      child: Row(
        // Centraliza o conteúdo horizontalmente dentro do botão
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone oficial do Google carregado da internet (o "G" colorido)
          // Usamos Image.network pra buscar a imagem de uma URL
          Image.network(
            // URL da imagem oficial do Google no Wikimedia
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',

            // Tamanho do ícone (24x24 é o padrão de ícone)
            height: 24,

            // Enquanto a imagem tá carregando, mostra uma bolinha girando
            loadingBuilder: (context, child, loadingProgress) {
              // Se já carregou (progress é null), mostra a imagem
              if (loadingProgress == null) return child;

              // Se ainda tá carregando, mostra o loading
              return const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            },

            // Se deu erro (ex: sem internet), mostra um ícone genérico
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.login, color: Colors.white, size: 24);
            },
          ),

          // Espaço entre o ícone e o texto
          const SizedBox(width: 12),

          // O texto do botão
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white, // Texto branco
              fontWeight: FontWeight.w500, // Peso médio (nem fino nem negrito)
            ),
          ),
        ],
      ),
    );
  }
}
