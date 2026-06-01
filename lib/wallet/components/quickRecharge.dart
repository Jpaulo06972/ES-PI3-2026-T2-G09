// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/startups/components/startup_colors.dart';

/// Seção de recarga rápida (Depósito).
///
/// Em vez de forçar o usuário a sempre digitar um valor (o que exige abrir
/// o teclado do celular, que é demorado e chato), damos a ele "chips" com valores
/// rápidos (R$ 50, R$ 100, etc). Isso acelera a jornada do usuário e incentiva
/// recargas nos valores que a gente quer.
///
/// IMPORTANTE: Este componente é "burro" (dumb widget). Ele não sabe fazer depósito
/// no banco de dados. Ele só desenha a tela e chama os callbacks (funções) que
/// o widget pai passou pra ele.
class QuickRecharge extends StatelessWidget {
  // O valor que está pintado de verdinho no momento.
  final double? selectedValue;

  // Controler do textfield. Funciona como um "caderno" onde o TextField anota
  // tudo que o usuário digita no campo "Outro valor".
  final TextEditingController customValueController;

  // Avisa o pai: "O usuário tocou no chip X!"
  final ValueChanged<double?> onValueSelected;

  // Avisa o pai: "O usuário está digitando no teclado!"
  final ValueChanged<String> onCustomValueChanged;

  // Avisa o pai: "O usuário clicou no botão verde grande para confirmar!"
  final VoidCallback onConfirm;

  // Valores predefinidos que o usuário pode escolher com 1 clique.
  static const List<double> _quickValues = [50, 100, 200, 500, 1000];

  const QuickRecharge({
    super.key,
    required this.selectedValue,
    required this.customValueController,
    required this.onValueSelected,
    required this.onCustomValueChanged,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start, // Alinha os textos na esquerda
      children: [
        // Títulozinho da seção
        const Text(
          "RECARGA RÁPIDA",
          style: TextStyle(
            color: Color(0xFF107649),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing:
                1.5, // Afasta um pouco as letras para dar um ar moderno
          ),
        ),
        const SizedBox(height: 4),
        // Subtítulo pra não deixar o usuário perdido
        const Text(
          "Selecione um valor ou insira manualmente",
          style: TextStyle(fontSize: 13, color: Colors.white38),
        ),
        const SizedBox(height: 16),

        // SizedBox fixando a altura em 44. Isso é necessário porque a ListView
        // horizontal precisa saber qual é o seu tamanho vertical, senão ela "estoura" a tela.
        SizedBox(
          height: 44,
          child: ListView.separated(
            // Direção do scroll: da esquerda pra direita!
            scrollDirection: Axis.horizontal,
            itemCount: _quickValues.length,
            // O separatorBuilder cria aquele espacinho de 10 pixels entre os botões.
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final value = _quickValues[index];
              // Checamos se este chip específico é o que está selecionado no momento.
              final isSelected = selectedValue == value;

              return GestureDetector(
                onTap: () {
                  // Lógica de "toggle": se o cara clica num chip já selecionado,
                  // a gente desmarca ele (passa null pro pai). Se não, seleciona.
                  onValueSelected(isSelected ? null : value);
                },
                child: AnimatedContainer(
                  // Essa animação faz o fundo verde aparecer suaaaavemente em 200ms.
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    // Se tiver selecionado, fundo verde com 20% de opacidade.
                    // Se não, usa a cor de card padrão.
                    color: isSelected
                        ? const Color(0xFF107649).withValues(alpha: 0.2)
                        : StartupColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF107649)
                          : Colors.white.withValues(alpha: 0.08),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bolinha verdinha bonitinha que só aparece quando tá selecionado.
                      if (isSelected) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF107649),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      // Texto do valor. Usamos .toInt() para tirar o ".0" (ex: "R$ 50" e não "R$ 50.0")
                      Text(
                        "R\$ ${value.toInt()}",
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF107649)
                              : Colors.white60,
                          // Se selecionado = Negrito!
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Caixa de texto para digitar valor manual (para quem é "do contra" rs).
        Container(
          decoration: BoxDecoration(
            color: StartupColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: TextField(
            controller: customValueController,
            // Isso aqui é vital: abre o teclado numérico do celular,
            // economizando o tempo do usuário de ter que trocar do teclado de letras pro de números.
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            // Cada vez que o usuário digita uma tecla, disparamos a função.
            // O pai usa isso pra desmarcar os chips lá de cima (se o cara tá digitando, os chips devem apagar).
            onChanged: onCustomValueChanged,
            decoration: const InputDecoration(
              hintText: "Outro valor (R\$)",
              hintStyle: TextStyle(color: Colors.white30),
              prefixIcon: Icon(
                Icons.attach_money_rounded,
                color: Colors.white30,
              ),
              border: InputBorder
                  .none, // Tira aquela linha tosca que o TextField tem por padrão
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Botão grandão de confirmar!
        SizedBox(
          width: double.infinity, // Ocupa toda a largura da tela
          height:
              52, // Altura padrão bem confortável pro dedão (touch target seguro)
          child: ElevatedButton.icon(
            onPressed: onConfirm, // Aciona a lógica pesada de recarga lá no pai
            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
            label: const Text(
              "Confirmar Depósito",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF107649),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0, // Tiramos a sombra pro visual ficar mais "flat"
            ),
          ),
        ),
      ],
    );
  }
}
