// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o Firestore para salvar os dados do perfil do usuário
import 'package:cloud_functions/cloud_functions.dart';

class GetListOperation {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<List<Map<String, dynamic>>> getOperations({String? userId}) async {
    try {
      final callable = _functions.httpsCallable("getListOperations");

      final response = await callable.call(<String, dynamic>{
        if (userId != null) 'userId': userId,
      });

      final resultData = response.data as Map<String, dynamic>;
      final operations = resultData['data'] as List<dynamic>;

      return operations
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      throw Exception('Erro ao listar operações: $e');
    }
  }
}
