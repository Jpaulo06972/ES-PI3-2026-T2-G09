import 'package:cloud_firestore/cloud_firestore.dart';

enum OperationType { buyFromStartup, buyFromUser, sellToUser }
enum OperationStatus { pending, accepted, rejected, cancelled }

class OperationModel {
  final String id;
  final OperationType type;
  final OperationStatus status;
  final String? buyerId;
  final String? sellerId;
  final String startupId;
  final String startupName;
  final int quantity;
  final int pricePerTokenCents;
  final int askedPricePerTokenCents;
  final int totalCents;
  final DateTime? createdAt;
  final DateTime? resolvedAt;
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

  double get pricePerToken => pricePerTokenCents / 100;
  double get total => totalCents / 100;

  factory OperationModel.fromMap(String id, Map<String, dynamic> data) {
    return OperationModel(
      id: id,
      type: _parseType(data['type'] as String? ?? ''),
      status: _parseStatus(data['status'] as String? ?? ''),
      buyerId: data['buyerId'] as String?,
      sellerId: data['sellerId'] as String?,
      startupId: data['startupId'] as String? ?? '',
      startupName: data['startupName'] as String? ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      pricePerTokenCents: (data['pricePerTokenCents'] as num?)?.toInt() ?? 0,
      askedPricePerTokenCents:
          (data['askedPricePerTokenCents'] as num?)?.toInt() ?? 0,
      totalCents: (data['totalCents'] as num?)?.toInt() ?? 0,
      createdAt: _tsToDate(data['createdAt']),
      resolvedAt: _tsToDate(data['resolvedAt']),
      resolvedBy: data['resolvedBy'] as String?,
    );
  }

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

  static OperationStatus _parseStatus(String s) {
    switch (s) {
      case 'pending':
        return OperationStatus.pending;
      case 'accepted':
        return OperationStatus.accepted;
      case 'rejected':
        return OperationStatus.rejected;
      case 'cancelled':
        return OperationStatus.cancelled;
      default:
        return OperationStatus.pending;
    }
  }

  static DateTime? _tsToDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    return null;
  }
}
