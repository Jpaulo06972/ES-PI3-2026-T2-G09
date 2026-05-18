// Grupo: G09
// Trabalho: PI3-2026-T2-G09

import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderType { compra, venda }

enum OrderStatus { aberta, cancelada, executada }

class OfferModel {
  final String id;
  final String startupId;
  final String startupNome;
  final String vendedorId;
  final String vendedorNome;
  final double quantidade;
  final double precoPorToken;
  final OrderType tipo;
  final OrderStatus status;
  final DateTime criadoEm;

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

  factory OfferModel.fromMap(String id, Map<String, dynamic> map) {
    return OfferModel(
      id: id,
      startupId: map['startupId'] ?? '',
      startupNome: map['startupNome'] ?? '',
      vendedorId: map['vendedorId'] ?? '',
      vendedorNome: map['vendedorNome'] ?? '',
      quantidade: (map['quantidade'] as num?)?.toDouble() ?? 0.0,
      precoPorToken: (map['precoPorToken'] as num?)?.toDouble() ?? 0.0,
      tipo: OrderType.values.firstWhere(
        (e) => e.name == (map['tipo'] ?? ''),
        orElse: () => OrderType.venda,
      ),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? ''),
        orElse: () => OrderStatus.aberta,
      ),
      criadoEm: map['criadoEm'] is Timestamp
          ? (map['criadoEm'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startupId': startupId,
      'startupNome': startupNome,
      'vendedorId': vendedorId,
      'vendedorNome': vendedorNome,
      'quantidade': quantidade,
      'precoPorToken': precoPorToken,
      'tipo': tipo.name,
      'status': status.name,
      'criadoEm': Timestamp.fromDate(criadoEm),
    };
  }

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
      status: status ?? this.status,
      criadoEm: criadoEm,
    );
  }
}
