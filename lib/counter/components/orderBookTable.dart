// Grupo: G09
// Trabalho: PI3-2026-T2-G09

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/model/offerModel.dart';

/// Tabela de livro de ordens estilo balcão de negociação.
/// Lado esquerdo: ordens de venda (ask) — preço crescente.
/// Lado direito: ordens de compra (bid) — preço decrescente.
class OrderBookTable extends StatelessWidget {
  final List<OfferModel> vendaOrders;
  final List<OfferModel> compraOrders;

  const OrderBookTable({
    super.key,
    required this.vendaOrders,
    required this.compraOrders,
  });

  static const _red = Color(0xFFE74C3C);
  static const _green = Color(0xFF1A9B5F);
  static const _divider = Color(0xFF3A3A3A);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF262629),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          ...List.generate(5, (i) => _buildRow(
            venda: i < vendaOrders.length ? vendaOrders[i] : null,
            compra: i < compraOrders.length ? compraOrders[i] : null,
            isLast: i == 4,
          )),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _buildSideHeader('Venda', isVenda: true)),
          Container(width: 1, height: 20, color: _divider),
          Expanded(child: _buildSideHeader('Compra', isVenda: false)),
        ],
      ),
    );
  }

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
              Icon(
                isVenda ? Icons.arrow_downward : Icons.arrow_upward,
                size: 11,
                color: isVenda ? _red : _green,
              ),
            ],
          ),
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

  Widget _buildRow({
    required OfferModel? venda,
    required OfferModel? compra,
    required bool isLast,
  }) {
    return Container(
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.04)),
              ),
            ),
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

  Widget _buildVendaCell(OfferModel? offer) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: offer == null
          ? const SizedBox()
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${offer.quantidade.toInt()}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  'R\$ ${offer.precoPorToken.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    color: _red,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCompraCell(OfferModel? offer) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: offer == null
          ? const SizedBox()
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${offer.quantidade.toInt()}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  'R\$ ${offer.precoPorToken.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    color: _green,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }
}

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
