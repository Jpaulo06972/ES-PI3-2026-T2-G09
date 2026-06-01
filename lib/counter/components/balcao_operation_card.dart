// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/model/operationModel.dart';
import 'package:mesclainvest_f/startups/components/startup_colors.dart';

/// Cardzinho que mostra o extrato de uma operação que o usuário fez no Balcão.
/// Ele fica lá na aba "Minhas Ordens".
///
/// Como no mercado financeiro "Comprar" = Verde e "Vender" = Vermelho,
/// a gente coloca um pontinho verde bem chamativo pra sinalizar que foi uma Compra.
/// Por enquanto a gente só tem compra no nosso app, mas o design já tá pronto
/// pra quando a gente botar o botão de vender! ;)
class BalcaoOperationCard extends StatelessWidget {
  // A "operação" inteira. O pai buscou lá do Firestore e passou mastigado pra cá.
  // Dentro desse objeto tem quantidade, preço, total, hora da compra, etc.
  final OperationModel op;

  // Nossa velha amiga função de formatar em Reais (R$).
  // De novo, recebemos por injeção pra não ter que importar o pacote `intl` aqui.
  final String Function(double) fmtBRL;

  const BalcaoOperationCard({
    super.key,
    required this.op,
    required this.fmtBRL,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // margin embaixo (bottom: 10) pra um card não ficar colado no de baixo
      // quando eles aparecerem na lista rolável (ListView).
      margin: const EdgeInsets.only(bottom: 10),

      // padding (all: 12) pra dar aquele respiro interno e não deixar o texto bater na borda.
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: const Color(
          0xFF141416,
        ), // Aquele pretão fundo que a gente gosta.
        borderRadius: BorderRadius.circular(12),
        // E lá vem a bordinha transparente. Isso salva o design de ficar flat demais.
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),

      child: Row(
        children: [
          // Expanded joga a coluna pra ocupar todo o espaço lateral possível.
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Tudo alinhadinho na esquerda.
              children: [
                // --- CABEÇALHO DO CARD (Badge de "COMPRA") ---
                Row(
                  children: [
                    // Aquela bolinha verde bonitinha.
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: StartupColors.green,
                        shape: BoxShape
                            .circle, // O Flutter já faz o trabalho de deixar redondo.
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Texto em caixa alta (COMPRA) com a mesma cor da bolinha.
                    const Text(
                      'COMPRA',
                      style: TextStyle(
                        color: StartupColors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // --- DETALHES DA OPERAÇÃO ---
                // Esse é o jeito chique de mostrar no mercado financeiro: "X tokens @ R$ Y".
                // O '@' significa 'at' (no preço de).
                Text(
                  '${op.quantity} tokens @ ${fmtBRL(op.pricePerToken)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 4),

                // --- TOTAL PAGO ---
                // O bolso é a parte que mais dói, então o total recebe um bold maroto.
                Text(
                  'Total: ${fmtBRL(op.total)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
