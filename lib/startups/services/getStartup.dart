// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684
//
// Feito por: Tomás Toniato RA: 25004211

// Acesso direto ao Firestore para consultas sem passar pelo Functions
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
// debugPrint exibe logs no console do browser (Flutter web)
import 'package:flutter/foundation.dart';

/// Serviço responsável pela comunicação com o backend (Firebase Functions)
/// para buscar, listar e popular as startups.
class StartupService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Lista as startups do catálogo.
  /// Permite filtrar opcionalmente por estágio ([stage]) ou texto ([search]).
  Future<List<Map<String, dynamic>>> listStartups({
    String? stage,
    String? search,
  }) async {
    try {
      // Chama a function 'listStartups'
      final callable = _functions.httpsCallable('listStartups');

      // Passa os parâmetros de filtro caso existam
      final response = await callable.call(<String, dynamic>{
        if (stage != null) 'stage': stage,
        if (search != null) 'search': search,
      });

      // A function retorna um objeto com 'data' (lista) e 'count'
      final resultData = response.data as Map<String, dynamic>;
      final list = resultData['data'] as List<dynamic>;

      // Converte a lista dinâmica para uma lista de Maps tipada
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      throw Exception('Erro ao listar startups: $e');
    }
  }

  /// Retorna os detalhes detalhados de uma startup baseada no [startupId].
  Future<Map<String, dynamic>> getStartupDetails(String startupId) async {
    try {
      final callable = _functions.httpsCallable('getStartupDetails');
      final response = await callable.call(<String, dynamic>{'id': startupId});

      final resultData = response.data as Map<String, dynamic>;

      // A function retorna os detalhes dentro do campo 'data'
      return Map<String, dynamic>.from(resultData['data'] as Map);
    } catch (e) {
      throw Exception('Erro ao buscar detalhes da startup: $e');
    }
  }

  /// Busca os eventos da coleção [event_startups] no Firestore,
  /// filtrando pelo campo [startupName] (nome exato da startup).
  /// A ordenação por data é feita no cliente para evitar a necessidade
  /// de índice composto no Firestore.
  Future<List<Map<String, dynamic>>> listEventos(String startupName) async {
    try {
      // Log de diagnóstico — visível no console do browser (F12)
      debugPrint('>>> listEventos buscando por startupName: "$startupName"');

      // Busca sem filtro para diagnóstico: lista todos os docs da coleção
      // e imprime o startupName de cada um para comparar com o valor passado
      final snapshotAll = await FirebaseFirestore.instance
          .collection('event_startups')
          .get();
      debugPrint(
        '>>> total docs na coleção (sem filtro): ${snapshotAll.docs.length}',
      );
      for (final d in snapshotAll.docs) {
        debugPrint(
          '>>> doc ${d.id}: startupName="${d.data()['startupName']}"',
        );
      }

      // Query real: filtra apenas os eventos da startup em questão
      final snapshot = await FirebaseFirestore.instance
          .collection('event_startups')
          .where('startupName', isEqualTo: startupName)
          .get();
      debugPrint('>>> com filtro encontrou: ${snapshot.docs.length} doc(s)');

      // Inclui o ID do documento junto aos dados para uso futuro
      final docs = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Ordena pelo campo 'data' (string) em ordem crescente
      docs.sort((a, b) {
        final aData = (a['data'] ?? '').toString();
        final bData = (b['data'] ?? '').toString();
        return aData.compareTo(bData);
      });

      return docs;
    } catch (e) {
      throw Exception('Erro ao buscar eventos: $e');
    }
  }

  /// Cria uma pergunta na subcoleção `comments` de uma startup.
  /// [visibility] deve ser `'publica'` ou `'privada'`.
  Future<void> createComment(
    String startupId,
    String text,
    String visibility,
  ) async {
    try {
      final callable = _functions.httpsCallable('createStartupComment');
      await callable.call(<String, dynamic>{
        'startupId': startupId,
        'text': text,
        'visibility': visibility,
      });
    } catch (e) {
      throw Exception('Erro ao enviar pergunta: $e');
    }
  }

  /// Lista as perguntas da subcoleção `comments` de uma startup.
  /// Retorna perguntas públicas + privadas do usuário logado.
  Future<List<Map<String, dynamic>>> listComments(String startupId) async {
    try {
      final callable = _functions.httpsCallable('listStartupComments');
      final response = await callable.call(<String, dynamic>{
        'startupId': startupId,
      });

      final resultData = response.data as Map<String, dynamic>;
      final data = resultData['data'] as Map<String, dynamic>;
      final list = data['comments'] as List<dynamic>;

      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      throw Exception('Erro ao listar perguntas: $e');
    }
  }

  /// Roda a function que popula o banco com as startups de demonstração.
  Future<Map<String, dynamic>> seedStartupCatalog() async {
    try {
      final callable = _functions.httpsCallable('seedStartupCatalog');
      final response = await callable.call();

      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      throw Exception('Erro ao popular banco de dados (seed): $e');
    }
  }
}
