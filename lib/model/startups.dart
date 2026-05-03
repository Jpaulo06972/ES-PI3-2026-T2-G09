// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684
// Revisado e comentado por: Antigravity AI

import 'package:mesclainvest_f/enum/stageStartup.dart';
import 'package:mesclainvest_f/enum/statusStartup.dart';

/// Modelo de dados que representa uma Startup dentro do ecossistema MesclaInvest.
/// Centraliza todas as informações de negócio, métricas financeiras e composição societária.
class StartupModel {
  // Identificador único gerado pelo Firestore
  final String uid;

  // Nome fantasia da startup
  String nome;

  // Texto detalhado sobre a proposta de valor e mercado da startup
  String descricao;

  // Estágio de maturidade (Ex: Nova, Em Operação, Em Expansão)
  StageStartup stageStartup;

  // Ramo de atividade (Ex: Fintech, Agrotech, Edtech)
  String setor;

  // Montante total em Reais que a startup já captou ou deseja captar
  double capitalAportado;

  // Volume total de ativos digitais (tokens) disponibilizados pela empresa
  double tokensEmitidos;

  // Lista de sócios fundadores: Armazena maps com 'nome', 'cargo' e 'bio'
  List<Map<String, String>> socios;

  // Divisão percentual do equity: Mapeia o nome do sócio para seu respectivo %
  Map<String, double> participacaoSocietaria;

  // Conselheiros e mentores que apoiam a governança da startup
  List<Map<String, String>> mentoresConselho;

  // Link ou caminho para a imagem de capa (banner) da startup
  String imagem;

  // Link do vídeo de pitch (YouTube/Vimeo) para apresentação aos investidores
  String video;

  // Status de visibilidade da startup no catálogo (Ex: Ativa, Inativa, Pendente)
  StatusStartup status;

  // Construtor principal para instanciar uma startup com os dados básicos obrigatórios
  StartupModel({
    required this.uid,
    required this.nome,
    required this.descricao,
    required this.stageStartup,
    required this.setor,
    this.capitalAportado = 0.0,
    required this.tokensEmitidos,
    required this.socios,
    required this.participacaoSocietaria,
    this.mentoresConselho = const [],
    this.imagem = "",
    this.video = "",
    this.status = StatusStartup.inativa,
  });

  // Getters - Facilitam o acesso aos dados seguindo padrões de encapsulamento
  String get getName => nome;
  String get getDescription => descricao;
  String get getStage => '$stageStartup';
  String get getSector => setor;
  double get getCapital => capitalAportado;
  double get getTokens => tokensEmitidos;
  List<Map<String, String>> get getPartners => socios;
  Map<String, double> get getEquity => participacaoSocietaria;
  List<Map<String, String>> get getMentors => mentoresConselho;
  String get getImage => imagem;
  String get getVideo => video;
  StatusStartup get getStatus => status;

  // Setters - Permitem a alteração controlada das propriedades da instância
  set setName(String value) => nome = value;
  set setDescription(String value) => descricao = value;
  set setStage(StageStartup value) => stageStartup = value;
  set setSector(String value) => setor = value;
  set setCapital(double value) => capitalAportado = value;
  set setTokens(double value) => tokensEmitidos = value;
  set setPartners(List<Map<String, String>> value) => socios = value;
  set setEquity(Map<String, double> value) => participacaoSocietaria = value;
  set setMentors(List<Map<String, String>> value) => mentoresConselho = value;
  set setImage(String value) => imagem = value;
  set setVideo(String value) => video = value;
  set setStatus(StatusStartup value) => status = value;

  /// Método Factory para converter um documento do Firestore (Map) em uma instância de StartupModel.
  /// Inclui proteções contra tipos nulos ou incorretos vindos do banco de dados.
  factory StartupModel.fromMap(String id, Map<String, dynamic> map) {
    return StartupModel(
      uid: id,
      nome: map['name'] ?? '',
      descricao: map['description'] ?? '',
      // Tenta converter o estágio vindo como String para o Enum correspondente
      stageStartup: StageStartup.values.firstWhere(
        (e) => e.name == (map['stage'] ?? ''),
        orElse: () => StageStartup.nova,
      ),
      setor: map['setor'] ?? '',
      // Garante que valores numéricos sejam tratados como double, mesmo se vierem como int
      capitalAportado: (map['capital'] as num?)?.toDouble() ?? 0.0,
      tokensEmitidos: (map['tokens'] as num?)?.toDouble() ?? 0.0,
      // Converte listas dinâmicas para listas tipadas de Maps
      socios: (map['socios'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          [],
      // Converte o map de participações garantindo que os valores sejam double
      participacaoSocietaria: (map['participacao'] as Map<dynamic, dynamic>?)
              ?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ??
          {},
      mentoresConselho: (map['mentores'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          [],
      imagem: map['imagem'] ?? '',
      video: map['video'] ?? '',
      // Tenta converter o status vindo como String para o Enum correspondente
      status: StatusStartup.values.firstWhere(
        (e) => e.name == (map['status'] ?? ''),
        orElse: () => StatusStartup.inativa,
      ),
    );
  }

  /// Converte o objeto para um Map pronto para ser persistido no Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': nome,
      'description': descricao,
      'stage': stageStartup.name, // Salva o nome do enum como string no banco
      'setor': setor,
      'capital': capitalAportado,
      'tokens': tokensEmitidos,
      'socios': socios,
      'participacao': participacaoSocietaria,
      'mentores': mentoresConselho,
      'imagem': imagem,
      'video': video,
      'status': status.name, // Salva o nome do enum como string no banco
    };
  }
}
