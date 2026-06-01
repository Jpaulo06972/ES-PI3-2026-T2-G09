// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';
import 'package:mesclainvest_f/startups/pages/startupsDetails.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/wallet/services/getListOperation.dart';
import 'package:mesclainvest_f/counter/services/counterService.dart';
import 'package:mesclainvest_f/startups/services/price_simulator.dart';

class MyInvestedStartupsCard extends StatefulWidget {
  final UserModel userModel;
  final bool isVisible;

  const MyInvestedStartupsCard({
    super.key,
    required this.userModel,
    required this.isVisible,
  });

  @override
  State<MyInvestedStartupsCard> createState() => _MyInvestedStartupsCardState();
}

class _MyInvestedStartupsCardState extends State<MyInvestedStartupsCard> {
  StreamSubscription<List<Map<String, dynamic>>>? _operationsSubscription;
  StreamSubscription<QuerySnapshot>? _holdingsSubscription;

  List<Map<String, dynamic>>? _operations;
  List<QueryDocumentSnapshot>? _holdingsDocs;

  bool _isLoadingTokens = true;
  List<Map<String, dynamic>> _finalHoldings = [];

  @override
  void initState() {
    super.initState();
    _listenToOperations();
    _listenToHoldings();
  }

  @override
  void dispose() {
    _operationsSubscription?.cancel();
    _holdingsSubscription?.cancel();
    super.dispose();
  }

  void _listenToHoldings() {
    final userId =
        FirebaseAuth.instance.currentUser?.uid ?? widget.userModel.uid;
    _holdingsSubscription = FirebaseFirestore.instance
        .collection('holdings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen(
          (snap) {
            _holdingsDocs = snap.docs;
            _computeFinalHoldings();
          },
          onError: (e) {
            print('Erro ao escutar holdings: $e');
            _holdingsDocs = [];
            _computeFinalHoldings();
          },
        );
  }

  void _listenToOperations() {
    final userId =
        FirebaseAuth.instance.currentUser?.uid ?? widget.userModel.uid;
    _operationsSubscription = _getCombinedOperationsStream(userId).listen(
      (ops) {
        if (mounted) {
          _operations = ops;
          _computeFinalHoldings();
        }
      },
      onError: (err) {
        print('Erro ao escutar operações: $err');
        if (mounted) {
          _operations = [];
          _computeFinalHoldings();
        }
      },
    );
  }

  Future<void> _computeFinalHoldings() async {
    if (_operations == null || _holdingsDocs == null) return;

    final userId =
        FirebaseAuth.instance.currentUser?.uid ?? widget.userModel.uid;
    final Set<String> startupIds = {};

    for (var op in _operations!) {
      final sId = op['startupId']?.toString();
      if (sId != null && sId.isNotEmpty) {
        startupIds.add(sId);
      }
    }

    for (var doc in _holdingsDocs!) {
      final data = doc.data() as Map<String, dynamic>;
      final sId = data['startupId']?.toString();
      if (sId != null && sId.isNotEmpty) {
        startupIds.add(sId);
      }
    }

    final counterService = CounterService();
    final List<Map<String, dynamic>> newHoldings = [];

    for (var sId in startupIds) {
      final qty = await counterService.getUserTokens(sId);
      if (qty > 0) {
        double avgPrice = _calculateAvgPurchasePrice(sId, qty.toInt());
        if (avgPrice <= 0) {
          // fallback to holding doc if exists
          try {
            final hDoc = _holdingsDocs!.firstWhere(
              (d) => (d.data() as Map<String, dynamic>)['startupId'] == sId,
            );
            avgPrice =
                (((hDoc.data() as Map<String, dynamic>)['averagePriceCents']
                            as num?)
                        ?.toDouble() ??
                    0.0) /
                100.0;
          } catch (e) {}
        }

        // Let's migrate to holdings automatically if not there
        try {
          final hDoc = await FirebaseFirestore.instance
              .collection('holdings')
              .doc('${userId}_$sId')
              .get();
          if (!hDoc.exists ||
              (hDoc.data()?['quantity'] as num?)?.toDouble() == 0.0) {
            await FirebaseFirestore.instance
                .collection('holdings')
                .doc('${userId}_$sId')
                .set({
                  'userId': userId,
                  'authorUid': userId, // For retro-compatibility
                  'startupId': sId,
                  'quantity': qty,
                  'averagePriceCents': (avgPrice * 100).round(),
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                  'migrated': true,
                }, SetOptions(merge: true));
          }
        } catch (e) {}

        newHoldings.add({
          'startupId': sId,
          'quantity': qty,
          'avgPrice': avgPrice,
        });
      }
    }

    if (mounted) {
      setState(() {
        _finalHoldings = newHoldings;
        _isLoadingTokens = false;
      });
    }
  }

