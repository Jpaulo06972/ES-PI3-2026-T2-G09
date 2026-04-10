// Importa o pacote do Flutter pra montar a interface
import 'package:flutter/material.dart';

// Link clicável que navega pra outra tela do app
// Funciona tipo a tag <a href="..."> do HTML
// Mostra um texto com sublinhado e quando clica leva pra página de destino
// É StatelessWidget porque não tem estado interno
class NavLink extends StatelessWidget {
  // label = o texto que aparece no link (ex: "Cadastre-se", "Esqueci minha senha")
  final String label;

  // destination = a tela pra onde o usuário vai quando clicar
  final Widget destination;

  // Construtor - os dois são obrigatórios
  const NavLink({super.key, required this.label, required this.destination});

  // Monta o link na tela
  @override
  Widget build(BuildContext context) {
    // Pega a cor primária do tema (verde/azul) pra usar no texto e na linha
    final Color linkColor = Theme.of(context).colorScheme.primary;

    // GestureDetector = detecta toques em qualquer widget
    // Usamos ele porque o Container sozinho não sabe responder a cliques
    return GestureDetector(
      // Quando o usuário toca no link
      onTap: () {
        // Navigator.push = empilha uma nova tela na pilha de navegação
        // É como abrir uma nova página no navegador
        Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
      },

      // Center = centraliza o link na tela (pra não ficar colado na esquerda)
      child: Center(
        // Container = uma caixa que a gente pode decorar com bordas
        // Usamos ele pra fazer o sublinhado customizado
        // (o underline padrão do Flutter fica grudado demais no texto)
        child: Container(
          // Pequeno espaço entre o texto e a linha de baixo
          padding: const EdgeInsets.only(bottom: 1),

          // Decoração: só uma borda embaixo (o sublinhado)
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: linkColor, // Mesma cor do texto
                width: 1,        // Espessura da linha
              ),
            ),
          ),

          // O texto do link em si
          child: Text(
            label,
            style: TextStyle(
              color: linkColor,         // Cor do texto (primária do tema)
              fontWeight: FontWeight.bold, // Negrito pra destacar que é clicável
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
