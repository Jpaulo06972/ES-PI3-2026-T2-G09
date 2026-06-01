// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

import 'package:mesclainvest_f/components/currencyInputFormatter.dart';
import 'package:flutter/material.dart';
import 'package:mesclainvest_f/model/offerModel.dart';

/// Enum que define como o livro de ordens vai ser renderizado:
/// - both: mostra tanto compras quanto vendas (duas colunas)
/// - vendaOnly: mostra apenas as ordens de venda (uma coluna)
/// - compraOnly: mostra apenas as ordens de compra (uma coluna)
enum OrderBookSide { both, vendaOnly, compraOnly }

/// Tabela de livro de ordens estilo balcão de negociação.
/// Simula aqueles livros de ofertas que vemos em home brokers ou exchanges de crypto.
class OrderBookTable extends StatelessWidget {
  /// Lista de ofertas de venda ativas no mercado
  final List<OfferModel> vendaOrders;
  
  /// Lista de ofertas de compra ativas no mercado
  final List<OfferModel> compraOrders;
  
  /// Ação a ser executada quando o usuário toca numa oferta de VENDA (para ele comprar)
  final void Function(OfferModel)? onVendaTap;
  
  /// Diz ao componente qual modo de exibição usar (both, venda, compra)
  final OrderBookSide side;

  /// Quando true e side == vendaOnly, altera os rótulos do cabeçalho
  /// para não confundir o usuário.
  final bool showAsCompra;

  const OrderBookTable({
    super.key,
    required this.vendaOrders,
    required this.compraOrders,
    this.onVendaTap,
    this.side = OrderBookSide.both,
    this.showAsCompra = false,
  });

  // Cores padronizadas para Venda (vermelho) e Compra (verde). 
  // Na B3 e em crypto é sempre assim: Venda = vermelho, Compra = verde.
  static const _red = Color(0xFFE74C3C);
  static const _green = Color(0xFF1A9B5F);
  // Cor da divisória das colunas
  static const _divider = Color(0xFF3A3A3A);

  @override
  Widget build(BuildContext context) {
    return Container(
      // Estiliza a caixa inteira do livro de ordens
      decoration: BoxDecoration(
        color: const Color(0xFF262629),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // 1. Constrói o cabeçalho (títulos das colunas)
          _buildHeader(),
          
          // 2. Constrói as linhas usando o operador spread (...)
          // Utilizamos uma função anônima para calcular dinamicamente a quantidade de linhas
          ...() {
            // Descobre quantas linhas a tabela vai ter.
            // Se for 'both', pega a maior lista (pra não faltar linha de um lado).
            final count = side == OrderBookSide.vendaOnly
                ? vendaOrders.length
                : side == OrderBookSide.compraOnly
                ? compraOrders.length
                : [
                    vendaOrders.length,
                    compraOrders.length,
                  ].reduce((a, b) => a > b ? a : b);
                  
            // Se não tem oferta nenhuma, exibe uma mensagem amigável de vazio
            if (count == 0) {
              return [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Nenhuma ordem disponível',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ];
            }
            
            // Gera as linhas preenchendo os dados da Venda e Compra.
            return List.generate(
              count,
              (i) => _buildRow(
                // Se a lista acabou, passa null pra linha ficar vazia
                venda: side != OrderBookSide.compraOnly
                    ? (i < vendaOrders.length ? vendaOrders[i] : null)
                    : null,
                compra: side != OrderBookSide.vendaOnly
                    ? (i < compraOrders.length ? compraOrders[i] : null)
                    : null,
                // Passa isLast pra saber se precisa desenhar a linha de borda embaixo
                isLast: i == count - 1,
              ),
            );
          }(),
        ],
      ),
    );
  }

