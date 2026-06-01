// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Simula variação de preço dos tokens de todas as startups.
/// A cada 10 segundos, cada startup sofre uma variação aleatória entre -0,1% e +0,1%.
/// Também expõe [sessionOpenPrices] com os preços no início da sessão,
/// para cálculo de variação diária nos cards.
class PriceSimulatorService {
  static Timer? _timer;
  static final _db = FirebaseFirestore.instance;
  static final _rng = Random();

  /// Preços (em R$) de cada startup no momento em que a sessão começou.
  static final Map<String, double> sessionOpenPrices = {};

  /// Variação percentual aplicada no último tick de cada startup (ex: 1.23 = +1.23%).
  static final Map<String, double> currentChangePct = {};

  static bool get isRunning => _timer != null && _timer!.isActive;

  /// Inicia o simulador. Seguro chamar múltiplas vezes (cancela timer anterior).
  static Future<void> start() async {
    _timer?.cancel();
    sessionOpenPrices.clear();

    // Carrega preços de abertura e última variação salva de cada startup
    try {
      final snap = await _db.collection('startups').get();
      for (final doc in snap.docs) {
        final d = doc.data();
        final cents =
            (d['currentTokenPriceCents'] as num?)?.toInt() ??
            ((d['currentPrice'] as num?)?.toDouble() ?? 0) * 100;
        sessionOpenPrices[doc.id] = cents / 100.0;

        // Restaura a última variação salva para exibir imediatamente nos cards
        final saved = (d['lastSimulatorChangePct'] as num?)?.toDouble();
        if (saved != null) currentChangePct[doc.id] = saved;
      }
    } catch (_) {}

    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _updatePrices(),
    );
    debugPrint(
      '[PriceSimulator] iniciado — ${sessionOpenPrices.length} startups',
    );
  }

  /// Para o simulador (chamado no logout).
  static void stop() {
    _timer?.cancel();
    _timer = null;
    sessionOpenPrices.clear();
    currentChangePct.clear();
    debugPrint('[PriceSimulator] parado');
  }

  static Future<void> _updatePrices() async {
    try {
      final snap = await _db.collection('startups').get();
      if (snap.docs.isEmpty) return;

      final batch = _db.batch();

      for (final doc in snap.docs) {
        final data = doc.data();
        final currentCents =
            (data['currentTokenPriceCents'] as num?)?.toInt() ?? 100;
        final initialCents =
            (data['initialPriceCents'] as num?)?.toInt() ?? currentCents;

        // Variação aleatória única por startup: de -0,70% até +1,40%
        final changePct = (_rng.nextDouble() * 2.1) - 0.7;
        currentChangePct[doc.id] = changePct;
        var newCents = (currentCents * (1 + changePct / 100)).round();

        // Preço não cai abaixo de 10% do inicial nem sobe mais de 10x
        final floor = (initialCents * 0.10).round().clamp(1, initialCents);
        newCents = newCents.clamp(floor, initialCents * 10);
        final newPrice = newCents / 100.0;

        // Atualiza preço e persiste a última variação para restaurar entre sessões
        batch.update(doc.reference, {
          'currentTokenPriceCents': newCents,
          'currentTokenPrice': newPrice,
          'currentPrice': newPrice,
          'lastSimulatorChangePct': changePct,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Persiste no histórico de preços (mesma estrutura usada pelo backend)
        final histRef = _db
            .collection('tokenPriceHistory')
            .doc(doc.id)
            .collection('prices')
            .doc();
        batch.set(histRef, {
          'price': newPrice,
          'priceCents': newCents,
          'changePct': changePct,
          'timestamp': FieldValue.serverTimestamp(),
          'source': 'simulator',
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('[PriceSimulator] erro: $e');
    }
  }
}
