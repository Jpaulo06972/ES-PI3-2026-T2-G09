// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';
import 'package:mesclainvest_f/counter/components/balcao_quantity_stepper.dart';

/// Aqui fica a parte de cima do nosso formulário de compra do Balcão.
/// Ele junta o controle de "Quantos tokens você quer?" com o "Aviso de preço".
///
/// Detalhe de negócio: no Balcão, o usuário não escolhe quanto quer pagar.
/// É o famoso preço a mercado ("Take it or leave it").
/// Por isso, o campo de preço é só pra leitura (read-only), a gente desenhou ele pra
/// parecer um campo, mas ele não tem um teclado por trás.
///
/// Esse componente é "burro" (StatelessWidget), o que é ótimo.
/// Ele só recebe a quantidade atual e as funções de clicar nos botões,
/// e o "pai" dele que se vira pra calcular os limites de mínimo e máximo.
class BalcaoBuyForm extends StatelessWidget {
  // Quantos tokens o cara quer comprar no momento.
  final int qty;

  // Quanto tá custando a cota agora lá no mercado secundário.
  final double currentMarketPrice;

  // Função que o botão de menos (-) vai chamar.
  final VoidCallback onDecrement;

  // Função que o botão de mais (+) vai chamar.
  final VoidCallback onIncrement;

  const BalcaoBuyForm({
    super.key,
    required this.qty,
    required this.currentMarketPrice,
    required this.onDecrement,
    required this.onIncrement,
  });

  /// Função ajudante (helper) pra criar aqueles textinhos em cima dos campos.
  /// Isso evita copiar e colar o mesmo TextStyle 50 vezes no projeto. DRY na veia!
  Widget _fieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(
      bottom: 6,
    ), // Desgruda o label do campo embaixo dele.
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      // Alinha tudo pra esquerda (start), senão os labels ficam centralizados e fica estranho.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- SEÇÃO 1: A QUANTIDADE ---
        _fieldLabel('Quantidade de tokens'),

        // Chamamos o componente "irmão" dele que só desenha os botões de - e +.
        BalcaoQuantityStepper(
          qty: qty,
          onDecrement: onDecrement,
          onIncrement: onIncrement,
        ),

        const SizedBox(height: 14),

        // --- SEÇÃO 2: O PREÇO DE MERCADO ---
        // Aquele aviso amigável pro usuário não achar que o app tá quebrado por não deixar ele editar o preço.
        _fieldLabel('Preço por token (fixado pelo mercado)'),

        // Aqui a gente cria um "Falso Input".
        // Ele tem a cara de um campo de texto (Container com borda arredondada e cor de fundo),
        // mas na verdade é só um Row com dois textos dentro. Hackzinho de design de UI!
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 52, // Mesma altura dos botões do Stepper pra ficar harmônico.
          decoration: BoxDecoration(
            color: const Color(
              0xFF141416,
            ), // Fundo ainda mais escuro pra dar profundidade.
            borderRadius: BorderRadius.circular(12),
            // Aquela bordinha fantasma que a gente usa no app inteiro (4% de opacidade).
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Joga um texto pra cada canto.
            children: [
              const Text(
                'Preço de mercado',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ), // Letra apagadinha pro label.
              ),

              // Valor formatado bonitinho em Reais (R$).
              // Usamos o nosso formatador central pra garantir que o padrão numérico seja o mesmo do app todo.
              Text(
                CurrencyInputFormatter.formatValue(currentMarketPrice),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
