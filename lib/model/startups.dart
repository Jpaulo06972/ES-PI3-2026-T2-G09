// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:mesclainvest_f/enum/stageStartup.dart';
import 'package:mesclainvest_f/enum/statusStartup.dart';

// Modelo de dados da Startup — representa as informações de uma empresa cadastrada
// É usado para exibir as informações nos cards e nas telas de detalhes
class StartupModel {
  // ID único da Startup no Firebase (gerado automaticamente ao criar a conta)
  final String uid;

  // Nome da empresa
  String nome;

  // Descricao da startup
  String descricao;

  // Estagio atual da startup
  StageStartup stageStartup;

  // Setor da startup
  String setor;

  // Valor de investimento total da startup
  double capitalAportado;

  // Quantidade de tokens emitidos pela startup
  double tokensEmitidos;

  // Sócios da startup
  List<Map<String, String>> socios;

  // Participação societária
  Map<String, double> participacaoSocietaria;

  // Mentores e conselheiros
  List<Map<String, String>> mentoresConselho;

  // Imagem da startup
  String imagem;

  // Video da startup
  String video;

  // Status da startup
  StatusStartup status;

  // Construtor — uid, nome, descricao, stageStartup, setor, tokensEmitidos, socios, participacaoSocietaria são obrigatórios, o resto tem valor padrão vazio
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

  // Nome da startup
  String get getName => nome;

  // Descrição da startup
  String get getDescription => descricao;

  // Estágio da startup
  String get getStage => '$stageStartup';

  // Setor da startup
  String get getSector => setor;
  // Capital aportado da startup
  double get getCapital => capitalAportado;

  // Tokens emitidos pela startup
  double get getTokens => tokensEmitidos;

  // Sócios da startup
  List<Map<String, String>> get getPartners => socios;

  // Participação societária da startup
  Map<String, double> get getEquity => participacaoSocietaria;

  // Mentores e conselheiros da startup
  List<Map<String, String>> get getMentors => mentoresConselho;

  // Imagem da startup
  String get getImage => imagem;

  // Video da startup
  String get getVideo => video;

  // Status da startup
  StatusStartup get getStatus => status;

  // --- Setters para alteração de dados ---

  // Altera o nome da startup
  set setName(String value) {
    nome = value;
  }

  // Altera a descrição da startup
  set setDescription(String value) {
    descricao = value;
  }

  set setStage(StageStartup stageStartup) {
    this.stageStartup = stageStartup;
  }

  set setSector(String setor) {
    this.setor = setor;
  }

  set setCapital(double capitalAportado) {
    this.capitalAportado = capitalAportado;
  }

  set setTokens(double tokensEmitidos) {
    this.tokensEmitidos = tokensEmitidos;
  }

  set setPartners(List<Map<String, String>> socios) {
    this.socios = socios;
  }

  set setEquity(Map<String, double> participacaoSocietaria) {
    this.participacaoSocietaria = participacaoSocietaria;
  }

  set setMentors(List<Map<String, String>> mentoresConselho) {
    this.mentoresConselho = mentoresConselho;
  }

  set setImage(String imagem) {
    this.imagem = imagem;
  }

  set setVideo(String video) {
    this.video = video;
  }

  set setStatus(StatusStartup status) {
    this.status = status;
  }

  // Cria um StartupModel a partir de um documento do Firestore ou de um Map
  // O Firestore retorna os dados como Map<String, dynamic>, então precisamos
  // "traduzir" isso para o nosso modelo. O '?? ""' garante que se o campo
  // não existir no banco, ele não vai quebrar o app (fica como valor padrão)
  factory StartupModel.fromMap(String id, Map<String, dynamic> map) {
    return StartupModel(
      uid: id,
      nome: map['name'] ?? '',
      descricao: map['description'] ?? '',
      stageStartup: map['stage'] ?? '',
      setor: map['setor'] ?? '',
      capitalAportado: map['capital'] ?? '',
      tokensEmitidos: map['tokens'] ?? '',
      socios: map['socios'] ?? '',
      participacaoSocietaria: map['participacao'] ?? '',
      mentoresConselho: map['mentores'] ?? '',
      imagem: map['imagem'] ?? '',
      video: map['video'] ?? '',
      status: map['status'] ?? '',
    );
  }

  // Converte o StartupModel de volta para Map — usado para salvar no Firestore
  // O Firestore só aceita dados no formato de Map (chave-valor)
  // Obs: o uid não é incluído no Map porque ele já é usado como o ID do documento
  Map<String, dynamic> toMap() {
    return {
      'name': nome,
      'description': descricao,
      'stage': stageStartup,
      'setor': setor,
      'capital': capitalAportado,
      'tokens': tokensEmitidos,
      'socios': socios,
      'participacao': participacaoSocietaria,
      'mentores': mentoresConselho,
      'imagem': imagem,
      'video': video,
      'status': status,
    };
  }
}
