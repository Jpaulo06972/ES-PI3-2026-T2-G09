// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

import 'package:flutter/material.dart';

/// Aqueles "botõezinhos" horizontais (Chips) que usamos para filtrar o extrato.
///
/// Diferença em relação ao FilterCrossFade (da tela principal):
/// Na tela principal, a gente esconde os filtros porque a tela já é cheia de coisa.
/// Mas aqui, na página dedicada de "Extrato" (StatementPage), os filtros são
/// muito importantes! Por isso eles ficam sempre visíveis no topo, numa lista
/// com scroll horizontal que o usuário pode arrastar com o dedo.
class StatementFilterChips extends StatelessWidget {
  // Mapa com nossas opções, onde a chave é o ID e o valor é o texto bonitinho.
  // Ex: {'deposito': 'Entradas', 'saque': 'Saídas'}
  final Map<String?, String> filterOptions;

  // Qual filtro está ativo nesse exato momento? (Se for null, é o "Tudo")
  final String? selectedFilter;

  // Função que vamos gritar pro componente pai (a tela) quando o usuário clicar
  // em algum chip. "Ei, o cara quer ver só as Entradas!"
  final ValueChanged<String?> onFilterSelected;

  // Nossa cor verde guardada na constante pra manter tudo padronizado.
  static const Color primaryGreen = Color(0xFF107649);

  const StatementFilterChips({
    super.key,
    required this.filterOptions,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Usamos um SizedBox com altura fixa (36). Por que?
    // Porque o ListView "infinito" precisa saber seu limite de altura quando
    // o scrollDirection é Axis.horizontal. Sem isso, o Flutter daria um erro
    // clássico de restrição ("unbounded height").
    return SizedBox(
      height: 36,
      child: ListView.separated(
        // Rola de ladinho, tipo Stories do Instagram.
        scrollDirection: Axis.horizontal,
        // Bota um respiro de 20px no começo e no fim da lista pro primeiro chip
        // não ficar grudado no beiço da tela.
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filterOptions.length,
        // O separatorBuilder desenha esse espacinho em branco ENTRE os chips.
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        // Aqui a gente constrói o chip em si, um por um.
        itemBuilder: (context, index) {
          // Pegamos a chave e o valor do map através do índice.
          final key = filterOptions.keys.elementAt(index);
          final label = filterOptions.values.elementAt(index);
          // É o chip que tá selecionado? Comparamos com a variável que veio do pai.
          final isActive = selectedFilter == key;

          // Capturamos o clique.
          return GestureDetector(
            onTap: () => onFilterSelected(key), // Chama a função láááá no pai
            // AnimatedContainer é maravilhoso: ao invés de pular bruscamente
            // de cinza pra verde quando o usuário clica, ele transita suave (200ms).
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical:
                    7, // Padding pequenininho vertical porque a altura já é 36.
              ),
              decoration: BoxDecoration(
                // O estado dita a cor:
                // Ativo = Verdao chapado (destaque maximo)
                // Inativo = Branco super transparente (fica um cinza bonitinho e moderno)
                color: isActive
                    ? primaryGreen
                    : Colors.white.withValues(alpha: 0.06),
                // Pill shape: raio bem grande pra ficar redondão nas bordas
                borderRadius: BorderRadius.circular(20),
                // A borda segue a mesma lógica do fundo pra dar um acabamento fino
                border: Border.all(
                  color: isActive
                      ? primaryGreen
                      : Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  // Contraste é rei: se o fundo for verde (isActive), o texto TEM que ser branco vivo.
                  // Se o fundo for cinza, o texto pode ser um branco um pouco opaco (0.6).
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  // Hierarquia visual: chip ativo ganha fonte bold. Inativo ganha regular.
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
