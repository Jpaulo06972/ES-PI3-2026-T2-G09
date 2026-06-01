// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

// Toggle de abas animado para o Balcão.
// Funciona como uma barra de navegação horizontal onde cada opção é um segmento.
// O segmento ativo tem fundo verde e os inativos ficam transparentes.
// A animação suave (AnimatedContainer) dá um toque profissional e indica
// claramente qual aba está selecionada sem precisar de ícones adicionais.

import 'package:flutter/material.dart';

/// Componente que renderiza um menu em formato de pílulas.
/// É basicamente uma barra com botões que alternam o estado da tela (ex: Livro, Minhas Ordens).
class CounterToggle extends StatelessWidget {
  /// Índice da aba atualmente selecionada.
  /// Começa sempre em 0 (primeiro item). O pai que controla isso.
  final int selectedIndex;

  /// Callback chamado ao tocar em uma aba.
  /// Informa ao pai qual foi o novo índice selecionado.
  final ValueChanged<int> onChanged;

  /// Lista com o texto das abas (ex.: ['Comprar', 'Vender', 'Minhas Ordens']).
  final List<String> tabs;

  /// Construtor requer todos os parâmetros para funcionar certinho.
  const CounterToggle({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    // O Container principal atua como o fundo escuro que engloba todas as abas.
    return Container(
      // Um pequeno padding para os botões não colarem nas bordas desse fundo.
      // Funciona como a "margem" das pílulas.
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF262629), // Cor de fundo da barra do toggle
        borderRadius: BorderRadius.circular(12), // Bordas globais arredondadas
      ),
      // Usamos uma Row para colocar os botões lado a lado
      child: Row(
        // List.generate cria a lista de widgets baseada na quantidade de tabs.
        // Ele vai rodar o index de 0 até o tamanho da lista - 1.
        children: List.generate(tabs.length, (i) {
          // Checa se o botão que estamos construindo agora (i) é o selecionado.
          final isActive = i == selectedIndex;
          
          return Expanded(
            // O Expanded aqui é o pulo do gato!
            // Ele faz com que todos os botões (abas) dividam o espaço igualmente.
            // Se tivermos 3 abas, cada uma ocupa exatamente 1/3 do tamanho da Row.
            child: GestureDetector(
              // Quando o usuário toca nessa aba, avisamos o pai passando o índice (i).
              onTap: () => onChanged(i),
              // O AnimatedContainer cuida de animar mudanças de estilo automaticamente.
              // Como a cor ou o padding mudam quando ativo/inativo, ele faz o "fade" sozinho.
              child: AnimatedContainer(
                // A duração do fade, 200ms é rápido o suficiente pra parecer imediato 
                // mas suave o suficiente para ser bonito.
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  // A mágica acontece aqui: se ativo, pinta de verde.
                  // Se inativo, deixa transparente (então mostra o fundo escuro do pai).
                  color: isActive
                      ? const Color(0xFF107649)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8), // Pílula arredondada
                ),
                child: Text(
                  // Pega o nome da aba da lista na posição 'i'.
                  tabs[i],
                  // Centraliza o texto no botão.
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    // Se ativo, texto fica branco branquíssimo. 
                    // Se não, fica um branco mais apagado (54% de opacidade).
                    color: isActive ? Colors.white : Colors.white54,
                    fontSize: 13,
                    // Se ativo a fonte ganha um peso maior (semi-bold).
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
