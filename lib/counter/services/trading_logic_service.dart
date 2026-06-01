// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

// Serviço puro de lógica de trading.
// Funciona como o motor de um Home Broker: recebe ordens, processa na carteira
// e tenta cruzar compra com venda (o famoso matching).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesclainvest_f/model/offerModel.dart';
import 'dart:math';

/// Engine do mercado secundário. Cuida de toda a matemática financeira e
/// consistência de banco de dados na hora de trocar tokens entre usuários.
class TradingLogicService {
  // Instância do banco. É a nossa ponte direta com os dados.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Publica uma nova ordem de COMPRA no book.
  /// Trava o saldo em R$ do investidor pra garantir que ele tem como pagar.
  Future<void> placeBuyOrder({
    required String userId,
    required String startupId,
    required String startupNome,
    required double qty,
    required double price,
  }) async {
    // Usamos transação do Firestore. É um bloco atômico: ou tudo dá certo, ou tudo é desfeito.
    // Assim não corremos risco do cara gastar o dinheiro e a ordem não ser criada.
    await _firestore.runTransaction((transaction) async {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await transaction.get(userRef);

      // Segurança em primeiro lugar: se não achou o usuário, aborta.
      if (!userDoc.exists) throw Exception('Usuário não encontrado');

      final dataMap = userDoc.data() as Map<String, dynamic>?;
      // Pega o saldo. Se vier nulo, assume 0 pra não crashar.
      final currentBalance = (dataMap?['saldo'] as num?)?.toDouble() ?? 0.0;
      // Calcula o custo total: Quantidade × Preço
      final requiredBalance = qty * price;

      // O cheque especial aqui não existe.
      if (currentBalance < requiredBalance) {
        throw Exception(
          'Saldo insuficiente para realizar esta ordem de compra',
        );
      }

      // Desconta o dinheiro da conta. O valor fica "preso" na ordem.
      transaction.update(userRef, {'saldo': currentBalance - requiredBalance});

      // Cria a boleta de compra.
      final newOrderRef = _firestore.collection('offers').doc();
      final newOrder = {
        'userId': userId,
        'startupId': startupId,
        'startupNome': startupNome,
        'type': 'buy',
        'quantity': qty,
        'pricePerToken': price,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(), // Usa a hora do servidor pra não ter treta de fuso horário.
      };
      // Salva a ordem no banco atrelada a transação.
      transaction.set(newOrderRef, newOrder);
    });

    // Ordem criada com sucesso! Agora roda a roleta pra ver se já dá match com alguma venda.
    await _matchOrders(startupId);
  }

