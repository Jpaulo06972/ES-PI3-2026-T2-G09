import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesclainvest_f/model/offerModel.dart';
import 'dart:math';

class TradingLogicService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> placeBuyOrder({
    required String userId,
    required String startupId,
    required String startupNome,
    required double qty,
    required double price,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await transaction.get(userRef);

      if (!userDoc.exists) throw Exception('Usuário não encontrado');

      final dataMap = userDoc.data() as Map<String, dynamic>?;
      final currentBalance = (dataMap?['saldo'] as num?)?.toDouble() ?? 0.0;
      final requiredBalance = qty * price;

      if (currentBalance < requiredBalance) {
        throw Exception('Saldo insuficiente para realizar esta ordem de compra');
      }

      // Deduzir BRL do saldo do comprador
      transaction.update(userRef, {
        'saldo': currentBalance - requiredBalance,
      });

      // Criar a ordem de compra
      final newOrderRef = _firestore.collection('offers').doc();
      final newOrder = {
        'userId': userId,
        'startupId': startupId,
        'startupNome': startupNome,
        'type': 'buy',
        'quantity': qty,
        'pricePerToken': price,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      };
      transaction.set(newOrderRef, newOrder);
    });

    // Chamar matching após a transação
    await _matchOrders(startupId);
  }

  Future<void> placeSellOrder({
    required String userId,
    required String startupId,
    required String startupNome,
    required double qty,
    required double price,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final tokenRef = _firestore
          .collection('startups')
          .doc(startupId)
          .collection('investors')
          .doc(userId);
      
      final tokenDoc = await transaction.get(tokenRef);

      if (!tokenDoc.exists) throw Exception('Você não possui tokens desta startup');

      final dataMap = tokenDoc.data() as Map<String, dynamic>?;
      final currentTokens = (dataMap?['tokens'] as num?)?.toDouble() ?? 0.0;

      if (currentTokens < qty) {
        throw Exception('Tokens insuficientes para realizar esta ordem de venda');
      }

      // Deduzir tokens da carteira do vendedor
      transaction.update(tokenRef, {
        'tokens': currentTokens - qty,
      });

      // Criar a ordem de venda
      final newOrderRef = _firestore.collection('offers').doc();
      final newOrder = {
        'userId': userId,
        'startupId': startupId,
        'startupNome': startupNome,
        'type': 'sell',
        'quantity': qty,
        'pricePerToken': price,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      };
      transaction.set(newOrderRef, newOrder);
    });

    // Chamar matching após a transação
    await _matchOrders(startupId);
  }

  Future<void> cancelOrder(String orderId, String userId) async {
    await _firestore.runTransaction((transaction) async {
      final orderRef = _firestore.collection('offers').doc(orderId);
      final orderDoc = await transaction.get(orderRef);

      if (!orderDoc.exists) throw Exception('Ordem não encontrada');

      final data = orderDoc.data() as Map<String, dynamic>;
      if (data['userId'] != userId) throw Exception('Acesso negado');
      if (data['status'] != 'open') throw Exception('Ordem não está mais aberta');

      final type = data['type'];
      final qty = (data['quantity'] as num).toDouble();
      final price = (data['pricePerToken'] as num).toDouble();
      final startupId = data['startupId'];

      if (type == 'buy') {
        // Estornar BRL
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);
        final currentBalance = ((userDoc.data() as Map<String, dynamic>?)?['saldo'] as num?)?.toDouble() ?? 0.0;
        transaction.update(userRef, {
          'saldo': currentBalance + (qty * price),
        });
      } else if (type == 'sell') {
        // Estornar Tokens
        final tokenRef = _firestore
            .collection('startups')
            .doc(startupId)
            .collection('investors')
            .doc(userId);
        final tokenDoc = await transaction.get(tokenRef);
        final currentTokens = ((tokenDoc.data() as Map<String, dynamic>?)?['tokens'] as num?)?.toDouble() ?? 0.0;
        if (!tokenDoc.exists) {
          transaction.set(tokenRef, {'tokens': qty});
        } else {
          transaction.update(tokenRef, {'tokens': currentTokens + qty});
        }
      }

      transaction.update(orderRef, {'status': 'cancelled'});
    });
  }

  Future<void> _matchOrders(String startupId) async {
    // Pegamos ordens abertas para esta startup
    final querySnapshot = await _firestore
        .collection('offers')
        .where('startupId', isEqualTo: startupId)
        .where('status', isEqualTo: 'open')
        .get();

    final docs = querySnapshot.docs;
    
    // Separamos ordens de compra e venda
    final List<QueryDocumentSnapshot> buyOrders = docs.where((doc) => (doc.data() as Map<String, dynamic>)['type'] == 'buy').toList();
    final List<QueryDocumentSnapshot> sellOrders = docs.where((doc) => (doc.data() as Map<String, dynamic>)['type'] == 'sell').toList();

    // Ordenamos compra decrescente (maior preço primeiro, mais antigo primeiro em empate)
    buyOrders.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;
      final priceA = (dataA['pricePerToken'] as num).toDouble();
      final priceB = (dataB['pricePerToken'] as num).toDouble();
      if (priceA != priceB) return priceB.compareTo(priceA);
      
      final timeA = (dataA['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      final timeB = (dataB['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      return timeA.compareTo(timeB);
    });

    // Ordenamos venda crescente (menor preço primeiro, mais antigo primeiro em empate)
    sellOrders.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;
      final priceA = (dataA['pricePerToken'] as num).toDouble();
      final priceB = (dataB['pricePerToken'] as num).toDouble();
      if (priceA != priceB) return priceA.compareTo(priceB);

      final timeA = (dataA['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      final timeB = (dataB['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      return timeA.compareTo(timeB);
    });

    // Tentamos fazer match usando transações no Firestore para manter a consistência
    for (var buyDoc in buyOrders) {
      for (var sellDoc in sellOrders) {
        // Se a ordem já foi atualizada na memória ou os preços não cruzam, continuamos
        final buyData = buyDoc.data() as Map<String, dynamic>;
        final sellData = sellDoc.data() as Map<String, dynamic>;
        var buyPrice = (buyData['pricePerToken'] as num).toDouble();
        var sellPrice = (sellData['pricePerToken'] as num).toDouble();

        if (buyPrice >= sellPrice) {
          // Os preços cruzam!
          // Executamos uma transação para esse match para evitar concorrência
          bool matchSuccess = await _executeMatchTransaction(buyDoc.id, sellDoc.id, startupId);
          if (matchSuccess) {
            // Recarregamos a lista e começamos de novo para simplificar o loop, 
            // ou poderíamos atualizar em memória. Vamos simplificar chamando _matchOrders recursivamente
            // até esgotar os matches.
            return _matchOrders(startupId);
          }
        }
      }
    }
  }

  Future<bool> _executeMatchTransaction(String buyOrderId, String sellOrderId, String startupId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final buyRef = _firestore.collection('offers').doc(buyOrderId);
        final sellRef = _firestore.collection('offers').doc(sellOrderId);

        final buySnap = await transaction.get(buyRef);
        final sellSnap = await transaction.get(sellRef);

        if (!buySnap.exists || !sellSnap.exists) throw Exception('Ordem não existe');
        
        final buyData = buySnap.data() as Map<String, dynamic>;
        final sellData = sellSnap.data() as Map<String, dynamic>;

        if (buyData['status'] != 'open' || sellData['status'] != 'open') {
          throw Exception('Ordens já foram executadas ou canceladas');
        }

        final buyQty = (buyData['quantity'] as num).toDouble();
        final sellQty = (sellData['quantity'] as num).toDouble();
        final buyPrice = (buyData['pricePerToken'] as num).toDouble();
        final sellPrice = (sellData['pricePerToken'] as num).toDouble();

        if (buyPrice < sellPrice) throw Exception('Preços não cruzam mais');

        // Preço de execução é o preço da ordem mais antiga na fila (criador do mercado)
        final buyTime = (buyData['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        final sellTime = (sellData['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        
        final executionPrice = (buyTime <= sellTime) ? buyPrice : sellPrice;
        final executionQty = min(buyQty, sellQty);

        // Atualizar saldos dos usuários
        final buyerId = buyData['userId'];
        final sellerId = sellData['userId'];

        // Se executionPrice < buyPrice, precisamos devolver a diferença para o comprador
        if (executionPrice < buyPrice) {
          final buyerRef = _firestore.collection('users').doc(buyerId);
          final buyerDoc = await transaction.get(buyerRef);
          final currentBuyerBalance = ((buyerDoc.data() as Map<String, dynamic>?)?['saldo'] as num?)?.toDouble() ?? 0.0;
          final diff = (buyPrice - executionPrice) * executionQty;
          transaction.update(buyerRef, {'saldo': currentBuyerBalance + diff});
        }

        // Vendedor recebe BRL
        final sellerUserRef = _firestore.collection('users').doc(sellerId);
        final sellerUserDoc = await transaction.get(sellerUserRef);
        final currentSellerBalance = ((sellerUserDoc.data() as Map<String, dynamic>?)?['saldo'] as num?)?.toDouble() ?? 0.0;
        transaction.update(sellerUserRef, {
          'saldo': currentSellerBalance + (executionPrice * executionQty)
        });

        // Comprador recebe Tokens
        final buyerTokenRef = _firestore
            .collection('startups')
            .doc(startupId)
            .collection('investors')
            .doc(buyerId);
        final buyerTokenDoc = await transaction.get(buyerTokenRef);
        final currentBuyerTokens = ((buyerTokenDoc.data() as Map<String, dynamic>?)?['tokens'] as num?)?.toDouble() ?? 0.0;
        if (!buyerTokenDoc.exists) {
          transaction.set(buyerTokenRef, {'tokens': executionQty});
        } else {
          transaction.update(buyerTokenRef, {'tokens': currentBuyerTokens + executionQty});
        }

        // Atualizar ordens
        if (buyQty == executionQty) {
          transaction.update(buyRef, {'status': 'executada', 'quantity': 0});
        } else {
          transaction.update(buyRef, {'quantity': buyQty - executionQty});
        }

        if (sellQty == executionQty) {
          transaction.update(sellRef, {'status': 'executada', 'quantity': 0});
        } else {
          transaction.update(sellRef, {'quantity': sellQty - executionQty});
        }

        // Opcional: Atualizar preço atual da startup com o valor da última negociação
        final startupRef = _firestore.collection('startups').doc(startupId);
        transaction.update(startupRef, {'currentTokenPriceCents': (executionPrice * 100).toInt()});
      });
      return true; // Match bem-sucedido
    } catch (e) {
      return false; // Match falhou (provavelmente outra thread já processou)
    }
  }
}
