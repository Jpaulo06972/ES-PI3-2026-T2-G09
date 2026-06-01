// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

import 'package:flutter/material.dart';

/// O título da seção de extrato, com a contagem de transações e botão de filtro.
///
/// Esse componente fica logo acima da lista de transações e serve pra mostrar ao
/// usuário o "status" atual da lista: quantas transações ele está vendo e se
/// os filtros estão abertos ou não.
class StatementHeader extends StatelessWidget {
  // O número que aparece no badgezinho verde (ex: "15").
  // Importante: esse número atualiza quando o filtro muda! Se filtrar por "Saque"
  // e tiverem 2 saques, ele vai mostrar "2", não o total de transações.
  final int count;

  // Diz se o painel de filtros (os chips) está aberto/visível.
  final bool showFilters;

  // Diz se o usuário tem algum filtro selecionado (que não seja "Todos").
  // Se tiver, a gente acende o botão do funil pra avisar: "Ei, a lista tá filtrada!"
  final bool hasActiveFilter;

  // A função que é disparada quando o usuário clica no funil.
  final VoidCallback onToggleFilters;

  const StatementHeader({
    super.key,
    required this.count,
    required this.showFilters,
    required this.hasActiveFilter,
    required this.onToggleFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      // Empurra os filhos pros dois cantos extremos da Row
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ── LADO ESQUERDO: Texto + Badge ──
        Row(
          children: [
            const Text(
              'Extrato',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            // Badge bonitinho mostrando a contagem.
            // Badges são essenciais pra dar noção de quantidade pro usuário
            // antes mesmo dele rolar a lista.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                // Fundo verde translúcido
                color: const Color(0xFF107649).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count', // Interpolação de string! Super rápido e limpo no Dart.
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        // ── LADO DIREITO: Botão de Funil (Filtro) ──
        GestureDetector(
          onTap: onToggleFilters,
          child: Container(
            padding: const EdgeInsets.all(
              8,
            ), // Um padding gordinho pra facilitar o toque do dedo
            decoration: BoxDecoration(
              // Lógica de cor:
              // Se os chips estiverem aparecendo (showFilters) OU se tiver algum
              // filtro selecionado (hasActiveFilter), pintamos o botão de VERDE.
              // Assim, mesmo se o cara esconder os chips, o funil verde lembra ele
              // de que a lista está filtrada.
              color: showFilters || hasActiveFilter
                  ? const Color(0xFF107649)
                  : const Color(0xFF3A3A3D), // Cinza neutro
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons
                  .tune_rounded, // Ícone de ajuste/funil super padrão e reconhecível
              color: showFilters || hasActiveFilter
                  ? Colors.white
                  : Colors.white70,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}
