// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:mesclainvest_f/enum/typeOfOperation.dart';

class OperationService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Chama a Cloud Function para registrar uma nova operação financeira.
  Future<bool> createOperation({
    required double amount,
    required TypeOfOperation type,
    String? text,
    String? targetIdentifier,
  }) async {
    try {
      final callable = _functions.httpsCallable("createOperation");

      final response = await callable.call(<String, dynamic>{
        'amount': amount,
        'type': type.name, // Passa o nome do enum (ex: 'deposito', 'pagar')
        'text': text,
        'targetIdentifier': targetIdentifier,
      });

      final result = response.data as Map<String, dynamic>;
      return result['success'] ?? false;
    } catch (e) {
      debugPrint('Erro ao criar operação via Functions: $e');
      return false;
    }
  }
}
