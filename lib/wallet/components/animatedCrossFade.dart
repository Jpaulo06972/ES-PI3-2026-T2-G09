// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote básico de UI do Flutter, contendo os widgets visuais e o sistema de renderização.
import 'package:flutter/material.dart';

/// Widget que exibe ou oculta os chips de filtro com uma animação suave de
/// cross-fade (transição entre dois widgets).
///
/// Pense nisso como um "efeito de fantasma": os filtros aparecem suavemente na tela
/// em vez de simplesmente "piscarem" do nada, o que dá uma experiência de uso muito mais polida.
///
/// Esse componente é usado na tela principal da carteira para expandir ou recolher os filtros
/// do extrato com visual elegante e feedback claro para o usuário.
class FilterCrossFade extends StatelessWidget {
  // Controla se os chips de filtro estão visíveis (true) ou ocultos (false).
  final bool showFilters;

  // Mapa de chave → label. É como um dicionário onde a chave é o valor interno usado pela lógica
  // (ex: 'deposito') e o valor é o texto que o usuário lê na tela ('Depósitos').
  final Map<String?, String> filterOptions;

  // Chave do filtro atualmente selecionado (null = "Todas as transações").
  // Guardamos a chave selecionada para saber qual "chip" deve ficar aceso.
  final String? selectedFilter;

  // Callback disparado quando o usuário toca em um chip de filtro.
  // Como este é um StatelessWidget (não guarda estado próprio), ele "grita" para o widget pai:
  // "Ei, alguém tocou neste filtro aqui!", passando a chave do filtro.
  final Function(String?) onFilterSelected;

  // Construtor do nosso widget. O "super.key" ajuda o Flutter a identificar este widget
  // na árvore de widgets, essencial para a performance e atualizações de UI.
  const FilterCrossFade({
    super.key,
    required this.showFilters,
    required this.filterOptions,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    // O AnimatedCrossFade é fantástico para transições entre dois estados visuais.
    // Ele faz o trabalho duro de animar a opacidade e o tamanho entre o firstChild e o secondChild.
    return AnimatedCrossFade(
      // Duração da animação: 250ms é o "sweet spot" (nem tão rápido que passe despercebido,
      // nem tão lento que deixe o usuário impaciente).
      duration: const Duration(milliseconds: 250),

      // Avalia a flag showFilters para decidir qual estado mostrar.
      crossFadeState: showFilters
          ? CrossFadeState
                .showFirst // Mostra os filtros
          : CrossFadeState.showSecond, // Esconde os filtros (fica invisível)
      // O firstChild é o nosso conteúdo real, os chips!
      firstChild: Padding(
        // Dá um respiro no topo para não ficar colado no elemento acima.
        padding: const EdgeInsets.only(top: 16),
        // O Wrap é como uma Row (linha), mas com um superpoder: se os itens não couberem
        // na largura da tela, ele "quebra a linha" automaticamente em vez de dar erro de overflow.
        child: Wrap(
          spacing: 8, // Espaço horizontal entre os chips (respiro lateral).
          runSpacing:
              8, // Espaço vertical quando os chips quebram linha (respiro vertical).
          // Mapeamos nossas opções de filtro para transformá-las em widgets na tela.
          children: filterOptions.entries.map((entry) {
            final key = entry.key; // A chave (ex: 'saque')
            final label = entry.value; // O texto visível (ex: 'Saques')

            // Verifica se o chip atual que estamos desenhando é o que está selecionado.
            final isSelected = selectedFilter == key;

            // Define a cor temática para cada tipo de transação.
            // O uso de cores ajuda o cérebro do usuário a associar rapidamente
            // o tipo de dado sem ter que ler o texto o tempo todo.
            Color chipColor;
            if (key == null) {
              chipColor = const Color(
                0xFF4A90E2,
              ); // Azul para "Todas" (Neutro/Geral)
            } else if (key == 'deposito') {
              chipColor = const Color(
                0xFF107649,
              ); // Verde para Depósito (Dinheiro entrando, positivo)
            } else if (key == 'saque') {
              chipColor = const Color(
                0xFFF5A623,
              ); // Laranja para Saque (Atenção, dinheiro saindo)
            } else if (key == 'transferencia') {
              chipColor = const Color(
                0xFF00B4D8,
              ); // Ciano para Transferência (Movimentação)
            } else {
              chipColor = const Color(
                0xFF9B59B6,
              ); // Roxo para Outros (Investimentos, etc)
            }

            // O GestureDetector envolve nosso botão para capturar os toques (taps) na tela.
            return GestureDetector(
              // Quando o usuário tocar, chamamos o callback passando a chave desse filtro.
              onTap: () => onFilterSelected(key),

              // AnimatedContainer faz a transição de cores suavemente.
              // Se o chip for selecionado, ele muda a cor de fundo e a borda gradualmente.
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),

                // O padding interno dá "corpo" ao botão, para que o texto não fique espremido.
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),

                // Decoração e estilo da "caixa" do nosso chip.
                decoration: BoxDecoration(
                  // Se selecionado, usamos a cor temática com 20% de opacidade (alpha 0.2)
                  // criando um fundo translúcido legal. Se não, usamos um cinza escuro.
                  color: isSelected
                      ? chipColor.withValues(alpha: 0.2)
                      : const Color(0xFF2C2C30),

                  // Borda arredondada suave.
                  borderRadius: BorderRadius.circular(14),

                  // Borda do chip
                  border: Border.all(
                    // A borda fica com a cor temática forte se selecionado,
                    // e branca muito fraquinha se inativo.
                    color: isSelected
                        ? chipColor
                        : Colors.white.withValues(alpha: 0.08),
                    width: 1.5,
                  ),
                ),
                // O conteúdo dentro do chip: uma linha com a bolinha de cor (se selecionado) e o texto.
                child: Row(
                  // mainAxisSize.min diz para a Row ocupar apenas o espaço de seus filhos,
                  // caso contrário ela tentaria esticar até o infinito.
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Um pequeno "bullet" colorido para dar ainda mais destaque visual
                    // de que ESTE é o filtro ativo.
                    if (isSelected) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: chipColor,
                          shape: BoxShape
                              .circle, // Transforma o quadrado num círculo perfeito
                        ),
                      ),
                      const SizedBox(
                        width: 6,
                      ), // Espacinho entre a bolinha e o texto
                    ],
                    // O texto do nosso chip.
                    Text(
                      label,
                      style: TextStyle(
                        // Se selecionado, o texto ganha a cor vibrante. Se não, um branco meio apagado.
                        color: isSelected ? chipColor : Colors.white60,
                        fontSize: 13,
                        // Dica de ouro: alterar a espessura da fonte (fontWeight) quando algo
                        // está selecionado ajuda na hierarquia visual!
                        fontWeight: isSelected
                            ? FontWeight
                                  .bold // Mais gordinho para destacar
                            : FontWeight.w500, // Peso médio para inativo
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      // O secondChild é o que o AnimatedCrossFade mostra quando showFilters for false.
      // SizedBox.shrink() é excelente porque é, literalmente, um widget de tamanho zero.
      // Ele não ocupa espaço e não afeta o layout vizinho.
      secondChild: const SizedBox.shrink(),
    );
  }
}
