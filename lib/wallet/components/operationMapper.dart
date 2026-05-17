// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesclainvest_f/enum/typeOfOperation.dart';
import 'package:mesclainvest_f/model/operations.dart';

/// Utilitário que converte dados brutos de operações do Firestore
/// em mapas prontos para exibição nos componentes de transação.
/// Centraliza a lógica duplicada entre a tela de extrato e a carteira principal.
class OperationMapper {
  /// Ordena os dados brutos por data (mais recente primeiro)
  static void sortByDateDesc(List<Map<String, dynamic>> rawData) {
    rawData.sort((a, b) {
      final dateA = a['createdAt'];
      final dateB = b['createdAt'];

      int secA = 0;
      if (dateA is Timestamp) {
        secA = dateA.seconds;
      } else if (dateA is Map) {
        secA = (dateA['_seconds'] ?? dateA['seconds'] ?? 0);
      }

      int secB = 0;
      if (dateB is Timestamp) {
        secB = dateB.seconds;
      } else if (dateB is Map) {
        secB = (dateB['_seconds'] ?? dateB['seconds'] ?? 0);
      }

      return secB.compareTo(secA);
    });
  }

  /// Converte uma lista de dados brutos do Firestore em uma lista de mapas
  /// prontos para uso nos componentes de transação.
  ///
  /// [rawData] - Lista de dados brutos vindos do Firestore.
  /// [currentUserId] - UID do usuário logado para identificar recebimentos.
  /// [useStatementIcons] - Se true, usa ícones do estilo da tela de extrato;
  ///                       se false, usa ícones do estilo da tela principal.
  static List<Map<String, dynamic>> mapOperations({
    required List<Map<String, dynamic>> rawData,
    required String currentUserId,
    bool useStatementIcons = false,
  }) {
    return rawData.map((data) {
      final op = OperationModel.fromMap(data['id'] ?? '', data);

      // Identifica quem é quem na transação
      bool souDestinatario = data['targetUserId'] == currentUserId;
      bool souAutor =
          (data['authorUid'] ?? data['authorID']) == currentUserId;

      IconData icon = Icons.help_outline;
      String title = op.text ?? 'Operação';
      bool isCredit = false;
      String subtitle = '';

      // Se eu sou o destinatário e não o autor, é um RECEBIMENTO
      if (souDestinatario && !souAutor) {
        isCredit = true;
        icon = Icons.move_to_inbox_rounded;
        title = useStatementIcons
            ? 'Transferência recebida'
            : (op.text ?? 'Transferência Recebida');
        subtitle = useStatementIcons ? (op.text ?? '') : '';
      } else {
        switch (op.operation) {
          case TypeOfOperation.deposito:
            icon = useStatementIcons
                ? Icons.add_circle_outline_rounded
                : Icons.add_circle;
            title = useStatementIcons
                ? 'Depósito'
                : (op.text ?? 'Depósito Realizado');
            subtitle = useStatementIcons
                ? (op.text ?? 'Conta MesclaInvest')
                : '';
            isCredit = true;
            break;
          case TypeOfOperation.pagar:
            icon = Icons.payment_rounded;
            title = useStatementIcons
                ? 'Pagamento'
                : (op.text ?? 'Pagamento Realizado');
            subtitle = useStatementIcons ? (op.text ?? '') : '';
            isCredit = false;
            break;
          case TypeOfOperation.transferencia:
            icon = useStatementIcons
                ? Icons.arrow_upward_rounded
                : Icons.swap_horiz_rounded;
            title = useStatementIcons
                ? 'Transferência enviada'
                : (op.text ?? 'Transferência Enviada');
            subtitle = useStatementIcons ? (op.text ?? '') : '';
            isCredit = false;
            break;
          case TypeOfOperation.saque:
            icon = useStatementIcons
                ? Icons.arrow_downward_rounded
                : Icons.account_balance_wallet_rounded;
            title = useStatementIcons
                ? 'Saque'
                : (op.text ?? 'Saque Realizado');
            subtitle = useStatementIcons
                ? (op.text ?? 'Conta bancária')
                : '';
            isCredit = false;
            break;
          case TypeOfOperation.investimento:
            icon = useStatementIcons
                ? Icons.rocket_launch_rounded
                : Icons.rocket_launch;
            title = useStatementIcons
                ? 'Investimento'
                : (op.text ?? 'Investimento Efetuado');
            subtitle = useStatementIcons ? (op.text ?? '') : '';
            isCredit = false;
            break;
        }
      }

      // Tipo para filtro
      String filterType;
      if (souDestinatario && !souAutor) {
        filterType = 'transferencia';
      } else {
        filterType = op.operation.name;
      }

      return {
        'icon': icon,
        'title': title,
        'subtitle': subtitle,
        'date': op.createdAt ?? 'Data não informada',
        'value': op.amount,
        'isCredit': isCredit,
        'type': filterType,
        'id': op.id,
      };
    }).toList();
  }
}