  Stream<List<Map<String, dynamic>>> _getCombinedOperationsStream(
    String userId,
  ) {
    final controller = StreamController<List<Map<String, dynamic>>>();
    StreamSubscription? sub;

    void _listenWithQuery(
      Query<Map<String, dynamic>> query, {
      bool clientSideSort = false,
    }) {
      sub = query.snapshots().listen(
        (snap) {
          if (controller.isClosed) return;
          final List<Map<String, dynamic>> list = [];
          for (var doc in snap.docs) {
            final data = doc.data();
            data['id'] = doc.id;
            list.add(data);
          }
          if (clientSideSort) {
            list.sort((a, b) {
              final aTime = a['createdAt'];
              final bTime = b['createdAt'];
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;

              DateTime aDt;
              if (aTime is Timestamp) {
                aDt = aTime.toDate();
              } else if (aTime is String) {
                aDt =
                    DateTime.tryParse(aTime) ??
                    DateTime.fromMillisecondsSinceEpoch(0);
              } else {
                aDt = DateTime.fromMillisecondsSinceEpoch(0);
              }

              DateTime bDt;
              if (bTime is Timestamp) {
                bDt = bTime.toDate();
              } else if (bTime is String) {
                bDt =
                    DateTime.tryParse(bTime) ??
                    DateTime.fromMillisecondsSinceEpoch(0);
              } else {
                bDt = DateTime.fromMillisecondsSinceEpoch(0);
              }

              return aDt.compareTo(bDt);
            });
          }
          controller.add(list);
        },
        onError: (err) {
          if (!controller.isClosed) {
            controller.addError(err);
          }
        },
      );
    }

    Future<void> init() async {
      try {
        final orderedQuery = FirebaseFirestore.instance
            .collection('operations')
            .where('authorUid', isEqualTo: userId)
            .orderBy('createdAt');

        // Test with a get() to see if index is ready
        await orderedQuery.limit(1).get();

        debugPrint(
          '[MyInvestedStartupsCard] Composite index is ready, using orderBy query',
        );
        _listenWithQuery(orderedQuery);
      } catch (e) {
        debugPrint(
          '[MyInvestedStartupsCard] Index not ready, falling back to simple query: $e',
        );
        try {
          final simpleQuery = FirebaseFirestore.instance
              .collection('operations')
              .where('authorUid', isEqualTo: userId);
          _listenWithQuery(simpleQuery, clientSideSort: true);
        } catch (e2) {
          if (!controller.isClosed) {
            controller.addError(e2);
          }
        }
      }
    }

    init();

    controller.onCancel = () {
      sub?.cancel();
    };

    return controller.stream;
  }

