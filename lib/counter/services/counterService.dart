// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesclainvest_f/model/offerModel.dart';

class CounterService {
  static const _baseUrl =
      'https://us-central1-mesclainvest-5ee48.cloudfunctions.net/api/balcao';

  // Todas as startups disponíveis no balcão (carregamento inicial síncrono para fallback)
  static const List<Map<String, String>> allStartups = [
    {'id': 'startup_eco', 'nome': 'EcoTech PUC'},
    {'id': 'startup_med', 'nome': 'MedConnect'},
    {'id': 'startup_agri', 'nome': 'AgriSmart'},
    {'id': 'startup_fin', 'nome': 'FinEduca'},
  ];

  /// Helper privado para gerar os headers HTTP com o token Bearer
  Future<Map<String, String>> _getHeaders() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Queries por startup ────────────────────────────────────────────────

  /// Ofertas de venda para uma startup — preço crescente (mais barato primeiro)
  Future<List<OfferModel>> getVendaForStartup(String startupId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/offers/$startupId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final offersList = body['offers'] as List<dynamic>;

        final list = offersList
            .map((item) {
              final map = item as Map<String, dynamic>;
              return _mapOfferJsonToModel(map);
            })
            .where((o) => o.tipo == OrderType.venda)
            .toList();

        list.sort((a, b) => a.precoPorToken.compareTo(b.precoPorToken));
        return list;
      } else {
        throw Exception(
          'Falha ao obter ofertas de venda: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Retorna lista vazia ou lança dependendo da UI
      return [];
    }
  }

