import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/startups/components/startup_colors.dart';

class PlaceBuyOfferSheet extends StatefulWidget {
  final String startupId;
  final String startupName;
  final UserModel userModel;
  final double currentMarketPrice;
  final String type; // 'buy' or 'sell'

  const PlaceBuyOfferSheet({
    super.key,
    required this.startupId,
    required this.startupName,
    required this.userModel,
    required this.currentMarketPrice,
    required this.type,
  });

  @override
  State<PlaceBuyOfferSheet> createState() => _PlaceBuyOfferSheetState();
}

class _PlaceBuyOfferSheetState extends State<PlaceBuyOfferSheet> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _priceCtrl = TextEditingController();

  double _qty = 10;
  double _price = 0.0;
  bool _isSubmitting = false;
  String? _errorMessage;
  double _availableBalance = 0.0;
  double _availableTokens = 0.0;
  bool _isLoadingLimits = true;

  @override
  void initState() {
    super.initState();
    _price = widget.currentMarketPrice;
    _priceCtrl.text = _price.toStringAsFixed(2).replaceAll('.', ',');
    _loadUserLimits();
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserLimits() async {
    setState(() => _isLoadingLimits = true);
    try {
      // 1. Carrega saldo de BRL do usuário do Firestore
      final userDoc = await _firestore.collection('users').doc(widget.userModel.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        _availableBalance = (data['saldo'] ?? data['balance'] ?? 0.0).toDouble();
      } else {
        _availableBalance = widget.userModel.saldo;
      }

      // 2. Carrega quantidade de tokens da startup — coleção top-level `holdings`
      //    (com fallback para subcoleção legada `investors`).
      final holdingDoc = await _firestore
          .collection('holdings')
          .doc('${widget.userModel.uid}_${widget.startupId}')
          .get();
      if (holdingDoc.exists) {
        _availableTokens = (holdingDoc.data()?['quantity'] as num?)?.toDouble() ?? 0.0;
      } else {
        final investorDoc = await _firestore
            .collection('startups')
            .doc(widget.startupId)
            .collection('investors')
            .doc(widget.userModel.uid)
            .get();
        _availableTokens = investorDoc.exists
            ? ((investorDoc.data()?['tokens'] as num?)?.toDouble() ?? 0.0)
            : 0.0;
      }

      if (mounted) {
        setState(() => _isLoadingLimits = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _availableBalance = widget.userModel.saldo;
          _availableTokens = 0.0;
          _isLoadingLimits = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double totalCost = _qty * _price;
    final bool isBuy = widget.type == 'buy';
    final bool hasLimits = isBuy
        ? _availableBalance >= totalCost
        : _availableTokens >= _qty;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: StartupColors.pageBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.startupName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isBuy ? 'ENVIAR OFERTA DE COMPRA' : 'ENVIAR OFERTA DE VENDA',
                          style: TextStyle(
                            color: isBuy ? StartupColors.green : const Color(0xFFE74C3C),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Reference price
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF141416),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Preço de mercado atual:',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                    Text(
                      'R\$ ${widget.currentMarketPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stepper for quantity
              const Text(
                'Quantidade de tokens',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141416),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isBuy ? StartupColors.green.withOpacity(0.3) : const Color(0xFFE74C3C).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    _buildStepBtn(
                      icon: Icons.remove,
                      onTap: () {
                        if (_qty > 1) setState(() => _qty--);
                      },
                    ),
                    Expanded(
                      child: Text(
                        _qty.toInt().toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _buildStepBtn(
                      icon: Icons.add,
                      onTap: () {
                        setState(() => _qty++);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Custom price per token input
              const Text(
                'Preço por token (R\$)',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141416),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isBuy ? StartupColors.green.withOpacity(0.3) : const Color(0xFFE74C3C).withOpacity(0.3),
                  ),
                ),
                child: TextField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    prefixText: 'R\$ ',
                    prefixStyle: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  onChanged: (val) {
                    final cleanVal = val.replaceAll(',', '.');
                    setState(() {
                      _price = double.tryParse(cleanVal) ?? 0.0;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Summary card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141416),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      isBuy ? 'Total da oferta (reservado)' : 'Total estimado a receber',
                      'R\$ ${totalCost.toStringAsFixed(2).replaceAll('.', ',')}',
                      highlight: true,
                    ),
                    const SizedBox(height: 10),
                    if (_isLoadingLimits)
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: StartupColors.green),
                      )
                    else
                      _buildSummaryRow(
                        isBuy ? 'Saldo disponível' : 'Tokens disponíveis',
                        isBuy
                            ? 'R\$ ${_availableBalance.toStringAsFixed(2).replaceAll('.', ',')}'
                            : '${_availableTokens.toInt()} tokens',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (!_isLoadingLimits && !hasLimits)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFE74C3C), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        isBuy ? 'Saldo disponível insuficiente.' : 'Participação de tokens insuficiente.',
                        style: const TextStyle(color: Color(0xFFE74C3C), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFE74C3C), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFE74C3C), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Enviar oferta button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasLimits && _price > 0 && !_isSubmitting
                        ? (isBuy ? StartupColors.green : const Color(0xFFE74C3C))
                        : Colors.white12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: hasLimits && _price > 0 && !_isSubmitting ? _submitOffer : null,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Enviar Oferta',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 54,
        height: 54,
        alignment: Alignment.center,
        child: Icon(icon, color: widget.type == 'buy' ? StartupColors.green : const Color(0xFFE74C3C), size: 22),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: highlight ? (widget.type == 'buy' ? StartupColors.green : const Color(0xFFE74C3C)) : Colors.white,
            fontSize: 14,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _submitOffer() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final String currentUserId = widget.userModel.uid;
    final String startupId = widget.startupId;
    final double quantity = _qty;
    final double pricePerToken = _price;
    final double total = quantity * pricePerToken;
    final String type = widget.type;

    try {
      // 1. Busca ofertas opostas ativas (status == 'open') com o MESMO preço do Firestore de forma síncrona/prévia
      final oppositeOffersQuery = await _firestore.collection('offers')
          .where('startupId', isEqualTo: startupId)
          .where('type', isEqualTo: type == 'buy' ? 'sell' : 'buy')
          .where('status', isEqualTo: 'open')
          .where('pricePerToken', isEqualTo: pricePerToken)
          .orderBy('timestamp', descending: false)
          .get();

      final candidates = oppositeOffersQuery.docs;

      // 2. Executa a transação atômica
      await _firestore.runTransaction((transaction) async {
        // A. Carrega saldos do usuário logado na transação para garantir consistência
        final userRef = _firestore.collection('users').doc(currentUserId);
        final userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) throw Exception("Sua conta de usuário não foi encontrada.");

        final userData = userSnapshot.data()!;
        final double userBrlBalance = (userData['saldo'] ?? userData['balance'] ?? 0.0).toDouble();

        final investorRef = _firestore
            .collection('startups')
            .doc(startupId)
            .collection('investors')
            .doc(currentUserId);
        final investorSnapshot = await transaction.get(investorRef);

        // Coleção top-level `holdings` é a fonte primária para a quantidade de tokens
        final ownHoldingRef = _firestore
            .collection('holdings')
            .doc('${currentUserId}_$startupId');
        final ownHoldingSnap = await transaction.get(ownHoldingRef);
        final double legacyTokens = investorSnapshot.exists
            ? ((investorSnapshot.data()!['tokens'] as num?)?.toDouble() ?? 0.0)
            : 0.0;
        double userTokenHolding = ownHoldingSnap.exists
            ? ((ownHoldingSnap.data()?['quantity'] as num?)?.toDouble() ?? 0.0)
            : legacyTokens;

        // B. Valida limites de BRL / tokens
        if (type == 'buy') {
          if (userBrlBalance < total) {
            throw Exception("Saldo insuficiente para esta compra.");
          }
        } else {
          if (userTokenHolding < quantity) {
            throw Exception("Insufficient tokens");
          }
        }

        // C. Prepara novos documentos e variáveis
        final newOfferRef = _firestore.collection('offers').doc();
        double ourRemainingQty = quantity;

        // D. Executa motor de matching greedy/linear
        for (final candidate in candidates) {
          if (ourRemainingQty <= 0) break;

          final candSnapshot = await transaction.get(candidate.reference);
          if (!candSnapshot.exists) continue;

          final candData = candSnapshot.data()!;
          if (candData['status'] != 'open') continue;

          final double candRemaining = (candData['remainingQuantity'] ?? candData['quantity'] ?? 0.0).toDouble();
          if (candRemaining <= 0) continue;

          // Evita comprar de si mesmo
          final String candUserId = candData['userId'] ?? '';
          if (candUserId == currentUserId) continue;

          final double matchQty = min(ourRemainingQty, candRemaining);
          if (matchQty <= 0) continue;

          // Atualiza a oferta do candidato
          final double newCandRemaining = candRemaining - matchQty;
          transaction.update(candidate.reference, {
            'remainingQuantity': newCandRemaining,
            'status': newCandRemaining <= 0 ? 'filled' : 'open',
          });

          // Transfere BRL e tokens
          final candUserRef = _firestore.collection('users').doc(candUserId);
          final candInvestorRef = _firestore
              .collection('startups')
              .doc(startupId)
              .collection('investors')
              .doc(candUserId);
          final candHoldingRef = _firestore
              .collection('holdings')
              .doc('${candUserId}_$startupId');

          final candUserSnapshot = await transaction.get(candUserRef);
          final candInvestorSnapshot = await transaction.get(candInvestorRef);
          final candHoldingSnap = await transaction.get(candHoldingRef);

          final double candBrl = candUserSnapshot.exists
              ? (candUserSnapshot.data()!['saldo'] ?? candUserSnapshot.data()!['balance'] ?? 0.0).toDouble()
              : 0.0;
          final double legacyCandTokens = candInvestorSnapshot.exists
              ? ((candInvestorSnapshot.data()!['tokens'] as num?)?.toDouble() ?? 0.0)
              : 0.0;
          final double candHoldingQty = candHoldingSnap.exists
              ? ((candHoldingSnap.data()?['quantity'] as num?)?.toDouble() ?? 0.0)
              : legacyCandTokens;
          final double candHoldingAvgCents = candHoldingSnap.exists
              ? ((candHoldingSnap.data()?['averagePriceCents'] as num?)?.toDouble() ?? 0.0)
              : 0.0;

          if (type == 'buy') {
            // Nós somos o Comprador (currentUserId), Candidato é o Vendedor (candUserId)
            // Candidato recebe BRL:
            final double newCandBrl = candBrl + (matchQty * pricePerToken);
            transaction.update(candUserRef, {
              'saldo': newCandBrl,
              'balance': newCandBrl,
            });

            // Vendedor candidato perde tokens na coleção top-level `holdings`
            final double newCandHoldingQty = candHoldingQty - matchQty;
            transaction.set(
              candHoldingRef,
              {
                'userId': candUserId,
                'startupId': startupId,
                'quantity': newCandHoldingQty <= 0 ? 0 : newCandHoldingQty,
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );

            // Vendedor candidato decrementa na subcoleção legada `investors` (se existir)
            if (candInvestorSnapshot.exists) {
              final double remainingLegacy = legacyCandTokens - matchQty;
              if (remainingLegacy <= 0) {
                transaction.delete(candInvestorRef);
              } else {
                transaction.update(candInvestorRef, {
                  'tokens': remainingLegacy,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
              }
            }

            // Nós recebemos tokens:
            userTokenHolding += matchQty;
          } else {
            // Nós somos o Vendedor (currentUserId), Candidato é o Comprador (candUserId)
            // Comprador candidato ganha tokens — subcoleção investors (retrocompat)
            final double newCandTokens = legacyCandTokens + matchQty;
            transaction.set(candInvestorRef, {
              'userId': candUserId,
              'startupId': startupId,
              'tokens': newCandTokens,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            // Comprador candidato — coleção top-level `holdings` (preço médio ponderado)
            final double newCandHoldingQty = candHoldingQty + matchQty;
            final double newCandAvgCents = newCandHoldingQty > 0
                ? (candHoldingQty * candHoldingAvgCents +
                        matchQty * (pricePerToken * 100)) /
                    newCandHoldingQty
                : 0.0;
            transaction.set(
              candHoldingRef,
              {
                'userId': candUserId,
                'startupId': startupId,
                'quantity': newCandHoldingQty,
                'averagePriceCents': newCandAvgCents.round(),
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
          }

          ourRemainingQty -= matchQty;
        }

        // E. Atualizações do usuário logado final pós loop
        if (type == 'buy') {
          // Debita o saldo BRL do comprador (nós)
          final double nextUserBrl = userBrlBalance - total;
          transaction.update(userRef, {
            'saldo': nextUserBrl,
            'balance': nextUserBrl,
          });

          // Atualiza as holdings de tokens do comprador (nós) — subcoleção legada
          transaction.set(investorRef, {
            'userId': currentUserId,
            'startupId': startupId,
            'tokens': userTokenHolding,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          // Coleção top-level `holdings` — preço médio ponderado pelas porções casadas
          final double prevOwnQty = ownHoldingSnap.exists
              ? ((ownHoldingSnap.data()?['quantity'] as num?)?.toDouble() ?? 0.0)
              : 0.0;
          final double prevOwnAvgCents = ownHoldingSnap.exists
              ? ((ownHoldingSnap.data()?['averagePriceCents'] as num?)?.toDouble() ?? 0.0)
              : 0.0;
          final double addedQty = userTokenHolding - prevOwnQty;
          final double newOwnAvgCents = userTokenHolding > 0
              ? (prevOwnQty * prevOwnAvgCents +
                      (addedQty > 0 ? addedQty : 0) * (pricePerToken * 100)) /
                  userTokenHolding
              : 0.0;
          transaction.set(
            ownHoldingRef,
            {
              'userId': currentUserId,
              'startupId': startupId,
              'quantity': userTokenHolding,
              'averagePriceCents': newOwnAvgCents.round(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        } else {
          // Debita os tokens do vendedor (nós) — subcoleção legada
          final double nextUserTokensLegacy = legacyTokens - quantity;
          if (investorSnapshot.exists) {
            if (nextUserTokensLegacy <= 0) {
              transaction.delete(investorRef);
            } else {
              transaction.update(investorRef, {
                'tokens': nextUserTokensLegacy,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }

          // Coleção top-level `holdings` — decrementa
          final double nextOwnHoldingQty = userTokenHolding - quantity;
          transaction.set(
            ownHoldingRef,
            {
              'userId': currentUserId,
              'startupId': startupId,
              'quantity': nextOwnHoldingQty <= 0 ? 0 : nextOwnHoldingQty,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          // Credita o BRL do vendedor pelas frações casadas
          final double matchedQty = quantity - ourRemainingQty;
          if (matchedQty > 0) {
            final double nextUserBrl = userBrlBalance + (matchedQty * pricePerToken);
            transaction.update(userRef, {
              'saldo': nextUserBrl,
              'balance': nextUserBrl,
            });
          }
        }

        // F. Salva o documento da nossa oferta (coleção `offers`)
        transaction.set(newOfferRef, {
          'userId': currentUserId,
          'startupId': startupId,
          'quantity': quantity,
          'remainingQuantity': ourRemainingQty,
          'pricePerToken': pricePerToken,
          'pricePerTokenCents': (pricePerToken * 100).round(),
          'total': total,
          'totalCents': (total * 100).round(),
          'type': type,
          'status': ourRemainingQty <= 0 ? 'filled' : 'open',
          'createdAt': FieldValue.serverTimestamp(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      final String message = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _errorMessage = message;
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFE74C3C),
            content: Text(message),
          ),
        );
      }
    }
  }
}
