// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/startups/components/startup_colors.dart';

/// Essa é a barra inferior com o botão de "Comprar" do nosso Balcão de Negociação.
///
/// Lembra de quando a gente compra algo e a tela congela enquanto o servidor processa?
/// Aqui a gente cuida disso com estilo: enquanto [isProcessing] for true,
/// a gente desabilita o botão e gira um spinner dentro dele.
/// Isso é muito importante! Se a gente não fizer isso, um usuário ansioso pode
/// clicar no botão 3 vezes e acabar comprando as ações em triplicidade (e a conta dele vai chorar).
///
/// Usamos um StatelessWidget porque a lógica pesada (chamar API, abater saldo)
/// fica lá na tela principal (o "pai"). Aqui a gente só desenha a interface (o "filho").
class BalcaoActionBar extends StatelessWidget {
  // Flag que diz: "Ei, estamos processando a compra lá no backend, desliga o botão aí!".
  final bool isProcessing;

  // Quantos tokens o usuário escolheu comprar no slider.
  final int qty;

  // Valor total (quantidade * preço atual da cota).
  final double totalEstimated;

  // A gente injeta a função que formata pra R$ aqui.
  // Por que? Pra esse componente não precisar importar o package 'intl' à toa.
  // Deixamos a formatação centralizada onde faz sentido e só passamos a função pronta pra cá.
  final String Function(double) fmtBRL;

  // O que acontece quando o cara finalmente clica em "Comprar".
  // Se você passar null pra uma propriedade onPressed, o Flutter automaticamente
  // deixa o botão "cinzinha" (desabilitado). Mágico, né?
  final VoidCallback? onConfirm;

  const BalcaoActionBar({
    super.key,
    required this.isProcessing,
    required this.qty,
    required this.totalEstimated,
    required this.fmtBRL,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Esse padding desgruda o botão das bordas do celular.
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: StartupColors.cardBg, // Fundo escuro igual o resto da tela.
        border: Border(
          // Aquela linhazinha quase transparente (4% de opacidade) em cima da barra
          // pra dar uma separação visual elegante do resto do formulário.
          top: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
        ),
      ),
      child: SizedBox(
        // double.infinity faz o botão espreguiçar e ocupar a largura inteira disponível.
        width: double.infinity,
        height: 50, // Uma altura confortável pro dedo gordo não errar o clique.
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                StartupColors.green, // Nosso verde do "dinheiro entrando".
            foregroundColor: Colors.white, // A cor do texto dentro do botão.
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                14,
              ), // Botão arredondado tá na moda.
            ),
            elevation:
                0, // Tiramos a sombra pra seguir o design "Flat" (plano) do app.
          ),

          // Se estiver processando, joga 'null' aqui pra matar o botão na hora.
          onPressed: isProcessing ? null : onConfirm,

          // O que vai desenhar dentro do botão:
          child: isProcessing
              // 1. Se estiver comprando -> Roda a bolinha de carregamento.
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth:
                        2, // Uma linha mais fina pro spinner ficar mais delicado.
                  ),
                )
              // 2. Se estiver de boa -> Mostra o texto da compra.
              : Text(
                  // Aquele ternário ali no 'token' é pra cuidar do plural.
                  // Fica feio escrever "1 tokens" ou "2 token(s)". O detalhe faz a diferença!
                  'Comprar $qty token${qty != 1 ? 's' : ''} · ${fmtBRL(totalEstimated)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
