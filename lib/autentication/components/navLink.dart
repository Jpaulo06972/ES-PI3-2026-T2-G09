// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote do Flutter pra montar a interface
import 'package:flutter/material.dart';

// Link clicável que navega pra outra tela do app
// Funciona de forma similar à tag <a href="..."> do HTML
// Mostra um texto com sublinhado e quando clica leva pra página de destino
// É StatelessWidget porque não guarda nenhum estado: só exibe e responde a cliques
class NavLink extends StatelessWidget {
  // label = o texto que aparece no link
  // Exemplos: "Cadastre-se", "Esqueci minha senha", "Voltar para o login"
  final String label;

  // destination = a tela pra onde o usuário vai quando clicar
  // Recebemos um Widget genérico para poder navegar para qualquer tela
  final Widget destination;

  // Construtor — os dois parâmetros são obrigatórios:
  // sem label não tem texto pra clicar, sem destination não sabe pra onde ir
  const NavLink({super.key, required this.label, required this.destination});

  // Monta o link na tela
  @override
  Widget build(BuildContext context) {
    // Pega a cor primária do tema do app (verde) para usar no texto e na linha
    // Hardcoded aqui para manter consistência visual em todos os links
    final Color linkColor = Color(0xFF107649);

    // GestureDetector = detecta toques em qualquer widget
    // Usamos ele porque o Container sozinho não responde a cliques
    // OnTap é a forma padrão de capturar toque único (equivalente ao onClick do HTML)
    return GestureDetector(
      // Quando o usuário toca no link, navega para a tela de destino
      onTap: () {
        // Navigator.push = empilha uma nova tela na pilha de navegação
        // É como abrir uma nova página: a tela atual fica atrás e pode voltar com "back"
        // MaterialPageRoute cria a animação de transição padrão do Material Design
        Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
      },

      // Center = centraliza o link na tela (pra não ficar colado na margem esquerda)
      child: Center(
        // Container com decoração de borda embaixo (o sublinhado do link)
        // Preferimos fazer o sublinhado assim porque o TextDecoration.underline
        // do Flutter fica muito colado na letra — o container dá mais controle visual
        child: Container(
          // Pequeno espaço entre o texto e a linha de baixo
          padding: const EdgeInsets.only(bottom: 1),

          // Decoração: apenas uma borda embaixo (o sublinhado)
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: linkColor, // Mesma cor do texto para consistência
                width: 1, // Espessura fina, semelhante a um link da web
              ),
            ),
          ),

          // O texto do link em si
          child: Text(
            label,
            style: TextStyle(
              color: linkColor, // Cor primária do tema, identifica que é clicável
              fontWeight:
                  FontWeight.bold, // Negrito para destacar que é interativo
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
