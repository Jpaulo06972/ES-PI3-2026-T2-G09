// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

// Componente stepper (incrementador/decrementador) de quantidade para o Balcão.
// Permite ao investidor escolher quantos tokens quer comprar usando botões + e -,
// sem precisar digitar — reduz erros de entrada e melhora a experiência em mobile.
// A quantidade exibida é controlada externamente (StatelessWidget puro),
// e as ações de incremento/decremento são delegadas ao widget pai.

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/startups/components/startup_colors.dart';

/// Stepper de quantidade para o mercado de balcão.
class BalcaoQuantityStepper extends StatelessWidget {
  /// Quantidade atual a ser exibida no centro do stepper.
  /// Recebida do widget pai, que é quem realmente guarda esse estado.
  final int qty;

  /// Callback disparado ao clicar no botão de menos (-).
  /// O pai decide o limite mínimo (ex.: 1) e atualiza o estado.
  final VoidCallback onDecrement;

  /// Callback disparado ao clicar no botão de mais (+).
  /// O pai decide o limite máximo (ex.: saldo disponível) e atualiza o estado.
  final VoidCallback onIncrement;

  /// Construtor requer todos os parâmetros, pois um stepper sem controle ou
  /// sem quantidade visível não tem função.
  const BalcaoQuantityStepper({
    super.key,
    required this.qty,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    // Um Container para encapsular visualmente todo o controle.
    return Container(
      // Padding lateral para afastar o conteúdo das bordas.
      padding: const EdgeInsets.symmetric(horizontal: 14),
      // Altura fixa garante alinhamento consistente com outros campos.
      height: 52,
      // Estiliza o fundo e bordas.
      decoration: BoxDecoration(
        color: const Color(0xFF141416), // Fundo escuro, quase preto
        // Bordas arredondadas para manter a linguagem visual moderna.
        borderRadius: BorderRadius.circular(12),
        // Borda levemente destacada para indicar que é uma área interativa,
        // semelhante a um campo de formulário.
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      // Usamos uma Row para separar o label de quantidade dos controles.
      child: Row(
        // Distribui o espaço: "Qtd N" colado à esquerda, botões à direita.
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sub-Row para a área de exibição do texto e quantidade atual.
          Row(
            children: [
              // Rótulo estático
              const Text(
                'Qtd ',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              // O valor dinâmico da quantidade vem aqui.
              // Usamos negrito e um tamanho levemente maior para dar foco
              // no número, que é a informação mais importante aqui.
              Text(
                qty.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Sub-Row para os botões de controle de incremento/decremento.
          Row(
            children: [
              // Botão de Menos (-)
              IconButton(
                // O ícone usa a cor de destaque do app (verde).
                icon: const Icon(
                  Icons.remove,
                  color: StartupColors.green,
                  size: 20, // Tamanho sutil para caber bem na altura fixa
                ),
                // Aciona a callback repassada pelo pai.
                // Não há lógica de "não reduzir se for menor que 1" aqui,
                // porque esse componente é burro (no bom sentido).
                onPressed: onDecrement,
              ),
              // Espacinho entre os botões para evitar toques acidentais.
              const SizedBox(width: 4),
              // Botão de Mais (+)
              IconButton(
                // O ícone também usa o verde característico.
                icon: const Icon(
                  Icons.add,
                  color: StartupColors.green,
                  size: 20,
                ),
                // Aciona o callback do pai.
                onPressed: onIncrement,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
