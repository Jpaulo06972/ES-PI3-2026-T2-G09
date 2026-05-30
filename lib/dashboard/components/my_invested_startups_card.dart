import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';
import 'package:mesclainvest_f/startups/pages/startupsDetails.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/wallet/services/getListOperation.dart';

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
  List<Map<String, dynamic>>? _operations;

  @override
  void initState() {
    super.initState();
    _loadOperations();
  }

  Future<void> _loadOperations() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? widget.userModel.uid;
    try {
      final ops = await GetListOperation().getOperations(userId: userId);
      if (mounted) {
        setState(() {
          _operations = ops;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _operations = [];
        });
      }
    }
  }

  double _calculateAvgPurchasePrice(String startupId, int totalTokensOwned) {
    if (_operations == null || _operations!.isEmpty || totalTokensOwned <= 0) return 0.0;
    
    final userId = FirebaseAuth.instance.currentUser?.uid ?? widget.userModel.uid;
    double totalSpent = 0.0;

    for (var op in _operations!) {
      final type = op['type'] ?? op['operation'] ?? op['typeOfOperation'] ?? '';
      final sId = op['startupId']?.toString();
      
      if (sId == startupId) {
        bool isBuyer = (op['buyerId'] == userId) || 
                       (type == 'buy_from_startup' && (op['authorUid'] == userId || op['authorID'] == userId)) ||
                       (type == 'investimento' && (op['authorUid'] == userId || op['authorID'] == userId)) ||
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
    final userId = FirebaseAuth.instance.currentUser?.uid ?? widget.userModel.uid;

    if (_operations == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: Color(0xFF1A9B5F)),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('holdings')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: Color(0xFF1A9B5F)),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorContainer('Erro ao carregar seus investimentos.');
        }

        final holdingsDocs = snapshot.data?.docs ?? [];
        // Filtrar holdings com quantidade > 0
        final activeHoldings = holdingsDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final qty = (data['quantity'] as num?)?.toDouble() ?? 0.0;
          return qty > 0;
        }).toList();

        if (activeHoldings.isEmpty) {
          return _buildEmptyContainer();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: activeHoldings.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final startupId = data['startupId'] ?? '';
              final qty = (data['quantity'] as num?)?.toInt() ?? 0;
              
              double avgPrice = _calculateAvgPurchasePrice(startupId, qty);
              if (avgPrice <= 0) {
                 avgPrice = ((data['averagePriceCents'] as num?)?.toDouble() ?? 0.0) / 100.0;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _HoldingCardItem(
                  holdingData: data,
                  userModel: widget.userModel,
                  isVisible: widget.isVisible,
                  calculatedAvgPrice: avgPrice,
                ),
              );
            }).toList(),
          ),
        );
      },
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

        final currentPrice = (startupData['currentPrice'] as num?)?.toDouble() ?? 
                             (((startupData['currentTokenPriceCents'] as num?)?.toInt() ?? 100) / 100.0);

        final double percentageChange;
        if (calculatedAvgPrice > 0) {
          percentageChange = ((currentPrice - calculatedAvgPrice) / calculatedAvgPrice) * 100.0;
        } else {
          percentageChange = 0.0;
        }

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
                            ? CurrencyInputFormatter.formatValue(currentPrice * qty)
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
