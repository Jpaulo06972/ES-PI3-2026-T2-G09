// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum que explica de onde vieram ou para onde vão os tokens numa negociação.
/// - [buyFromStartup] — O famoso mercado primário. Compra direto da fonte.
/// - [buyFromUser]    — Mercado secundário. Você comprando tokens de outro investidor.
/// - [sellToUser]     — Mercado secundário. Você liquidando sua posição vendendo pra alguém.
enum OperationType { buyFromStartup, buyFromUser, sellToUser }

/// O que aconteceu com a operação?
/// - [accepted]  — Deu certo, os tokens trocaram de mão e a grana caiu.
/// - [cancelled] — Alguém desistiu ou deu algum problema na liquidação.
enum OperationStatus { accepted, cancelled }

/// Model para registrar que uma operação DE FATO aconteceu com tokens.
///
/// Diferente do OfferModel (que é só a *intenção* de negócio), aqui a parada já rolou.
/// Detalhe sênior: Note que os valores monetários aqui estão em CENTAVOS (int).
/// Por que? Porque Double perde precisão com números decimais gigantes, e a gente 
/// não quer sumir com os centavos do usuário. Inteiro sempre!
class OperationModel {
  /// ID único do recibo da transação lá no banco.
  final String id;

  /// De qual mercado (primário ou secundário) isso faz parte?
  final OperationType type;

  /// Deu boa ou foi cancelado?
  final OperationStatus status;

  /// Quem botou a grana. Pode ser null se for uma operação que não rastreia o comprador.
  final String? buyerId;

  /// Quem entregou os tokens. Pode ser null se a compra for direto da startup.
  final String? sellerId;

  /// A startup alvo. A "ação" que está sendo negociada.
  final String startupId;

  /// O nome da startup, salvo junto pra não ter que bater no banco e gastar request.
  final String startupName;

  /// Volume negociado. Quantos tokens mudaram de mão.
  final int quantity;

  /// Quanto custou CADA token, em centavos. Ex: R$ 5,00 é guardado como 500.
  final int pricePerTokenCents;

  /// O preço que o cara *queria* pagar ou vender, em centavos. 
  /// Se rolou um preço melhor pra ele no livro de ofertas, esse valor vai ser diferente do preço final.
  final int askedPricePerTokenCents;

  /// O montante total em centavos. É basicamente quantity * pricePerTokenCents.
  final int totalCents;

  /// Quando a oferta inicial foi criada.
  final DateTime? createdAt;

  /// Quando a operação foi liquidada e o dinheiro/token de fato mudou de dono.
  final DateTime? resolvedAt;

  /// Quem bateu o martelo. Geralmente é o nosso robozinho (engine) do balcão.
  final String? resolvedBy;

  const OperationModel({
    required this.id,
    required this.type,
    required this.status,
    this.buyerId,
    this.sellerId,
    required this.startupId,
    required this.startupName,
    required this.quantity,
    required this.pricePerTokenCents,
    required this.askedPricePerTokenCents,
    required this.totalCents,
    this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
  });

  /// Nossos atalhos pros Devs de Frontend!
  /// Ao invés da UI ter que fazer a conta toda hora e lembrar de dividir por 100,
  /// a gente já entrega o valor em Reais prontinho pra usar no Text().
  double get pricePerToken => pricePerTokenCents / 100;
  double get total => totalCents / 100;

  /// Construtor fromMap turbinado com Retrocompatibilidade!
  ///
  /// Em projetos reais, o banco evolui. Antes a gente salvava BRL em double,
  /// agora salvamos Cents em int. Pra não quebrar o app de quem tem histórico antigo,
  /// a gente tenta ler o novo formato, se falhar, lê o antigo e converte na mosca. Magia!
  factory OperationModel.fromMap(String id, Map<String, dynamic> data) {
    // 1. Tenta pegar os centavos (novo)
    final rawPriceCents = (data['pricePerTokenCents'] as num?)?.toInt();
    // 2. Tenta pegar o BRL (antigo)
    final rawPriceBrl = (data['pricePerToken'] as num?)?.toDouble();
    // 3. O fallback: Se tem centavos, usa. Se não tem, mas tem BRL, converte. Se não tem nada, zero.
    final priceCents = rawPriceCents ??
        (rawPriceBrl != null ? (rawPriceBrl * 100).round() : 0);

    // Mesma treta com o total
    final rawTotalCents = (data['totalCents'] as num?)?.toInt();
    final rawTotalBrl = (data['totalValue'] as num?)?.toDouble();
    final totalCents = rawTotalCents ??
        (rawTotalBrl != null ? (rawTotalBrl * 100).round() : 0);

    // Historicamente o nome do campo mudou de 'startupNome' (PT) pra 'startupName' (EN).
    // A gente tenta o novo, se falhar, puxa do antigo.
    final startupName = (data['startupName'] as String?)?.trim().isNotEmpty == true
        ? data['startupName'] as String
        : (data['startupNome'] as String? ?? '');

    return OperationModel(
      id: id,
      type: _parseType(data['type'] as String? ?? ''),
      status: _parseStatus(data['status'] as String? ?? ''),
      buyerId: data['buyerId'] as String?,
      sellerId: data['sellerId'] as String?,
      startupId: data['startupId'] as String? ?? '',
      startupName: startupName,
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      pricePerTokenCents: priceCents,
      
      // Se não tiver o asked price, assume que ele pediu exatamente o que pagou.
      askedPricePerTokenCents:
          (data['askedPricePerTokenCents'] as num?)?.toInt() ?? priceCents,
      totalCents: totalCents,
      createdAt: _tsToDate(data['createdAt']),
      resolvedAt: _tsToDate(data['resolvedAt']),
      resolvedBy: data['resolvedBy'] as String?,
    );
  }

  /// Lida com a string feia do banco e transforma no nosso enum limpinho.
  /// Se vier algo louco que não conhecemos, assumimos 'buyFromStartup' como fallback seguro.
  static OperationType _parseType(String t) {
    switch (t) {
      case 'buy_from_startup':
        return OperationType.buyFromStartup;
      case 'buy_from_user':
        return OperationType.buyFromUser;
      case 'sell_to_user':
        return OperationType.sellToUser;
      default:
        return OperationType.buyFromStartup;
    }
  }

  /// Mesma lógica de segurança pro status. Se vier lixo, assumimos accepted
  /// só pra operação não sumir misteriosamente do extrato do usuário.
  static OperationStatus _parseStatus(String s) {
    switch (s) {
      case 'accepted':
        return OperationStatus.accepted;
      case 'cancelled':
        return OperationStatus.cancelled;
      default:
        return OperationStatus.accepted;
    }
  }

  /// O clássico parser de datas do Firebase. Pega o Timestamp brabo do Firestore
  /// e transforma no doce e cheiroso DateTime do Dart.
  static DateTime? _tsToDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    return null;
  }
}
