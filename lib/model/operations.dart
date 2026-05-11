// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesclainvest_f/enum/operationStatus.dart';
import 'package:mesclainvest_f/enum/typeOfOperation.dart';

class OperationModel {
  final String id;
  final String authorID;
  final double amount;
  final TypeOfOperation operation;
  final OperationStatus status;
  final String targetUserId;
  final String? text;
  final String? createdAt;
  final String? completedAt;

  OperationModel({
    required this.id,
    required this.authorID,
    required this.amount,
    required this.operation,
    required this.status,
    required this.targetUserId,
    required this.text,
    required this.createdAt,
    required this.completedAt,
  });

  String get getId => id;
  String get getAuthorID => authorID;
  double get getAmount => amount;
  TypeOfOperation get getOperation => operation;
  OperationStatus get getStatus => status;
  String get getTargetUserId => targetUserId;
  String? get getText => text;
  String? get getCreatedAt => createdAt;
  String? get getCompletedAt => completedAt;

  set setStatus(OperationStatus status) => status = status;
  set setCompletedAt(String? completedAt) => completedAt = completedAt;

  factory OperationModel.fromMap(String id, Map<String, dynamic> map) {
    // Tenta pegar o valor de 'amountCents' ou 'amount' ou 'valor'
    final dynamic rawAmount = map['amountCents'] ?? map['amount'] ?? map['valor'] ?? 0;
    
    // Se vier do backend novo, ele chama de 'typeOfOperation', se for antigo 'operation'
    final String typeStr = map['typeOfOperation'] ?? map['operation'] ?? '';

    return OperationModel(
      id: id,
      authorID: map['authorUid']?.toString() ?? map['authorID']?.toString() ?? '',
      amount: rawAmount.toDouble(), 
      operation: TypeOfOperation.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => TypeOfOperation.investimento,
      ),
      status: OperationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OperationStatus.pendente,
      ),
      targetUserId: map['targetUserId']?.toString() ?? '',
      text: map['text']?.toString(),
      createdAt: _parseDate(map['createdAt']),
      completedAt: _parseDate(map['completedAt']),
    );
  }

  static String? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is String) return date;
    
    DateTime? dt;
    if (date is Timestamp) {
      dt = date.toDate();
    } else if (date is Map) {
      final seconds = date['_seconds'] ?? date['seconds'];
      if (seconds != null) {
        dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    }
    
    if (dt != null) {
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }
    
    return date.toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorID': authorID,
      'amount': amount,
      'operation': operation.name,
      'status': status.name,
      'targetUserId': targetUserId,
      'text': text,
      'createdAt': createdAt,
      'completedAt': completedAt,
    };
  }

  @override
  String toString() {
    return 'OperationModel{id: $id, authorID: $authorID, amount: $amount, operation: $operation, status: $status, targetUserId: $targetUserId, text: $text, createdAt: $createdAt, completedAt: $completedAt}';
  }
}