  double _calculateAvgPurchasePrice(String startupId, int totalTokensOwned) {
    if (_operations == null || _operations!.isEmpty || totalTokensOwned <= 0)
      return 0.0;

    final userId =
        FirebaseAuth.instance.currentUser?.uid ?? widget.userModel.uid;
    double totalSpent = 0.0;

    for (var op in _operations!) {
      final type = op['type'] ?? op['operation'] ?? op['typeOfOperation'] ?? '';
      final sId = op['startupId']?.toString();

      if (sId == startupId) {
        bool isBuyer =
            (op['buyerId'] == userId) ||
            (type == 'buy_from_startup' &&
                (op['authorUid'] == userId || op['authorID'] == userId)) ||
            (type == 'investimento' &&
                (op['authorUid'] == userId || op['authorID'] == userId)) ||
            (type == 'buy_from_user' && op['buyerId'] == userId);

        if (isBuyer) {
          double amt = 0.0;
          if (op.containsKey('totalCents')) {
            amt = ((op['totalCents'] as num?)?.toDouble() ?? 0.0) / 100.0;
          } else if (op.containsKey('amountCents')) {
            amt = ((op['amountCents'] as num?)?.toDouble() ?? 0.0) / 100.0;
          } else if (op.containsKey('amount')) {
            amt = (op['amount'] as num?)?.toDouble() ?? 0.0;
          } else if (op.containsKey('valor')) {
            amt = (op['valor'] as num?)?.toDouble() ?? 0.0;
          }
          totalSpent += amt;
        }
      }
    }

    return totalSpent / totalTokensOwned;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingTokens) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: Color(0xFF1A9B5F)),
        ),
      );
    }

    if (_finalHoldings.isEmpty) {
      return _buildEmptyContainer();
    }

    final List<Widget> items = _finalHoldings.map((hData) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: _HoldingCardItem(
          holdingData: {
            'startupId': hData['startupId'],
            'quantity': hData['quantity'],
          },
          userModel: widget.userModel,
          isVisible: widget.isVisible,
          calculatedAvgPrice: hData['avgPrice'],
        ),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: items),
    );
  }

  Widget _buildErrorContainer(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: Text(message, style: const TextStyle(color: Colors.white70)),
    );
  }

  Widget _buildEmptyContainer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          'Você ainda não possui investimentos.',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      ),
    );
  }
}

class _HoldingCardItem extends StatelessWidget {
  final Map<String, dynamic> holdingData;
  final UserModel userModel;
  final bool isVisible;
  final double calculatedAvgPrice;

  const _HoldingCardItem({
    required this.holdingData,
    required this.userModel,
    required this.isVisible,
    required this.calculatedAvgPrice,
  });

  @override
  Widget build(BuildContext context) {
    final startupId = holdingData['startupId'] ?? '';
    final qty = (holdingData['quantity'] as num?)?.toDouble() ?? 0.0;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('startups')
          .doc(startupId)
          .snapshots(),
      builder: (context, startupSnap) {
        if (!startupSnap.hasData || !startupSnap.data!.exists) {
          return Container(
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF1A9B5F),
                ),
              ),
            ),
          );
        }

        final startupData = startupSnap.data!.data() as Map<String, dynamic>;
        final nome = startupData['name'] ?? 'Startup';
        final status = startupData['stage'] ?? 'Desconhecido';

        final currentPrice =
            (startupData['currentPrice'] as num?)?.toDouble() ??
            (((startupData['currentTokenPriceCents'] as num?)?.toInt() ?? 100) /
                100.0);

        // Usa a variação em memória; se ainda não houve tick, usa o valor salvo no Firestore
        final double percentageChange =
            PriceSimulatorService.currentChangePct[startupId] ??
            (startupData['lastSimulatorChangePct'] as num?)?.toDouble() ??
            0.0;

        final isPositive = percentageChange >= 0;
        final percentageColor = isPositive
            ? const Color(0xFF1A9B5F)
            : const Color(0xFFE74C3C);
        final percentageIcon = isPositive
            ? Icons.arrow_upward
            : Icons.arrow_downward;

        final storageName = nome.toString().toLowerCase().replaceAll(' ', '-');
        final storagePath = 'startups_images/$storageName.png';

        return Material(
          color: const Color(0xFF2A2A2E),
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StartupsDetails(
                    startupId: startupId,
                    startupName: nome,
                    startupStage: status,
                    userModel: userModel,
                    storagePath: storagePath,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: FutureBuilder<String>(
                      future: FirebaseStorage.instance
                          .ref(storagePath)
                          .getDownloadURL(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1A9B5F),
                              ),
                            ),
                          );
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Center(
                            child: Icon(
                              Icons.business,
                              color: Colors.white24,
                              size: 24,
                            ),
                          );
                        }
                        return Image.network(
                          snapshot.data!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.white24,
                                  size: 24,
                                ),
                              ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Detalhes (Nome e Tokens)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.view_in_ar,
                              color: Colors.white54,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${qty.toInt()} Tokens',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Preço Atual e Variação Percentual
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isVisible
                            ? CurrencyInputFormatter.formatValue(
                                currentPrice * qty,
                              )
                            : 'R\$ ••••',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      isVisible
                          ? Row(
                              children: [
                                Icon(
                                  percentageIcon,
                                  color: percentageColor,
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${percentageChange.abs().toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: percentageColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              '••••',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