  /// Ofertas de compra para uma startup — preço decrescente (maior lance primeiro)
  Future<List<OfferModel>> getCompraForStartup(String startupId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/offers/$startupId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final offersList = body['offers'] as List<dynamic>;

        final list = offersList
            .map((item) {
              final map = item as Map<String, dynamic>;
              return _mapOfferJsonToModel(map);
            })
            .where((o) => o.tipo == OrderType.compra)
            .toList();

        list.sort((a, b) => b.precoPorToken.compareTo(a.precoPorToken));
        return list;
      } else {
        throw Exception(
          'Falha ao obter ofertas de compra: ${response.statusCode}',
        );
      }
    } catch (e) {
      return [];
    }
  }

  /// Ordens do usuário logado — mais recente primeiro
  Future<List<OfferModel>> getUserOffers(String userId) async {
    try {
      final snapshotDirect = await FirebaseFirestore.instance
          .collection('balcaoOffers')
          .where('userId', isEqualTo: userId)
          .get();

      final list = snapshotDirect.docs.map((doc) {
        final data = doc.data();
        return OfferModel(
          id: doc.id,
          startupId: data['startupId'] ?? '',
          startupNome: data['startupNome'] ?? 'Startup',
          vendedorId: data['userId'] ?? '',
          vendedorNome: 'Minha Ordem',
          quantidade: (data['quantity'] as num?)?.toDouble() ?? 0.0,
          precoPorToken: (data['pricePerToken'] as num?)?.toDouble() ?? 0.0,
          tipo: data['type'] == 'buy' ? OrderType.compra : OrderType.venda,
          status: data['status'] == 'open'
              ? OrderStatus.aberta
              : (data['status'] == 'cancelled'
                    ? OrderStatus.cancelada
                    : OrderStatus.executada),
          criadoEm: data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
        );
      }).toList();

      list.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
      return list;
    } catch (e) {
      return [];
    }
  }

  // ── Token holdings do usuário ──────────────────────────────────────────

  /// ID determinístico do documento na coleção top-level `holdings`.
  static String _holdingDocId(String userId, String startupId) =>
      '${userId}_$startupId';

  /// Quantidade de tokens que o usuário possui em determinada startup.
  /// Lê diretamente da coleção top-level `holdings` (Firestore SDK) para evitar
  /// depender do round-trip pela API; faz fallback para a subcoleção legada `investors`.
  Future<double> getUserTokens(String startupId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0.0;

      final db = FirebaseFirestore.instance;
      final holdingDoc = await db
          .collection('holdings')
          .doc(_holdingDocId(user.uid, startupId))
          .get();

      if (holdingDoc.exists) {
        final data = holdingDoc.data();
        return (data?['quantity'] as num?)?.toDouble() ?? 0.0;
      }

      // Fallback para registros legados na subcoleção investors
      final investorDoc = await db
          .collection('startups')
          .doc(startupId)
          .collection('investors')
          .doc(user.uid)
          .get();
      if (investorDoc.exists) {
        return (investorDoc.data()?['tokens'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Busca a lista de holdings de tokens do próprio usuário autenticado
  Future<List<Map<String, dynamic>>> getMyTokens() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/my-tokens'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final holdingsList = body['holdings'] as List<dynamic>;
        return holdingsList
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else {
        throw Exception(
          'Falha ao obter tokens holdings: ${response.statusCode}',
        );
      }
    } catch (e) {
      return [];
    }
  }

  /// Startups onde o usuário tem pelo menos 1 token — lê Firestore diretamente
  Future<List<Map<String, String>>> getStartupsWithUserTokens() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final db = FirebaseFirestore.instance;
      final snap = await db
          .collection('holdings')
          .where('userId', isEqualTo: user.uid)
          .get();

      final result = <Map<String, String>>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final qty = (data['quantity'] as num?)?.toDouble() ?? 0;
        if (qty <= 0) continue;
        final startupId = (data['startupId'] as String?) ?? '';
        if (startupId.isEmpty) continue;

        String nome = startupId;
        try {
          final sdoc = await db.collection('startups').doc(startupId).get();
          if (sdoc.exists) {
            nome = (sdoc.data()?['name'] as String?) ?? startupId;
          }
        } catch (_) {}

        result.add({'id': startupId, 'nome': nome});
      }
      return result;
    } catch (e) {
      return [];
    }
  }

  // ── Mutações ───────────────────────────────────────────────────────────

  /// Registra uma nova oferta no balcão via API REST
  Future<bool> addOffer(OfferModel offer) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/offer'),
        headers: headers,
        body: json.encode({
          'startupId': offer.startupId,
          'type': offer.tipo == OrderType.compra ? 'buy' : 'sell',
          'quantity': offer.quantidade,
          'pricePerToken': offer.precoPorToken,
        }),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final offerId = body['offerId'] as String;

        try {
          await FirebaseFirestore.instance
              .collection('balcaoOffers')
              .doc(offerId)
              .set({
                'userId': offer.vendedorId,
                'userName': offer.vendedorNome,
                'startupId': offer.startupId,
                'startupNome': offer.startupNome,
                'type': offer.tipo == OrderType.compra ? 'buy' : 'sell',
                'quantity': offer.quantidade,
                'remainingQuantity': offer.quantidade,
                'pricePerToken': offer.precoPorToken,
                'status': 'open',
                'createdAt': FieldValue.serverTimestamp(),
              });
        } catch (_) {}

        // Ao publicar uma VENDA, decrementa os holdings imediatamente para o
        // dashboard refletir que os tokens estão reservados/saindo da carteira.
        if (offer.tipo == OrderType.venda) {
          try {
            final db = FirebaseFirestore.instance;
            final holdingRef = db
                .collection('holdings')
                .doc('${offer.vendedorId}_${offer.startupId}');
            await db.runTransaction((tx) async {
              final snap = await tx.get(holdingRef);
              if (!snap.exists) return;
              final current =
                  (snap.data()?['quantity'] as num?)?.toDouble() ?? 0;
              final updated = (current - offer.quantidade).clamp(
                0.0,
                double.maxFinite,
              );
              tx.update(holdingRef, {
                'quantity': updated,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            });
          } catch (_) {}
        }

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Cancela uma oferta aberta pertencente ao usuário.
  /// Se for uma oferta de VENDA, restaura os holdings decrementados na publicação.
  Future<bool> cancelOffer(String offerId) async {
    try {
      // Lê os dados da oferta antes de cancelar para restaurar holdings se necessário
      Map<String, dynamic>? offerData;
      try {
        final snap = await FirebaseFirestore.instance
            .collection('balcaoOffers')
            .doc(offerId)
            .get();
        if (snap.exists) offerData = snap.data();
      } catch (_) {}

      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/offer/$offerId'),
        headers: headers,
      );

      if (response.statusCode == 200 && offerData?['type'] == 'sell') {
        try {
          final userId = offerData!['userId'] as String?;
          final startupId = offerData['startupId'] as String?;
          final remaining =
              (offerData['remainingQuantity'] ?? offerData['quantity'] as num?)
                  ?.toDouble() ??
              0.0;
          if (userId != null && startupId != null && remaining > 0) {
            final db = FirebaseFirestore.instance;
            final holdingRef = db
                .collection('holdings')
                .doc('${userId}_$startupId');
            await db.runTransaction((tx) async {
              final snap = await tx.get(holdingRef);
              if (!snap.exists) return;
              final current =
                  (snap.data()?['quantity'] as num?)?.toDouble() ?? 0;
              tx.update(holdingRef, {
                'quantity': current + remaining,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            });
          }
        } catch (_) {}
      }

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Compra de tokens diretamente da startup (transação nativa no Flutter)
  Future<Map<String, dynamic>> buyTokens(
    String startupId,
    double quantity,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      final db = FirebaseFirestore.instance;
      double newBalance = 0.0;
      double newTokenPrice = 0.0;

      String? txError;

      try {
        await db.runTransaction((transaction) async {
          try {
            final startupRef = db.collection('startups').doc(startupId);
            final userRef = db.collection('users').doc(user.uid);
            final tokenRef = startupRef.collection('investors').doc(user.uid);
            final holdingRef = db
                .collection('holdings')
                .doc(_holdingDocId(user.uid, startupId));

            // Execute all reads first
            final startupDoc = await transaction.get(startupRef);
            final userDoc = await transaction.get(userRef);
            final tokenDoc = await transaction.get(tokenRef);
            final holdingDoc = await transaction.get(holdingRef);

            if (!startupDoc.exists) throw 'Startup não encontrada';
            if (!userDoc.exists) throw 'Usuário não encontrado';

            final sData = startupDoc.data() as Map<String, dynamic>;
            final priceCents =
                (sData['currentTokenPriceCents'] as num?)?.toInt() ?? 100;
            final price = priceCents / 100.0;
            newTokenPrice = price;
            final totalCost = quantity * price;

            final uData = userDoc.data() as Map<String, dynamic>;
            final currentBalance = (uData['saldo'] as num?)?.toDouble() ?? 0.0;

            if (currentBalance < totalCost) throw 'Saldo insuficiente';

            newBalance = currentBalance - totalCost;

            // Execute all writes after reads
            transaction.update(userRef, {'saldo': newBalance});

            final tData = tokenDoc.data();
            final currentTokens = (tData?['tokens'] as num?)?.toDouble() ?? 0.0;

            if (!tokenDoc.exists) {
              transaction.set(tokenRef, {
                'userId': user.uid,
                'startupId': startupId,
                'tokens': quantity,
                'updatedAt': Timestamp.now(),
              });
            } else {
              transaction.update(tokenRef, {
                'tokens': currentTokens + quantity,
                'updatedAt': Timestamp.now(),
              });
            }

            // Atualiza a coleção top-level `holdings` (preço médio ponderado em centavos)
            final hData = holdingDoc.data();
            final prevQty = (hData?['quantity'] as num?)?.toDouble() ?? 0.0;
            final prevAvgCents =
                (hData?['averagePriceCents'] as num?)?.toDouble() ?? 0.0;
            final newQty = prevQty + quantity;
            final newAvgCents = newQty > 0
                ? ((prevQty * prevAvgCents) + (quantity * priceCents)) / newQty
                : 0.0;

            transaction.set(holdingRef, {
              'userId': user.uid,
              'startupId': startupId,
              'quantity': newQty,
              'averagePriceCents': newAvgCents.round(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            final tokensSold = (sData['tokensSold'] as num?)?.toDouble() ?? 0.0;
            final capitalRaisedCents =
                (sData['capitalRaisedCents'] as num?)?.toInt() ?? 0;
            final addedCents = (totalCost * 100).toInt();
            transaction.update(startupRef, {
              'tokensSold': tokensSold + quantity,
              'capitalRaisedCents': capitalRaisedCents + addedCents,
            });
          } catch (e, stack) {
            txError = 'ERRO REAL: $e\n$stack';
            rethrow;
          }
        });
      } catch (e) {
        if (txError != null) throw Exception(txError);
        rethrow;
      }

      return {
        'success': true,
        'updatedBalance': newBalance,
        'newTokenPrice': newTokenPrice,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString().replaceFirst('Exception: ', ''),
      };
    }
  }

  /// Compra tokens de uma oferta de usuário no mercado secundário.
  /// Decrementa a oferta em balcaoOffers e transfere saldo entre comprador e vendedor.
  Future<Map<String, dynamic>> buyFromOffer(
    OfferModel offer,
    double quantity,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      final buyerId = user.uid;
      final sellerId = offer.vendedorId;
      if (buyerId == sellerId)
        throw Exception('Você não pode comprar sua própria oferta');

      final db = FirebaseFirestore.instance;
      double newBuyerBalance = 0.0;

      await db.runTransaction((tx) async {
        final offerRef = db.collection('balcaoOffers').doc(offer.id);
        final buyerRef = db.collection('users').doc(buyerId);
        final sellerRef = db.collection('users').doc(sellerId);
        final buyerHoldingRef = db
            .collection('holdings')
            .doc('${buyerId}_${offer.startupId}');
        final sellerHoldingRef = db
            .collection('holdings')
            .doc('${sellerId}_${offer.startupId}');

        final offerSnap = await tx.get(offerRef);
        final buyerSnap = await tx.get(buyerRef);
        final sellerSnap = await tx.get(sellerRef);
        final buyerHoldingSnap = await tx.get(buyerHoldingRef);
        final sellerHoldingSnap = await tx.get(sellerHoldingRef);

        if (!offerSnap.exists) throw Exception('Oferta não encontrada');
        final oData = offerSnap.data() as Map<String, dynamic>;
        if (oData['status'] != 'open')
          throw Exception('Oferta não está mais disponível');

        final currentQty =
            ((oData['remainingQuantity'] ?? oData['quantity']) as num?)
                ?.toDouble() ??
            0;
        if (quantity > currentQty) {
          throw Exception(
            'Quantidade solicitada (${quantity.toInt()}) maior que disponível (${currentQty.toInt()})',
          );
        }

        final totalCost = quantity * offer.precoPorToken;
        final bData = buyerSnap.data() as Map<String, dynamic>;
        final buyerBalance = (bData['saldo'] as num?)?.toDouble() ?? 0.0;
        if (buyerBalance < totalCost) throw Exception('Saldo insuficiente');

        newBuyerBalance = buyerBalance - totalCost;
        final sData = sellerSnap.data() as Map<String, dynamic>;
        final sellerBalance = (sData['saldo'] as num?)?.toDouble() ?? 0.0;

        // Atualiza oferta: decrementa quantidade
        final newQty = currentQty - quantity;
        tx.update(offerRef, {
          'quantity': newQty,
          'remainingQuantity': newQty,
          'status': newQty <= 0 ? 'matched' : 'open',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Transfere saldo
        tx.update(buyerRef, {'saldo': newBuyerBalance});
        tx.update(sellerRef, {'saldo': sellerBalance + totalCost});

        // Holdings do comprador (preço médio ponderado)
        final bhData = buyerHoldingSnap.data();
        final prevBuyerQty = (bhData?['quantity'] as num?)?.toDouble() ?? 0.0;
        final prevBuyerAvgCents =
            (bhData?['averagePriceCents'] as num?)?.toDouble() ?? 0.0;
        final priceCents = (offer.precoPorToken * 100).roundToDouble();
        final newBuyerQty = prevBuyerQty + quantity;
        final newAvgCents = newBuyerQty > 0
            ? ((prevBuyerQty * prevBuyerAvgCents) + (quantity * priceCents)) /
                  newBuyerQty
            : 0.0;
        tx.set(buyerHoldingRef, {
          'userId': buyerId,
          'startupId': offer.startupId,
          'quantity': newBuyerQty,
          'averagePriceCents': newAvgCents.round(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Holdings do vendedor (decrementa)
        final shData = sellerHoldingSnap.data();
        final prevSellerQty = (shData?['quantity'] as num?)?.toDouble() ?? 0.0;
        final newSellerQty = (prevSellerQty - quantity).clamp(
          0.0,
          double.maxFinite,
        );
        tx.set(sellerHoldingRef, {
          'userId': sellerId,
          'startupId': offer.startupId,
          'quantity': newSellerQty,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Registra operação
        tx.set(db.collection('operations').doc(), {
          'buyerId': buyerId,
          'sellerId': sellerId,
          'startupId': offer.startupId,
          'startupName': offer.startupNome,
          'offerId': offer.id,
          'quantity': quantity,
          'pricePerTokenCents': (offer.precoPorToken * 100).round(),
          'askedPricePerTokenCents': (offer.precoPorToken * 100).round(),
          'totalCents': (totalCost * 100).round(),
          'type': 'buy_from_user',
          'status': 'accepted',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      return {'success': true, 'updatedBalance': newBuyerBalance};
    } catch (e) {
      return {
        'success': false,
        'error': e.toString().replaceFirst('Exception: ', ''),
      };
    }
  }

  /// Venda de tokens diretamente para a startup (transação nativa no Flutter)
  Future<Map<String, dynamic>> sellTokens(
    String startupId,
    double quantity,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      final db = FirebaseFirestore.instance;
      double newBalance = 0.0;
      double newTokenPrice = 0.0;

      await db.runTransaction((transaction) async {
        final startupRef = db.collection('startups').doc(startupId);
        final userRef = db.collection('users').doc(user.uid);
        final tokenRef = startupRef.collection('investors').doc(user.uid);
        final holdingRef = db
            .collection('holdings')
            .doc(_holdingDocId(user.uid, startupId));

        // Execute all reads first
        final startupDoc = await transaction.get(startupRef);
        final userDoc = await transaction.get(userRef);
        final tokenDoc = await transaction.get(tokenRef);
        final holdingDoc = await transaction.get(holdingRef);

        if (!startupDoc.exists) throw 'Startup não encontrada';
        if (!userDoc.exists) throw 'Usuário não encontrado';

        final sData = startupDoc.data() as Map<String, dynamic>;
        final priceCents =
            (sData['currentTokenPriceCents'] as num?)?.toInt() ?? 100;
        final price = priceCents / 100.0;
        newTokenPrice = price;
        final totalValue = quantity * price;

        final uData = userDoc.data() as Map<String, dynamic>;
        final currentBalance = (uData['saldo'] as num?)?.toDouble() ?? 0.0;

        // Valida a quantidade prioritariamente pela coleção top-level `holdings`,
        // com fallback para a subcoleção legada `investors`.
        final hData = holdingDoc.data();
        final legacyTokens =
            (tokenDoc.data()?['tokens'] as num?)?.toDouble() ?? 0.0;
        final heldQty = holdingDoc.exists
            ? ((hData?['quantity'] as num?)?.toDouble() ?? 0.0)
            : legacyTokens;

        if (heldQty < quantity) throw 'Insufficient tokens';

        newBalance = currentBalance + totalValue;
        transaction.update(userRef, {'saldo': newBalance});

        // Decrementa subcoleção investors (retrocompat) somente se existir
        if (tokenDoc.exists) {
          final remainingLegacy = legacyTokens - quantity;
          if (remainingLegacy <= 0) {
            transaction.delete(tokenRef);
          } else {
            transaction.update(tokenRef, {
              'tokens': remainingLegacy,
              'updatedAt': Timestamp.now(),
            });
          }
        }

        // Decrementa a coleção top-level `holdings`
        final remainingHolding = heldQty - quantity;
        if (remainingHolding <= 0) {
          transaction.set(holdingRef, {
            'userId': user.uid,
            'startupId': startupId,
            'quantity': 0,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else {
          transaction.set(holdingRef, {
            'userId': user.uid,
            'startupId': startupId,
            'quantity': remainingHolding,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        final tokensSold = (sData['tokensSold'] as num?)?.toDouble() ?? 0.0;
        final capitalRaisedCents =
            (sData['capitalRaisedCents'] as num?)?.toInt() ?? 0;
        final deductedCents = (totalValue * 100).toInt();
        transaction.update(startupRef, {
          'tokensSold': tokensSold - quantity,
          'capitalRaisedCents': capitalRaisedCents - deductedCents,
        });
      });

      return {
        'success': true,
        'updatedBalance': newBalance,
        'newTokenPrice': newTokenPrice,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString().replaceFirst('Exception: ', ''),
      };
    }
  }

  /// Busca histórico de preço de uma startup por período
  Future<List<Map<String, dynamic>>> getPriceHistory(
    String startupId,
    String period,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/price-history/$startupId?period=$period'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final historyList = body['history'] as List<dynamic>;
        return historyList
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else {
        throw Exception(
          'Falha ao obter histórico de preço: ${response.statusCode}',
        );
      }
    } catch (e) {
      return [];
    }
  }

  /// Compra de múltiplos vendedores simultaneamente com prioridade para lances mais baratos (Greedy matching)
  Future<Map<String, dynamic>> buyFromOrders(
    String startupId,
    double quantity,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/buy-from-orders'),
        headers: headers,
        body: json.encode({'startupId': startupId, 'quantity': quantity}),
      );

      final body = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {
          'success': true,
          'filledQuantity': (body['filledQuantity'] as num).toDouble(),
          'totalPaid': (body['totalPaid'] as num).toDouble(),
          'change': (body['change'] as num).toDouble(),
          'operations': body['operations'] as List<dynamic>,
        };
      } else {
        return {
          'success': false,
          'error':
              body['error'] ?? 'Erro ao processar compra casada no Balcão.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Falha na comunicação com o servidor: $e',
      };
    }
  }

  // ── Mapeadores Privados ─────────────────────────────────────────────────

  OfferModel _mapOfferJsonToModel(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'] ?? '',
      startupId: json['startupId'] ?? '',
      startupNome: json['startupNome'] ?? 'Startup',
      vendedorId: json['userId'] ?? '',
      vendedorNome: json['vendedorNome'] ?? 'Outro Usuário',
      quantidade: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      precoPorToken: (json['pricePerToken'] as num?)?.toDouble() ?? 0.0,
      tipo: json['type'] == 'buy' ? OrderType.compra : OrderType.venda,
      status: json['status'] == 'open'
          ? OrderStatus.aberta
          : (json['status'] == 'cancelled'
                ? OrderStatus.cancelada
                : OrderStatus.executada),
      criadoEm: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
