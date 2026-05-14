// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o Firestore para salvar os dados do perfil do usuário
import 'package:cloud_firestore/cloud_firestore.dart';

class GetListOperation {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getOperations({String? userId}) async {
    try {
      if (userId == null) return [];

      // Fazemos as queries separadas para evitar a necessidade de índices compostos complexos no Firestore
      final results = await Future.wait([
        _firestore.collection('operations').where('authorUid', isEqualTo: userId).get(),
        _firestore.collection('operations').where('authorID', isEqualTo: userId).get(),
        _firestore.collection('operations').where('targetUserId', isEqualTo: userId).get(),
      ]);

      // Usamos um Map para garantir que não haja operações duplicadas (caso achem em mais de uma query)
      final Map<String, Map<String, dynamic>> mergedOperations = {};

      for (var snapshot in results) {
        for (var doc in snapshot.docs) {
          if (!mergedOperations.containsKey(doc.id)) {
            final data = doc.data();
            data['id'] = doc.id;
            mergedOperations[doc.id] = data;
          }
        }
      }

      return mergedOperations.values.toList();
    } catch (e) {
      throw Exception('Erro ao listar operações: $e');
    }
  }
}
