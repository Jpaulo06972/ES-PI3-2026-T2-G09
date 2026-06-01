// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684
// Revisado e comentado por: Equipe G09

import 'package:mesclainvest_f/enum/stageStartup.dart';
import 'package:mesclainvest_f/enum/statusStartup.dart';

/// O grande coração do app: o model da Startup!
///
/// Tudo no MesclaInvest gira em torno delas. Essa classe é a "pasta" que guarda
/// toda a papelada e ficha técnica de uma startup cadastrada na plataforma.
/// Da descrição bonitinha pro investidor até o controle matemático do equity (sociedade).
class StartupModel {
  // O CPF da startup no Firebase. Identificador único e sagrado.
  final String uid;

  // O nome fantasia que vai aparecer grande no app.
  String nome;

  // O pitch de elevador. Aqui eles contam o que fazem e porque são bons.
  String descricao;

  // Qual o nível do "chefão" dessa startup? (Nova, em operação, expansão)
  StageStartup stageStartup;

  // Em que campo eles jogam? (Agrotech, Fintech, Edtech, etc)
  String setor;

  // O tanque de combustível financeiro deles. Quanto já captaram.
  double capitalAportado;

  // Quantas "fatias do bolo" (tokens) eles colocaram no mercado.
  double tokensEmitidos;

  // A lista de quem manda na parada. Cada sócio tem nome, bio e cargo no Map.
  List<Map<String, String>> socios;

  // Como o bolo é dividido! Mapeia o "João" -> 50.0 (%)
  Map<String, double> participacaoSocietaria;

  // Os gurus da startup. Geralmente gente do mercado que dá conselhos pro board.
  List<Map<String, String>> mentoresConselho;

  // A vitrine do app! A URL da imagem principal que fica nos cards.
  String imagem;

  // URL de YouTube/Vimeo. Se a imagem vende, o vídeo fecha o negócio.
  String video;

  // Só aparece pro investidor se isso aqui estiver como [ativa]. Senão, fica na gaveta.
  StatusStartup status;

  // Construtor lotado! O Dart obriga a passar os required, 
  // mas as listas e status a gente inicia vazias ou inativas por segurança.
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

  // Getters - Para que o pessoal do UI (Telas) consiga pegar os dados 
  // sem risco de alterar nada acidentalmente no meio do processo.
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

  // Setters - A portaria controlada. Quem quiser alterar o dado de uma startup
  // já instanciada tem que passar por aqui.
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

  /// Método clássico para sugar os dados do Firestore e dar vida a nossa StartupModel.
  /// Se atente à malandragem das validações. Nunca confie no que o banco te entrega!
  factory StartupModel.fromMap(String id, Map<String, dynamic> map) {
    return StartupModel(
      uid: id,
      nome: map['name'] ?? '',
      descricao: map['description'] ?? '',
      // Tenta achar o Enum mágico, se o banco mandar coisa errada assume [nova] pra não quebrar.
      stageStartup: StageStartup.values.firstWhere(
        (e) => e.name == (map['stage'] ?? ''),
        orElse: () => StageStartup.nova,
      ),
      setor: map['setor'] ?? '',
      
      // Lembra da dor de cabeça do Firebase mandar inteiro no lugar de double?
      // O `as num?` resolve isso com maestria.
      capitalAportado: (map['capital'] as num?)?.toDouble() ?? 0.0,
      tokensEmitidos: (map['tokens'] as num?)?.toDouble() ?? 0.0,
      
      // Aqui rola um cast pesado! Transforma a lista de 'dynamics' do banco
      // numa lista tipada bonitinha List<Map<String, String>>.
      socios: (map['socios'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          [],
          
      // O Equity vem como um Map "Nome" -> Percentual. 
      // Mapeamos a chave pra String e o valor pra double na marra!
      participacaoSocietaria: (map['participacao'] as Map<dynamic, dynamic>?)
              ?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ??
          {},
          
      mentoresConselho: (map['mentores'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          [],
      imagem: map['imagem'] ?? '',
      video: map['video'] ?? '',
      
      // Garantimos o status inativo em caso de falha. A regra é: Na dúvida, esconda!
      status: StatusStartup.values.firstWhere(
        (e) => e.name == (map['status'] ?? ''),
        orElse: () => StatusStartup.inativa,
      ),
    );
  }

  /// O passaporte de volta pro banco de dados. 
  /// Converte nosso objeto num formato Map "limpo" pro Firestore devorar.
  Map<String, dynamic> toMap() {
    return {
      'name': nome,
      'description': descricao,
      'stage': stageStartup.name, // String pura, nada de enum lá no console do Firebase
      'setor': setor,
      'capital': capitalAportado,
      'tokens': tokensEmitidos,
      'socios': socios,
      'participacao': participacaoSocietaria,
      'mentores': mentoresConselho,
      'imagem': imagem,
      'video': video,
      'status': status.name, 
    };
  }
}
