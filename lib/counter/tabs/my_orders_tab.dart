// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

// Aba "Minhas Ordens".
// Traz o histórico completo de operações executadas do usuário no Balcão.
// É tipo o extrato bancário de compra/venda de tokens dele.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesclainvest_f/counter/components/empty_prompt.dart';
import 'package:mesclainvest_f/counter/components/section_label.dart';
import 'package:mesclainvest_f/counter/components/operation_card.dart';
import 'package:mesclainvest_f/model/operationModel.dart';

/// Aba que lista as operações do investidor.
/// É bem simples, ela mesmo busca os dados do Firestore usando um StreamBuilder.
class MyOrdersTab extends StatelessWidget {
  // UID do usuário. Necessário para filtrar o que é dele e esconder o do resto do mundo.
  final String userId;

  const MyOrdersTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder é o maestro aqui. Fica ouvindo o Firebase e atualiza a tela
    // se pintar uma nova operação. Magia pura.
    return StreamBuilder<QuerySnapshot>(
      // Filtra na coleção 'operations' onde o buyerId for o nosso cara.
      stream: FirebaseFirestore.instance
          .collection('operations')
          .where('buyerId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snap) {
        // Enquanto o dado não chega (internet lenta), joga o loading giratório verde.
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(color: Color(0xFF107649)),
            ),
          );
        }

        // Puxa a lista de docs. Usa fallback pra array vazio caso seja null.
        final docs = snap.data?.docs ?? [];
        
        // Faz o parse do mapa de dados pro nosso objeto de negócio (OperationModel)
        final ops =
            docs
                .map(
                  (d) => OperationModel.fromMap(
                    d.id,
                    d.data() as Map<String, dynamic>,
                  ),
                )
                .toList()
              // Ordena na unha (código-fonte) da mais recente pra mais antiga.
              // O Firestore pode fazer isso no backend com orderBy, mas requer criar índice lá.
              ..sort(
                (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                  a.createdAt ?? DateTime(0),
                ),
              );

        // Sem histórico? Mostra a view genérica "Tudo vazio por aqui".
        if (ops.isEmpty) {
          return const EmptyPrompt(
            message: 'Você ainda não tem operações registradas',
          );
        }

        // Se tem dados, empurra pro ListView renderizar um a um.
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          physics: const BouncingScrollPhysics(),
          // O +1 é porque a primeira linha (índice 0) é ocupada pelo Título da Sessão.
          itemCount: ops.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              // Rótulo maroto grudado lá em cima
              return const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: SectionLabel(text: 'MINHAS OPERAÇÕES'),
              );
            }
            // Retorna o Card passando a operação. Subtrai 1 pra não bugar o índice do Array (por causa do Título).
            return OperationCard(op: ops[i - 1]);
          },
        );
      },
    );
  }
}
