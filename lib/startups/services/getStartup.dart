// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:cloud_functions/cloud_functions.dart';

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
