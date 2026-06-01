// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesclainvest_f/counter/services/counterService.dart';

class WealthController extends ChangeNotifier {
  final String userId;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  double cashBalance = 0.0;
  double tokensMarketValue = 0.0;
  double get consolidatedTotal => cashBalance + tokensMarketValue;

  // Valor dos tokens no início da sessão (base para o indicador de variação)
  double _sessionStartTokenValue = 0.0;
  bool _sessionStartRecorded = false;
  bool _baselineSavedOrLoaded = false;

  double get dailyChangeAbs => tokensMarketValue - _sessionStartTokenValue;
  double get dailyChangePct => _sessionStartTokenValue > 0
      ? (dailyChangeAbs / _sessionStartTokenValue) * 100.0
      : 0.0;

  bool isLoading = true;

  StreamSubscription? _userSub;
  StreamSubscription? _holdingsSub;
  StreamSubscription? _startupsSub;
  StreamSubscription? _operationsSub; // To fetch missing legacy holdings

  Map<String, double> _holdingQuantities = {};
  Map<String, double> _startupPrices = {};

  WealthController({required this.userId}) {
    _init();
  }

  void _init() {
    _listenToUserCash();
    _listenToHoldings();
    _listenToStartups();
    _listenToOperationsForLegacyTokens();
  }

  void _listenToUserCash() {
    _userSub = _db.collection('users').doc(userId).snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        cashBalance = (data['saldo'] as num?)?.toDouble() ?? 0.0;

        // Restaura o baseline salvo na sessão anterior (só na primeira leitura)
        if (!_baselineSavedOrLoaded) {
          final saved = (data['tokenValueBaseline'] as num?)?.toDouble();
          if (saved != null && saved > 0) {
            _sessionStartTokenValue = saved;
            _sessionStartRecorded = true;
            _baselineSavedOrLoaded = true;
          }
        }

        _calculateWealth();
      }
    });
  }

  Future<void> _saveBaseline(double value) async {
    try {
      await _db.collection('users').doc(userId).update({
        'tokenValueBaseline': value,
      });
    } catch (_) {}
  }

  void _listenToHoldings() {
    _holdingsSub = _db
        .collection('holdings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snap) {
          final newQuantities = <String, double>{};
          for (var doc in snap.docs) {
            final data = doc.data();
            final sId = data['startupId']?.toString();
            if (sId != null && sId.isNotEmpty) {
              final qty = (data['quantity'] as num?)?.toDouble() ?? 0.0;
              newQuantities[sId] = qty;
            }
          }

          // Merge with existing legacy tokens we discovered if any
          _holdingQuantities.forEach((k, v) {
            if (!newQuantities.containsKey(k)) {
              newQuantities[k] = v;
            }
          });

          _holdingQuantities = newQuantities;
          _calculateWealth();
        });
  }

  void _listenToOperationsForLegacyTokens() {
    _operationsSub = _db
        .collection('operations')
        .where('buyerId', isEqualTo: userId)
        .snapshots()
        .listen((snap) async {
          bool needRecalc = false;
          final Set<String> opsStartupIds = {};
          for (var doc in snap.docs) {
            final data = doc.data();
            final sId = data['startupId']?.toString();
            if (sId != null && sId.isNotEmpty) opsStartupIds.add(sId);
          }

          for (var sId in opsStartupIds) {
            if (!_holdingQuantities.containsKey(sId) ||
                _holdingQuantities[sId] == 0) {
              final qty = await CounterService().getUserTokens(sId);
              if (qty > 0) {
                _holdingQuantities[sId] = qty;
                needRecalc = true;
              }
            }
          }
          if (needRecalc) {
            _calculateWealth();
          }
        });
  }

  void _listenToStartups() {
    _startupsSub = _db.collection('startups').snapshots().listen((snap) {
      for (var doc in snap.docs) {
        final data = doc.data();
        final sId = doc.id;
        final currentPrice =
            (data['currentPrice'] as num?)?.toDouble() ??
            (((data['currentTokenPriceCents'] as num?)?.toInt() ?? 100) /
                100.0);
        _startupPrices[sId] = currentPrice;
      }
      _calculateWealth();
    });
  }

  void _calculateWealth() {
    double tokensValue = 0.0;
    _holdingQuantities.forEach((sId, qty) {
      if (qty > 0) {
        final price = _startupPrices[sId] ?? 0.0;
        tokensValue += (qty * price);
      }
    });

    tokensMarketValue = tokensValue;
    isLoading = false;

    // Se não veio do Firestore, grava agora como novo baseline
    if (!_sessionStartRecorded && tokensMarketValue > 0) {
      _sessionStartTokenValue = tokensMarketValue;
      _sessionStartRecorded = true;
      _baselineSavedOrLoaded = true;
      _saveBaseline(tokensMarketValue);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _holdingsSub?.cancel();
    _startupsSub?.cancel();
    _operationsSub?.cancel();
    super.dispose();
  }
}
