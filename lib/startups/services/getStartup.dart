// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684
//
// Feito por: Tomás Toniato RA: 25004211

// Acesso direto ao Firestore para consultas sem passar pelo Functions
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
// debugPrint exibe logs no console do browser (F12 no Flutter web / logcat no Android)
import 'package:flutter/foundation.dart';

/// [StartupService] é a classe de serviço encarregada de gerenciar toda a integração
/// de dados do módulo de Startups entre o aplicativo móvel e o Firebase.
/// 
/// ### Decisão de Design de Integração:
/// - O serviço adota uma arquitetura híbrida inteligente:
///   1. Usa **Cloud Functions Callable** para operações complexas de negócio que envolvem regras de validação rígidas
///      (ex: listar comentários com controle de privacidade, criação de perguntas, listagem de startups).
///   2. Usa **Firestore SDK Direto** em consultas de leitura simples (ex: `listEventos`), onde fazer uma ponte
///      via Cloud Functions geraria custos desnecessários de execução de CPU sem ganho de segurança.
class StartupService {
  // Instancia o SDK de Cloud Functions para disparar chamadas HTTPS seguras baseadas em JSON
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Lista todas as startups cadastradas no catálogo.
  /// 
  /// ### Filtros Suportados:
  /// - [stage]: Filtra por estágio de maturidade (ex: 'nova', 'em_operacao').
  /// - [search]: Filtra por correspondência de texto no nome da startup.
  /// 
  /// ### Tratamento de Erros e Conversão:
  /// - A Cloud Function devolve uma estrutura dinâmica. Fazemos o mapeamento seguro `Map<String, dynamic>.from(e as Map)`
  ///   para evitar falhas de cast implícito no Dart (`_TypeError`), garantindo estabilidade do app.
  Future<List<Map<String, dynamic>>> listStartups({
    String? stage,
    String? search,
  }) async {
    try {
      // Estabelece a conexão com a função callable declarada no Node.js/TypeScript
      final callable = _functions.httpsCallable('listStartups');

      // Executa a chamada assíncrona transmitindo os filtros de forma condicional
      final response = await callable.call(<String, dynamic>{
        if (stage != null) 'stage': stage,
        if (search != null) 'search': search,
      });

      // Trata a resposta do servidor decodificando a lista estruturada
      final resultData = response.data as Map<String, dynamic>;
      final list = resultData['data'] as List<dynamic>;

      // Varre a lista dinâmica e converte defensivamente cada item para um Map tipado
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      throw Exception('Erro ao listar startups: $e');
    }
  }

  /// Retorna as informações completas e detalhadas de uma startup específica via [startupId].
  Future<Map<String, dynamic>> getStartupDetails(String startupId) async {
    try {
      final callable = _functions.httpsCallable('getStartupDetails');
      final response = await callable.call(<String, dynamic>{'id': startupId});

      final resultData = response.data as Map<String, dynamic>;

      // Retorna a estrutura interna do campo 'data' devidamente convertida
      return Map<String, dynamic>.from(resultData['data'] as Map);
    } catch (e) {
      throw Exception('Erro ao buscar detalhes da startup: $e');
    }
  }

  /// Busca os eventos da coleção `event_startups` diretamente do Firestore,
  /// utilizando o campo [startupName] (nome exato da startup) como critério de busca.
  /// 
  /// ### Detalhes e Decisão Técnica de Ordenação no Cliente:
  /// - O Firestore requer a criação de **Índices Compostos** manuais no console caso tentemos filtrar por `where`
  ///   e ordenar por `orderBy` simultaneamente na mesma query.
  /// - **Economia de Recursos**: Para contornar a necessidade de criar índices manuais (o que aumentaria a complexidade de deploy
  ///   e custos do Firebase), a consulta faz o filtro bruto e o algoritmo de ordenação por data (`docs.sort(...)`) é executado
  ///   diretamente na memória do celular do cliente. Como a lista de eventos de uma startup raramente passa de dezenas,
  ///   o impacto de CPU no cliente é irrisório (próximo de zero) e economiza recursos do banco de dados na nuvem.
  Future<List<Map<String, dynamic>>> listEventos(String startupName) async {
    try {
      // Logs de diagnóstico em console úteis durante o desenvolvimento
      debugPrint('>>> listEventos buscando por startupName: "$startupName"');

      // Busca geral de diagnóstico: ajuda a rastrear no console se há divergências de digitação ou caixa alta/baixa nos nomes
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

      // Consulta filtrada real no banco
      final snapshot = await FirebaseFirestore.instance
          .collection('event_startups')
          .where('startupName', isEqualTo: startupName)
          .get();
      debugPrint('>>> com filtro encontrou: ${snapshot.docs.length} doc(s)');

      // Une o ID único gerado pelo Firestore junto ao mapa de dados
      final docs = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Algoritmo de ordenação lexicográfica por data executado localmente
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

  /// Registra uma nova pergunta (comentário) associada a uma startup específica.
  /// 
  /// ### Parâmetros:
  /// - [startupId]: ID único da startup que receberá a pergunta.
  /// - [text]: O texto descritivo da pergunta digitada.
  /// - [visibility]: Deve ser obrigatoriamente `'publica'` (visível a todos) ou `'privada'` (investidor/fundador).
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

  /// Retorna as perguntas cadastradas para a startup.
  /// 
  /// ### Regra de Filtro no Servidor:
  /// - O backend filtra automaticamente as mensagens com base no usuário autenticado:
  ///   perguntas públicas aparecem para todos; perguntas privadas aparecem apenas se o usuário logado
  ///   for o autor dela, ou se for o fundador da própria startup em questão.
  Future<List<Map<String, dynamic>>> listComments(String startupId) async {
    try {
      final callable = _functions.httpsCallable('listStartupComments');
      final response = await callable.call(<String, dynamic>{
        'startupId': startupId,
      });

      final resultData = response.data as Map<String, dynamic>;
      final data = resultData['data'] as Map<String, dynamic>;
      final list = data['comments'] as List<dynamic>;

      // Conversão defensiva de tipos dinâmicos do JSON
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      throw Exception('Erro ao listar perguntas: $e');
    }
  }

  /// Roda a Cloud Function administrativa de "Seed" (carga inicial)
  /// Popula as startups de teste no banco com fotos, descrição, balanço societário e eventos fake.
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
