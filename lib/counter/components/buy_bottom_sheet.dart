// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

// Bottom sheet de confirmação de compra de uma oferta do mercado secundário.
// É exibido como modal deslizando da parte inferior da tela quando o usuário
// toca em uma oferta de venda no livro de ordens (OrderBook).
// O fluxo é: escolher quantidade -> ver resumo -> confirmar -> feedback visual.

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';
import 'package:mesclainvest_f/counter/components/stepper_button.dart';
import 'package:mesclainvest_f/counter/components/summary_row.dart';
import 'package:mesclainvest_f/counter/services/counterService.dart';
import 'package:mesclainvest_f/model/offerModel.dart';
import 'package:mesclainvest_f/model/userModel.dart';

/// Abre o bottom sheet de compra de tokens a partir de uma oferta de usuário.
/// 
/// O bottom sheet é como uma gaveta que sobe, muito comum em mobile para não 
/// tirar o usuário do contexto atual da tela (ele ainda vê a tela lá atrás).
///
/// Parâmetros:
/// - [context]   -> Contexto atual para exibir o Modal.
/// - [offer]     -> Oferta selecionada pelo investidor.
/// - [user]      -> Usuário logado (precisamos verificar o saldo e atualizar os dados).
/// - [service]   -> Serviço do Balcão para executar a transação de fato no Firebase.
/// - [onSuccess] -> Callback chamado após a compra dar certo, para o pai atualizar a tela.
void showBuySheet(
  BuildContext context,
  OfferModel offer,
  UserModel user,
  CounterService service,
  VoidCallback onSuccess,
) {
  // Começamos a quantidade selecionada em 1 token.
  // É o mínimo que alguém pode comprar.
  double qty = 1;

  // showModalBottomSheet constrói a "gaveta" na tela.
  showModalBottomSheet(
    context: context,
    // isScrollControlled: true permite que a gaveta empurre o conteúdo se o teclado subir
    // ou se o conteúdo for muito alto.
    isScrollControlled: true,
    // O fundo do sheet em si é transparente para podermos desenhar 
    // os cantos arredondados no nosso próprio Container interno.
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      // StatefulBuilder é um truque para termos estado local dentro de um 
      // StatelessWidget ou função. Assim podemos atualizar a [qty] sem recriar
      // a tela inteira por trás.
      builder: (ctx, setSheet) {
        // Multiplicamos a quantidade pelo preço unitário para saber o valor a ser pago.
        final total = qty * offer.precoPorToken;
        
        // Verificamos se o saldo atual aguenta o tranco dessa compra.
        final hasSaldo = user.saldo >= total;
        
        // O limite de compra é o que sobrou na oferta.
        final maxQty = offer.quantidade;

        // Padding dinâmico: o bottomInsets reage ao teclado. 
        // Se o teclado abrir, o sheet sobe junto, não escondendo os botões.
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          // Nosso Container principal desenha a cor de fundo e as bordas.
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: const BoxDecoration(
              color: Color(0xFF262629), // Um cinza escuro sofisticado
              // A borda arredondada fica apenas no topo (o clássico visual de gaveta)
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              // mainAxisSize.min diz pro modal: "ocupe apenas o espaço dos seus filhos"
              // e não a tela inteira.
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Essa é aquela pequena barra (handle) no topo da gaveta.
                // Serve como dica visual de que é possível arrastar para fechar.
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24, // Bem sutil
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Linha de Cabeçalho: Título + Nome da Startup de um lado,
                // e o Preço da oferta do outro.
                Row(
                  // Empurra um grupo pra esquerda e outro pra direita
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Grupo da esquerda (Títulos)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Comprar Tokens',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        // Nome da startup como subtítulo em cinza
                        Text(
                          offer.startupNome,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    // Grupo da direita (Preço)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          // Formata o double pra R$ bonitinho
                          CurrencyInputFormatter.formatValue(offer.precoPorToken),
                          style: const TextStyle(
                            color: Color(0xFF1A9B5F), // Verde que remete a dinheiro
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          '/token',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 6),
                
                // Texto de dica mostrando quantos tokens ainda tem na oferta
                Text(
                  'Disponível: ${offer.quantidade.toInt()} tokens',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),

                const SizedBox(height: 20),

                // Seção de controle da Quantidade
                const Text(
                  'Quantidade',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Caixa do Stepper (onde controlamos + e -)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1E), // Fundo mais escuro para destaque
                    borderRadius: BorderRadius.circular(12),
                    // Uma bordinha verde pra dar charme
                    border: Border.all(
                      color: const Color(0xFF107649).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Botão de diminuir
                      StepperButton(
                        icon: Icons.remove,
                        onTap: () {
                          // setSheet avisa o StatefulBuilder pra redesenhar
                          // Impedimos de baixar de 1
                          if (qty > 1) setSheet(() => qty--);
                        },
                      ),
                      // O valor atual da quantidade fica no meio, expandido
                      Expanded(
                        child: Text(
                          qty.toInt().toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      // Botão de aumentar
                      StepperButton(
                        icon: Icons.add,
                        onTap: () {
                          // Impedimos de passar do limite disponível na oferta
                          if (qty < maxQty) setSheet(() => qty++);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Cartão de Resumo Financeiro
                // Mostra ao usuário o estrago que ele fará na carteira
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Linha de Total
                      SummaryRow(
                        label: 'Total',
                        value: CurrencyInputFormatter.formatValue(total),
                        highlight: true, // Destaque na cor para o total
                      ),
                      const SizedBox(height: 8),
                      // Linha de Saldo para comparar com o Total
                      SummaryRow(
                        label: 'Saldo disponível',
                        value: CurrencyInputFormatter.formatValue(user.saldo),
                      ),
                    ],
                  ),
                ),

                // Mostramos o aviso SE não houver saldo suficiente.
                // O operador de spread (...) embute esses widgets direto na Column.
                if (!hasSaldo) ...[
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFE74C3C), // Vermelho de alerta
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Saldo insuficiente para esta compra',
                        style: TextStyle(
                          color: Color(0xFFE74C3C),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                // Botão principal de confirmar a compra
                SizedBox(
                  width: double.infinity, // Ocupa toda a largura possível
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      // Se tem saldo, botão fica verde bonito.
                      // Se não tem saldo, botão fica num cinza morto pra indicar que não dá.
                      backgroundColor: hasSaldo
                          ? const Color(0xFF107649)
                          : Colors.white12,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      elevation: 0,
                    ),
                    // O onPressed é nulo se não tem saldo (o Flutter desabilita o botão automaticamente).
                    onPressed: hasSaldo
                        ? () async {
                            // O usuário quer comprar. Primeiro fechamos a gaveta
                            // para ele não ficar clicando mais de uma vez.
                            Navigator.pop(ctx);
                            
                            // Chama o serviço do balcão pra realizar a magia do backend
                            final result = await service.buyFromOffer(
                              offer,
                              qty,
                            );
                            
                            // Dica de ouro: depois de um await, SEMPRE confira 
                            // se a tela (context) ainda existe antes de tentar alterá-la!
                            if (!context.mounted) return;
                            
                            if (result['success'] == true) {
                              // Sucesso! Atualiza o saldo em memória
                              user.saldo = result['updatedBalance'];
                              // Avisa o pai que deu bom (ele vai recarregar as ofertas)
                              onSuccess();
                              // Mostra aquela notificação flutuante avisando da alegria
                              _showSnackBar(
                                context,
                                'Compra de ${qty.toInt()} tokens de ${offer.startupNome} realizada!',
                              );
                            } else {
                              // Deu ruim! Pode ser erro no firebase, falta de internet, etc.
                              _showSnackBar(
                                context,
                                result['error'] ?? 'Erro ao processar compra.',
                                isError: true,
                              );
                            }
                          }
                        : null,
                    child: Text(
                      'Confirmar Compra',
                      style: TextStyle(
                        // O texto também reflete o estado: branco vívido ou cinza opaco
                        color: hasSaldo ? Colors.white : Colors.white38,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Helper para exibir uma SnackBar (aquela notificação que flutua embaixo)
/// - [context] Onde desenhar
/// - [message] A mensagem que o usuário vai ler
/// - [isError] Se for true, muda a cor pra vermelho, se false (padrão) fica verde.
void _showSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      // Cor condicional: vermelho de socorro ou verde de sucesso
      backgroundColor: isError
          ? const Color(0xFFE74C3C)
          : const Color(0xFF107649),
      // O estilo 'floating' deixa ela meio descolada das bordas, mais elegante.
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // Dura só 3 segundinhos na tela
      duration: const Duration(seconds: 3),
    ),
  );
}
