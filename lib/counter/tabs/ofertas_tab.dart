// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

// Aba "Ofertas" (Visualização Simples).
// Esse componente escuta ofertas de VENDA abertas no mercado secundário
// pra mostrar aos investidores num card reduzido. 

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Exibe listagem em tempo real de quem está querendo vender tokens
/// para uma startup específica.
class OfertasTab extends StatelessWidget {
  // O ID da startup (usado no Where da Query do Firebase)
  final String startupId;
  // Uma função utilitária do pai pra não duplicar lógica de formatação de moedas
  final String Function(double) fmtBRL;

  const OfertasTab({super.key, required this.startupId, required this.fmtBRL});

  @override
  Widget build(BuildContext context) {
    // Liga o ouvido na coleção de ofertas pra buscar tudo relacionado à startup selecionada
    // e cujo status seja 'open'. Ninguém quer ver ordem cancelada ou já executada.
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('balcaoOffers')
          .where('startupId', isEqualTo: startupId)
          .where('status', isEqualTo: 'open')
          .snapshots(),
      builder: (context, snap) {
        final offers = snap.data?.docs ?? [];
        
        // Separa só o que for VENDA (sell). Ignora compras (buy).
        final sellOffers = offers
            .where((d) => (d.data() as Map)['type'] == 'sell')
            .toList();

        // O menor preço vem no topo. Comprador adora pechincha.
        sellOffers.sort(
          (a, b) => ((a.data() as Map)['pricePerToken'] as num).compareTo(
            (b.data() as Map)['pricePerToken'] as num,
          ),
        );

        // Se o mercado tá morto (ninguém vendendo).
        if (sellOffers.isEmpty) {
          return const Center(
            child: Text(
              'Sem ofertas de venda no mercado secundário.',
              style: TextStyle(color: Colors.white, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          );
        }

        // ListView pra poder scrollar a vontade as ofertas.
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            // Rótulo da lista, cor vermelha indicando "Venda".
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Ofertas de Venda',
                style: TextStyle(
                  color: Color(0xFFE74C3C),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Mapeia os documentos brutos para containers visuais.
            ...sellOffers.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final double price = (data['pricePerToken'] ?? 0.0).toDouble();
              
              // Tenta usar remainingQuantity (se houve compra parcial), senao pega o total.
              final double qty =
                  (data['remainingQuantity'] ?? data['quantity'] ?? 0.0)
                      .toDouble();
              
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Bolinha vermelha estilo "Live/Alerta" pra chamar atencao.
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE74C3C),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${qty.toInt()} tokens',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    // Preço usando a funçãozinha helper injetada pelo Widget Pai.
                    Text(
                      fmtBRL(price),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