  /// Publica uma ordem de VENDA no book.
  /// Trava os tokens do investidor pra garantir que ele não venda 2x.
  Future<void> placeSellOrder({
    required String userId,
    required String startupId,
    required String startupNome,
    required double qty,
    required double price,
  }) async {
    await _firestore.runTransaction((transaction) async {
      // Caminho legado pra buscar os tokens do investidor naquela startup.
      final tokenRef = _firestore
          .collection('startups')
          .doc(startupId)
          .collection('investors')
          .doc(userId);

      final tokenDoc = await transaction.get(tokenRef);

      if (!tokenDoc.exists)
        throw Exception('Você não possui tokens desta startup');

      final dataMap = tokenDoc.data() as Map<String, dynamic>?;
      final currentTokens = (dataMap?['tokens'] as num?)?.toDouble() ?? 0.0;

      // Valida se o cara não tá operando vendido a descoberto (Short não permitido aqui).
      if (currentTokens < qty) {
        throw Exception(
          'Tokens insuficientes para realizar esta ordem de venda',
        );
      }

      // Retira os tokens da carteira do usuário.
      transaction.update(tokenRef, {'tokens': currentTokens - qty});

      // Gera a boleta de venda.
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

    // Manda pro matching pra ver se encontra comprador na hora.
    await _matchOrders(startupId);
  }

  /// Cancela uma ordem e devolve o ativo (R$ ou Token) pro dono.
  Future<void> cancelOrder(String orderId, String userId) async {
    await _firestore.runTransaction((transaction) async {
      final orderRef = _firestore.collection('offers').doc(orderId);
      final orderDoc = await transaction.get(orderRef);

      // Ordem fantasma? Rejeita.
      if (!orderDoc.exists) throw Exception('Ordem não encontrada');

      final data = orderDoc.data() as Map<String, dynamic>;
      // Proteção contra hacker querendo cancelar ordem dos outros.
      if (data['userId'] != userId) throw Exception('Acesso negado');
      // Só dá pra cancelar se tiver aberta.
      if (data['status'] != 'open')
        throw Exception('Ordem não está mais aberta');

      // Puxa as propriedades da ordem pra saber o que devolver.
      final type = data['type'];
      final qty = (data['quantity'] as num).toDouble();
      final price = (data['pricePerToken'] as num).toDouble();
      final startupId = data['startupId'];

      if (type == 'buy') {
        // Estorno de COMPRA: Devolve os Reais (BRL).
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);
        final currentBalance =
            ((userDoc.data() as Map<String, dynamic>?)?['saldo'] as num?)
                ?.toDouble() ??
            0.0;
        transaction.update(userRef, {'saldo': currentBalance + (qty * price)});
      } else if (type == 'sell') {
        // Estorno de VENDA: Devolve os Tokens pra carteira.
        final tokenRef = _firestore
            .collection('startups')
            .doc(startupId)
            .collection('investors')
            .doc(userId);
        final tokenDoc = await transaction.get(tokenRef);
        final currentTokens =
            ((tokenDoc.data() as Map<String, dynamic>?)?['tokens'] as num?)
                ?.toDouble() ??
            0.0;
        // Se a carteira dele de tokens não existia mais, recria.
        if (!tokenDoc.exists) {
          transaction.set(tokenRef, {'tokens': qty});
        } else {
          // Senão só soma os tokens de volta.
          transaction.update(tokenRef, {'tokens': currentTokens + qty});
        }
      }

      // Muda o status da ordem pra cancelada.
      transaction.update(orderRef, {'status': 'cancelled'});
    });
  }

  /// Puxa o book inteiro da startup e tenta encontrar pares perfeitos (Matches).
  Future<void> _matchOrders(String startupId) async {
    // Traz todas as ordens em aberto dessa startup.
    final querySnapshot = await _firestore
        .collection('offers')
        .where('startupId', isEqualTo: startupId)
        .where('status', isEqualTo: 'open')
        .get();

    final docs = querySnapshot.docs;

    // Filtra e divide: de um lado quem quer comprar, do outro quem quer vender.
    final List<QueryDocumentSnapshot> buyOrders = docs
        .where((doc) => (doc.data() as Map<String, dynamic>)['type'] == 'buy')
        .toList();
    final List<QueryDocumentSnapshot> sellOrders = docs
        .where((doc) => (doc.data() as Map<String, dynamic>)['type'] == 'sell')
        .toList();

    // Ordenação de COMPRA: Maior lance no topo (Decrescente). Se empatar, o mais antigo leva.
    buyOrders.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;
      final priceA = (dataA['pricePerToken'] as num).toDouble();
      final priceB = (dataB['pricePerToken'] as num).toDouble();
      if (priceA != priceB) return priceB.compareTo(priceA);

      final timeA =
          (dataA['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      final timeB =
          (dataB['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      return timeA.compareTo(timeB); // Crescente = mais velho primeiro.
    });

    // Ordenação de VENDA: Menor lance no topo (Crescente). Se empatar, o mais antigo leva.
    sellOrders.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;
      final priceA = (dataA['pricePerToken'] as num).toDouble();
      final priceB = (dataB['pricePerToken'] as num).toDouble();
      if (priceA != priceB) return priceA.compareTo(priceB);

      final timeA =
          (dataA['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      final timeB =
          (dataB['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      return timeA.compareTo(timeB);
    });

    // O loop duplo da morte: tenta casar todo mundo da fila.
    for (var buyDoc in buyOrders) {
      for (var sellDoc in sellOrders) {
        final buyData = buyDoc.data() as Map<String, dynamic>;
        final sellData = sellDoc.data() as Map<String, dynamic>;
        var buyPrice = (buyData['pricePerToken'] as num).toDouble();
        var sellPrice = (sellData['pricePerToken'] as num).toDouble();

        // Condição mágica do mercado: Comprador tá disposto a pagar igual ou mais caro do que o vendedor tá pedindo.
        if (buyPrice >= sellPrice) {
          // Deu Match! Dispara a transação atômica.
          bool matchSuccess = await _executeMatchTransaction(
            buyDoc.id,
            sellDoc.id,
            startupId,
          );
          if (matchSuccess) {
            // Se fechou negócio, os books mudaram. Cancela o loop e começa de novo limpo.
            // É a forma mais segura de evitar inconsistência de dados (gambiarra genial).
            return _matchOrders(startupId);
          }
        }
      }
    }
  }

  /// Executa o aperto de mão financeiro (Match). Troca os ativos entre o Comprador e o Vendedor.
  Future<bool> _executeMatchTransaction(
    String buyOrderId,
    String sellOrderId,
    String startupId,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final buyRef = _firestore.collection('offers').doc(buyOrderId);
        final sellRef = _firestore.collection('offers').doc(sellOrderId);

        // Faz o GET pra garantir que tá com a versão mais recente dos docs.
        final buySnap = await transaction.get(buyRef);
        final sellSnap = await transaction.get(sellRef);

        if (!buySnap.exists || !sellSnap.exists)
          throw Exception('Ordem não existe');

        final buyData = buySnap.data() as Map<String, dynamic>;
        final sellData = sellSnap.data() as Map<String, dynamic>;

        // Validação defensiva: vai que alguém cancelou no milisegundo anterior.
        if (buyData['status'] != 'open' || sellData['status'] != 'open') {
          throw Exception('Ordens já foram executadas ou canceladas');
        }

        final buyQty = (buyData['quantity'] as num).toDouble();
        final sellQty = (sellData['quantity'] as num).toDouble();
        final buyPrice = (buyData['pricePerToken'] as num).toDouble();
        final sellPrice = (sellData['pricePerToken'] as num).toDouble();

        if (buyPrice < sellPrice) throw Exception('Preços não cruzam mais');

        // A regra de preço de bolsa: Quem chegou primeiro (Maker) dita o preço da negociação.
        final buyTime =
            (buyData['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        final sellTime =
            (sellData['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;

        final executionPrice = (buyTime <= sellTime) ? buyPrice : sellPrice;
        
        // A quantidade executada é o que eles têm em comum (o menor dos dois).
        final executionQty = min(buyQty, sellQty);

        final buyerId = buyData['userId'];
        final sellerId = sellData['userId'];

        // Se o preço de execução for MENOR que o que o comprador propôs, devolvemos o troco pra ele.
        // Lembra que travamos o total (buyQty * buyPrice) lá no placeBuyOrder.
        if (executionPrice < buyPrice) {
          final buyerRef = _firestore.collection('users').doc(buyerId);
          final buyerDoc = await transaction.get(buyerRef);
          final currentBuyerBalance =
              ((buyerDoc.data() as Map<String, dynamic>?)?['saldo'] as num?)
                  ?.toDouble() ??
              0.0;
          final diff = (buyPrice - executionPrice) * executionQty;
          transaction.update(buyerRef, {'saldo': currentBuyerBalance + diff});
        }

        // Paga o vendedor! Injete R$ na conta dele.
        final sellerUserRef = _firestore.collection('users').doc(sellerId);
        final sellerUserDoc = await transaction.get(sellerUserRef);
        final currentSellerBalance =
            ((sellerUserDoc.data() as Map<String, dynamic>?)?['saldo'] as num?)
                ?.toDouble() ??
            0.0;
        transaction.update(sellerUserRef, {
          'saldo': currentSellerBalance + (executionPrice * executionQty),
        });

        // Entrega os tokens pro comprador!
        final buyerTokenRef = _firestore
            .collection('startups')
            .doc(startupId)
            .collection('investors')
            .doc(buyerId);
        final buyerTokenDoc = await transaction.get(buyerTokenRef);
        final currentBuyerTokens =
            ((buyerTokenDoc.data() as Map<String, dynamic>?)?['tokens'] as num?)
                ?.toDouble() ??
            0.0;
        if (!buyerTokenDoc.exists) {
          transaction.set(buyerTokenRef, {'tokens': executionQty});
        } else {
          transaction.update(buyerTokenRef, {
            'tokens': currentBuyerTokens + executionQty,
          });
        }

        // Abate a quantidade executada das ordens. Se zerou, muda pra 'executada'.
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

        // Atualiza a cotação global da startup com base no último negócio fechado!
        // Isso é o que move o gráfico pra cima e pra baixo no app.
        final startupRef = _firestore.collection('startups').doc(startupId);
        transaction.update(startupRef, {
          'currentTokenPriceCents': (executionPrice * 100).toInt(),
        });
      });
      return true; // Sucesso total
    } catch (e) {
      return false; // Falhou, provável concorrência do Firestore. Retorna false pra ignorar e tentar depois.
    }
  }
}
