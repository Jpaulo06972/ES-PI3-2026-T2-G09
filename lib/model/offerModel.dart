// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum que nos diz se o usuário quer comprar ou vender.
/// Por que um enum? Para a gente não ter que ficar lidando com Strings do tipo 
/// "COMPRA" ou "Venda", que são fáceis de digitar errado e bugar a listagem no balcão.
enum OrderType { compra, venda }

/// O semáforo da nossa ordem no balcão.
/// - [aberta]    — A ordem está lá na vitrine, esperando alguém aceitar.
/// - [cancelada] — O cara que criou desistiu e tirou a ordem da vitrine.
/// - [executada] — Deu match! Alguém comprou/vendeu e o negócio foi fechado.
enum OrderStatus { aberta, cancelada, executada }

/// Model que mapeia as intenções de compra/venda no nosso Balcão (Mercado Secundário).
///
/// Pensa nisso aqui como um "anúncio de classificados" dentro do app.
/// O usuário chega e diz: "Quero vender 100 tokens da startup X por R$ 5 cada".
/// Essa classe empacota toda essa intenção para mandarmos pro banco (Firestore).
class OfferModel {
  /// O ID único gerado pelo banco para esta oferta.
  final String id;

  /// O código da startup que está sendo negociada.
  final String startupId;

  /// O nome da startup. Salvamos isso junto aqui para não precisar fazer 
  /// um join super custoso lá no Firebase toda vez que for listar.
  final String startupNome;

  /// Quem é o dono dessa oferta? (O ID dele)
  final String vendedorId;

  /// O nome do dono da oferta, de novo pra evitar joins desnecessários.
  final String vendedorNome;

  /// Quantos tokens estão na mesa.
  final double quantidade;

  /// Quanto o cara está pedindo (ou disposto a pagar) por CADA token.
  final double precoPorToken;

  /// É uma oferta de [compra] ou de [venda]?
  final OrderType tipo;

  /// Como está essa oferta agora? [aberta], [executada] ou [cancelada]?
  final OrderStatus status;

  /// Quando isso foi postado? Importante para ordenar e mostrar as mais recentes primeiro.
  final DateTime criadoEm;

  /// O construtor. Repare que o status já nasce como [aberta], 
  /// o que faz total sentido: ninguém cria uma ordem já executada.
  OfferModel({
    required this.id,
    required this.startupId,
    required this.startupNome,
    required this.vendedorId,
    required this.vendedorNome,
    required this.quantidade,
    required this.precoPorToken,
    required this.tipo,
    this.status = OrderStatus.aberta,
    required this.criadoEm,
  });

  /// Factory genial que transforma aquele Map sujo vindo do Firestore num objeto bonitinho do Dart.
  ///
  /// Aqui o segredo é o defensive programming: note o uso de `??` (fallback) 
  /// e conversões seguras. Nunca confie 100% que o banco vai devolver o dado perfeito!
  factory OfferModel.fromMap(String id, Map<String, dynamic> map) {
    return OfferModel(
      id: id,
      startupId: map['startupId'] ?? '',
      startupNome: map['startupNome'] ?? '',
      vendedorId: map['vendedorId'] ?? '',
      vendedorNome: map['vendedorNome'] ?? '',
      // Se o Firebase inventar de devolver um int em vez de double (acontece muito!),
      // o `as num?` resolve o problema e o `.toDouble()` padroniza.
      quantidade: (map['quantidade'] as num?)?.toDouble() ?? 0.0,
      precoPorToken: (map['precoPorToken'] as num?)?.toDouble() ?? 0.0,
      
      // Aqui a gente busca qual enum tem o nome que veio do banco.
      // E se vir lixo do banco? O orElse salva nosso dia e devolve [venda] como padrão.
      tipo: OrderType.values.firstWhere(
        (e) => e.name == (map['tipo'] ?? ''),
        orElse: () => OrderType.venda,
      ),
      
      status: OrderStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? ''),
        orElse: () => OrderStatus.aberta,
      ),
      
      // Datas no Firestore vem como Timestamp.
      // Precisamos converter pro DateTime do Dart pra conseguir exibir bonitinho na tela.
      criadoEm: map['criadoEm'] is Timestamp
          ? (map['criadoEm'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// O caminho inverso do fromMap. Pega nosso objeto maravilhoso e transforma num Map 
  /// pra gente enviar pro Firestore.
  Map<String, dynamic> toMap() {
    return {
      'startupId': startupId,
      'startupNome': startupNome,
      'vendedorId': vendedorId,
      'vendedorNome': vendedorNome,
      'quantidade': quantidade,
      'precoPorToken': precoPorToken,
      // .name pega a string pura do enum. Fica perfeito lá no console do Firebase.
      'tipo': tipo.name,
      'status': status.name,
      // Voltamos nosso DateTime pra Timestamp, que é o tipo que o Firestore adora.
      'criadoEm': Timestamp.fromDate(criadoEm),
    };
  }

  /// Nossa máquina de xerox. O copyWith clona o objeto trocando só o que a gente pedir.
  ///
  /// Como Flutter ama imutabilidade (objetos que não mudam), ao invés de fazermos 
  /// `offer.status = cancelada`, a gente cria um clone com o status novo. 
  /// Isso evita bugs assustadores de estado compartilhado.
  OfferModel copyWith({OrderStatus? status}) {
    return OfferModel(
      id: id,
      startupId: startupId,
      startupNome: startupNome,
      vendedorId: vendedorId,
      vendedorNome: vendedorNome,
      quantidade: quantidade,
      precoPorToken: precoPorToken,
      tipo: tipo,
      // Se o Dev passou um status novo, usa ele. Se não, copia o antigo mesmo.
      status: status ?? this.status,
      criadoEm: criadoEm,
    );
  }
}
