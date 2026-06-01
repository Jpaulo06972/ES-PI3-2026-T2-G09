// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

// Aba "Ordens" dentro do contexto de uma única startup (BalcaoOrdersScreen).
// Mostra o histórico de compras que o cara já fez SÓ daquela startup específica.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesclainvest_f/counter/components/balcao_operation_card.dart';
import 'package:mesclainvest_f/model/operationModel.dart';
import 'package:mesclainvest_f/startups/components/startup_colors.dart';

/// Aba Ordens - Filtra e renderiza as operações fechadas.
class OrdensTab extends StatelessWidget {
  // IDs pra montar o Query no Banco.
  final String startupId;
  final String userId;
  
  // Função pra formatar dinheiro, vem lá do topo.
  final String Function(double) fmtBRL;

  const OrdensTab({
    super.key,
    required this.startupId,
    required this.userId,
    required this.fmtBRL,
  });

  @override
  Widget build(BuildContext context) {
    // Stream pra buscar na hora qualquer alteração na coleção 'operations' do usuário.
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('operations')
          .where('buyerId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snap) {
        // Enquanto tenta conectar e puxar, mostra o bolinho de loading.
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: StartupColors.green),
          );
        }

        final docs = snap.data?.docs ?? [];
        
        // Aqui ele faz o parse, filtra e ordena tudo na memória do celular.
        final ops =
            docs
                .map(
                  (d) => OperationModel.fromMap(
                    d.id,
                    d.data() as Map<String, dynamic>,
                  ),
                )
                // Peneira de Ouro: Pega a operação SÓ se for da startup que estamos vendo na tela!
                .where((op) => op.startupId == startupId)
                .toList()
              // Ordena jogando as compras mais fresquinhas pro topo da lista.
              ..sort(
                (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                  a.createdAt ?? DateTime(0),
                ),
              );

        // Se o histórico do cara tá limpo, solta a mensagem.
        if (ops.isEmpty) {
          return const Center(
            child: Text(
              'Nenhuma compra registrada.',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          );
        }

        // ListView que consome o array e cospe na tela na forma de Cards.
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: ops.length,
          itemBuilder: (context, index) =>
              BalcaoOperationCard(op: ops[index], fmtBRL: fmtBRL),
        );
      },
    );
  }
}