  /// Constrói a primeira linha do livro: Venda | Compra
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      // Bordinha embaixo do header pra separar do conteúdo
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: side == OrderBookSide.vendaOnly
          // Modo Venda: mostra só 1 título que varia dependendo de showAsCompra
          ? _buildSideHeader(
              showAsCompra ? 'Ordens de Compra' : 'Ordens de Venda',
              isVenda: !showAsCompra,
            )
          : side == OrderBookSide.compraOnly
          // Modo Compra
          ? _buildSideHeader('Ordens de Compra', isVenda: false)
          // Modo Both: mostra as duas colunas divididas
          : Row(
              children: [
                Expanded(child: _buildSideHeader('Venda', isVenda: true)),
                Container(width: 1, height: 20, color: _divider), // A divisória do meio
                Expanded(child: _buildSideHeader('Compra', isVenda: false)),
              ],
            ),
    );
  }

  /// Constrói o título de uma das colunas (ex: "Venda" com a setinha e as labels Qtd e Preço)
  Widget _buildSideHeader(String label, {required bool isVenda}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              // Ícone que indica venda (seta pra baixo) ou compra (seta pra cima)
              Icon(
                isVenda ? Icons.arrow_downward : Icons.arrow_upward,
                size: 11,
                color: isVenda ? _red : _green,
              ),
            ],
          ),
          // Etiquetas de Quantidade e Preço
          const Row(
            children: [
              _HeaderCell(text: 'Qtd'),
              SizedBox(width: 8),
              _HeaderCell(text: 'Preço'),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói a linha inteira, definindo se mostra 1 ou 2 células
  Widget _buildRow({
    required OfferModel? venda,
    required OfferModel? compra,
    required bool isLast,
  }) {
    // Se não for o último, desenha borda sutil embaixo
    final border = isLast
        ? null
        : BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
            ),
          );

    if (side == OrderBookSide.vendaOnly) {
      return Container(decoration: border, child: _buildVendaCell(venda));
    }
    if (side == OrderBookSide.compraOnly) {
      return Container(decoration: border, child: _buildCompraCell(compra));
    }
    
    // Modo Both: desenha venda na esquerda, linha vertical no meio, compra na direita.
    // IntrinsicHeight faz a linha vertical esticar perfeitamente.
    return Container(
      decoration: border,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _buildVendaCell(venda)),
            Container(width: 1, color: _divider),
            Expanded(child: _buildCompraCell(compra)),
          ],
        ),
      ),
    );
  }

  /// Célula de Venda (vermelha)
  Widget _buildVendaCell(OfferModel? offer) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      // Se não tem oferta nessa linha, mostra espaço vazio
      child: offer == null
          ? const SizedBox()
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Qtd do lado esquerdo
                Text(
                  '${offer.quantidade.toInt()}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                // Preço e nomezinho do vendedor na direita
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CurrencyInputFormatter.formatValue(
                            offer.precoPorToken,
                          ),
                          style: const TextStyle(
                            color: _red, // Preço vermelho (venda)
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // Se o widget pai passou uma ação de "toque", mostra um ícone de mãozinha
                        if (onVendaTap != null) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.touch_app, size: 12, color: _red),
                        ],
                      ],
                    ),
                    Text(
                      offer.vendedorNome,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );

    // Se o widget for clicável, envelopa com o InkWell pra dar efeito de clique
    if (offer == null || onVendaTap == null) return content;

    return InkWell(
      onTap: () => onVendaTap!(offer),
      borderRadius: BorderRadius.circular(4),
      child: content,
    );
  }

  /// Célula de Compra (Verde)
  Widget _buildCompraCell(OfferModel? offer) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      // Se não tem nada, renderiza vazio
      child: offer == null
          ? const SizedBox()
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Qtd na esquerda
                Text(
                  '${offer.quantidade.toInt()}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                // Preço na direita (verde)
                Text(
                  CurrencyInputFormatter.formatValue(offer.precoPorToken),
                  style: const TextStyle(
                    color: _green, // Verde (compra)
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Etiqueta simples que vai lá no cabeçalho ("Qtd", "Preço")
class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
