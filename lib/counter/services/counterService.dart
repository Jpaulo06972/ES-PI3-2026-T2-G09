// Grupo: G09
// Trabalho: PI3-2026-T2-G09

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

        final list = offersList.map((item) {
          final map = item as Map<String, dynamic>;
          return _mapOfferJsonToModel(map);
        }).where((o) => o.tipo == OrderType.venda).toList();

        list.sort((a, b) => a.precoPorToken.compareTo(b.precoPorToken));
        return list;
      } else {
        throw Exception('Falha ao obter ofertas de venda: ${response.statusCode}');
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

        final list = offersList.map((item) {
          final map = item as Map<String, dynamic>;
          return _mapOfferJsonToModel(map);
        }).where((o) => o.tipo == OrderType.compra).toList();

        list.sort((a, b) => b.precoPorToken.compareTo(a.precoPorToken));
        return list;
      } else {
        throw Exception('Falha ao obter ofertas de compra: ${response.statusCode}');
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

  /// Quantidade de tokens que o usuário possui em determinada startup (obtido via API)
  Future<double> getUserTokens(String startupId) async {
    try {
      final holdings = await getMyTokens();
      final match = holdings.firstWhere(
        (h) => h['startupId'] == startupId,
        orElse: () => <String, dynamic>{},
      );
      return (match['tokens'] as num?)?.toDouble() ?? 0.0;
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
        return holdingsList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        throw Exception('Falha ao obter tokens holdings: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Startups onde o usuário tem pelo menos 1 token
  Future<List<Map<String, String>>> getStartupsWithUserTokens() async {
    try {
      final holdings = await getMyTokens();
      return holdings.map((h) {
        return {
          'id': (h['startupId'] ?? '').toString(),
          'nome': (h['startupName'] ?? 'Startup').toString(),
        };
      }).toList();
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
          await FirebaseFirestore.instance.collection('balcaoOffers').doc(offerId).set({
            'userId': offer.vendedorId,
            'startupId': offer.startupId,
            'startupNome': offer.startupNome,
            'type': offer.tipo == OrderType.compra ? 'buy' : 'sell',
            'quantity': offer.quantidade,
            'pricePerToken': offer.precoPorToken,
            'status': 'open',
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          // Ignora falha sutil
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Cancela uma oferta aberta pertencente ao usuário
  Future<bool> cancelOffer(String offerId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/offer/$offerId'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Compra de tokens diretamente da startup (transação nativa no Flutter)
  Future<Map<String, dynamic>> buyTokens(String startupId, double quantity) async {
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
            
            // Execute all reads first
            final startupDoc = await transaction.get(startupRef);
            final userDoc = await transaction.get(userRef);
            final tokenDoc = await transaction.get(tokenRef);
            
            if (!startupDoc.exists) throw 'Startup não encontrada';
            if (!userDoc.exists) throw 'Usuário não encontrado';
            
            final sData = startupDoc.data() as Map<String, dynamic>;
            final priceCents = (sData['currentTokenPriceCents'] as num?)?.toInt() ?? 100;
            final price = priceCents / 100.0;
            newTokenPrice = price;
            final totalCost = quantity * price;
            
            final uData = userDoc.data() as Map<String, dynamic>;
            final currentBalance = (uData['saldo'] as num?)?.toDouble() ?? 0.0;
            
            if (currentBalance < totalCost) throw 'Saldo insuficiente';
            
            newBalance = currentBalance - totalCost;
            
            // Execute all writes after reads
            transaction.update(userRef, {'saldo': newBalance});
            
            final tData = tokenDoc.data() as Map<String, dynamic>?;
            final currentTokens = (tData?['tokens'] as num?)?.toDouble() ?? 0.0;
            
            if (!tokenDoc.exists) {
              transaction.set(tokenRef, {
                'userId': user.uid,
                'startupId': startupId,
                'tokens': quantity,
                'updatedAt': Timestamp.now()
              });
            } else {
              transaction.update(tokenRef, {
                'tokens': currentTokens + quantity,
                'updatedAt': Timestamp.now()
              });
            }
            
            final tokensSold = (sData['tokensSold'] as num?)?.toDouble() ?? 0.0;
            final capitalRaisedCents = (sData['capitalRaisedCents'] as num?)?.toInt() ?? 0;
            final addedCents = (totalCost * 100).toInt();
            transaction.update(startupRef, {
              'tokensSold': tokensSold + quantity,
              'capitalRaisedCents': capitalRaisedCents + addedCents,
            });
          } catch (e, stack) {
            txError = 'ERRO REAL: $e\n$stack';
            throw e;
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

  /// Venda de tokens diretamente para a startup (transação nativa no Flutter)
  Future<Map<String, dynamic>> sellTokens(String startupId, double quantity) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');
      
      final db = FirebaseFirestore.instance;
      double newBalance = 0.0;
      double newTokenPrice = 0.0;
      
      await db.runTransaction((transaction) async {
        try {
          final startupRef = db.collection('startups').doc(startupId);
          final startupDoc = await transaction.get(startupRef);
          if (!startupDoc.exists) throw 'Startup não encontrada';
          
          final sData = startupDoc.data() as Map<String, dynamic>;
          final priceCents = (sData['currentTokenPriceCents'] as num?)?.toInt() ?? 100;
          final price = priceCents / 100.0;
          newTokenPrice = price;
          final totalValue = quantity * price;
          
          final userRef = db.collection('users').doc(user.uid);
          final userDoc = await transaction.get(userRef);
          if (!userDoc.exists) throw 'Usuário não encontrado';
          
          final uData = userDoc.data() as Map<String, dynamic>;
          final currentBalance = (uData['saldo'] as num?)?.toDouble() ?? 0.0;
          
          final tokenRef = startupRef.collection('investors').doc(user.uid);
          final tokenDoc = await transaction.get(tokenRef);
          if (!tokenDoc.exists) throw 'Você não possui tokens desta startup';
          
          final tData = tokenDoc.data() as Map<String, dynamic>;
          final currentTokens = (tData['tokens'] as num?)?.toDouble() ?? 0.0;
          
          if (currentTokens < quantity) throw 'Tokens insuficientes';
          
          newBalance = currentBalance + totalValue;
          transaction.update(userRef, {'saldo': newBalance});
          
          transaction.update(tokenRef, {'tokens': currentTokens - quantity, 'updatedAt': Timestamp.now()});
          
          final tokensSold = (sData['tokensSold'] as num?)?.toDouble() ?? 0.0;
          final capitalRaisedCents = (sData['capitalRaisedCents'] as num?)?.toInt() ?? 0;
          final deductedCents = (totalValue * 100).toInt();
          transaction.update(startupRef, {
            'tokensSold': tokensSold - quantity,
            'capitalRaisedCents': capitalRaisedCents - deductedCents,
          });
        } catch (e, stack) {
          throw 'TRANSACTION_ERROR: $e\n$stack';
        }
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
  Future<List<Map<String, dynamic>>> getPriceHistory(String startupId, String period) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/price-history/$startupId?period=$period'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final historyList = body['history'] as List<dynamic>;
        return historyList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        throw Exception('Falha ao obter histórico de preço: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Compra de múltiplos vendedores simultaneamente com prioridade para lances mais baratos (Greedy matching)
  Future<Map<String, dynamic>> buyFromOrders(String startupId, double quantity) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/buy-from-orders'),
        headers: headers,
        body: json.encode({
          'startupId': startupId,
          'quantity': quantity,
        }),
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
          'error': body['error'] ?? 'Erro ao processar compra casada no Balcão.'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Falha na comunicação com o servidor: $e'
      };
    }
  }

  /// Aprovação de oferta de compra pendente por parte do vendedor
  Future<bool> approveOffer(String offerId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/offer/$offerId/approve'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Recusa/rejeição de oferta de compra pendente por parte do vendedor
  Future<bool> rejectOffer(String offerId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/offer/$offerId/reject'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Obtém aprovações pendentes direcionadas ao usuário autenticado (como vendedor)
  Future<List<Map<String, dynamic>>> getPendingApprovals() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/pending-approvals'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final pendingList = body['pending'] as List<dynamic>;
        return pendingList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        throw Exception('Falha ao obter aprovações pendentes: ${response.statusCode}');
      }
    } catch (e) {
      return [];
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
