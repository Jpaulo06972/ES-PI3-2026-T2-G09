// Grupo: G09
// Trabalho: PI3-2026-T2-G09

import 'package:mesclainvest_f/model/offerModel.dart';

class CounterService {
  // Todas as startups disponíveis no balcão
  static const List<Map<String, String>> allStartups = [
    {'id': 'startup_eco', 'nome': 'EcoTech PUC'},
    {'id': 'startup_med', 'nome': 'MedConnect'},
    {'id': 'startup_agri', 'nome': 'AgriSmart'},
    {'id': 'startup_fin', 'nome': 'FinEduca'},
  ];

  // Mock: tokens que o usuário possui por startup (produção viria do Firestore)
  static final Map<String, double> _userTokens = {
    'startup_eco': 120.0,
    'startup_med': 45.0,
  };

  // Lista estática para persistir adições durante a sessão
  static final List<OfferModel> _offers = [
    // ── Ordens de VENDA ───────────────────────────────────────────────────
    OfferModel(
      id: 'sell_001',
      startupId: 'startup_eco',
      startupNome: 'EcoTech PUC',
      vendedorId: 'mock_user_a',
      vendedorNome: 'Lucas Silva',
      quantidade: 50,
      precoPorToken: 1.00,
      tipo: OrderType.venda,
      criadoEm: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    OfferModel(
      id: 'sell_002',
      startupId: 'startup_med',
      startupNome: 'MedConnect',
      vendedorId: 'mock_user_b',
      vendedorNome: 'Ana Rodrigues',
      quantidade: 10,
      precoPorToken: 1.01,
      tipo: OrderType.venda,
      criadoEm: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    OfferModel(
      id: 'sell_003',
      startupId: 'startup_eco',
      startupNome: 'EcoTech PUC',
      vendedorId: 'mock_user_c',
      vendedorNome: 'Pedro Alves',
      quantidade: 2,
      precoPorToken: 1.05,
      tipo: OrderType.venda,
      criadoEm: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    OfferModel(
      id: 'sell_004',
      startupId: 'startup_agri',
      startupNome: 'AgriSmart',
      vendedorId: 'mock_user_d',
      vendedorNome: 'Carla Mendes',
      quantidade: 5,
      precoPorToken: 4.00,
      tipo: OrderType.venda,
      criadoEm: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    OfferModel(
      id: 'sell_005',
      startupId: 'startup_fin',
      startupNome: 'FinEduca',
      vendedorId: 'mock_user_e',
      vendedorNome: 'Roberto Lima',
      quantidade: 6,
      precoPorToken: 10.20,
      tipo: OrderType.venda,
      criadoEm: DateTime.now().subtract(const Duration(hours: 24)),
    ),

    // ── Ordens de COMPRA ──────────────────────────────────────────────────
    OfferModel(
      id: 'buy_001',
      startupId: 'startup_eco',
      startupNome: 'EcoTech PUC',
      vendedorId: 'mock_user_f',
      vendedorNome: 'Marina Costa',
      quantidade: 150,
      precoPorToken: 1.50,
      tipo: OrderType.compra,
      criadoEm: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    OfferModel(
      id: 'buy_002',
      startupId: 'startup_med',
      startupNome: 'MedConnect',
      vendedorId: 'mock_user_g',
      vendedorNome: 'João Paulo',
      quantidade: 190,
      precoPorToken: 9.30,
      tipo: OrderType.compra,
      criadoEm: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    OfferModel(
      id: 'buy_003',
      startupId: 'startup_agri',
      startupNome: 'AgriSmart',
      vendedorId: 'mock_user_h',
      vendedorNome: 'Felipe Bastos',
      quantidade: 9,
      precoPorToken: 4.00,
      tipo: OrderType.compra,
      criadoEm: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    OfferModel(
      id: 'buy_004',
      startupId: 'startup_fin',
      startupNome: 'FinEduca',
      vendedorId: 'mock_user_i',
      vendedorNome: 'Camila Souza',
      quantidade: 30,
      precoPorToken: 2.60,
      tipo: OrderType.compra,
      criadoEm: DateTime.now().subtract(const Duration(hours: 10)),
    ),
    OfferModel(
      id: 'buy_005',
      startupId: 'startup_eco',
      startupNome: 'EcoTech PUC',
      vendedorId: 'mock_user_j',
      vendedorNome: 'Thiago Reis',
      quantidade: 19,
      precoPorToken: 2.00,
      tipo: OrderType.compra,
      criadoEm: DateTime.now().subtract(const Duration(hours: 15)),
    ),
  ];

  // ── Queries por startup ────────────────────────────────────────────────

  /// Ofertas de venda para uma startup — preço crescente (mais barato primeiro)
  List<OfferModel> getVendaForStartup(String startupId) {
    final list = _offers
        .where((o) =>
            o.startupId == startupId &&
            o.tipo == OrderType.venda &&
            o.status == OrderStatus.aberta)
        .toList();
    list.sort((a, b) => a.precoPorToken.compareTo(b.precoPorToken));
    return list;
  }

  /// Ofertas de compra para uma startup — preço decrescente (maior lance primeiro)
  List<OfferModel> getCompraForStartup(String startupId) {
    final list = _offers
        .where((o) =>
            o.startupId == startupId &&
            o.tipo == OrderType.compra &&
            o.status == OrderStatus.aberta)
        .toList();
    list.sort((a, b) => b.precoPorToken.compareTo(a.precoPorToken));
    return list;
  }

  /// Ordens do usuário logado — mais recente primeiro
  List<OfferModel> getUserOffers(String userId) {
    return _offers
        .where((o) => o.vendedorId == userId)
        .toList()
      ..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
  }

  // ── Token holdings do usuário (mock) ──────────────────────────────────

  /// Quantidade de tokens que o usuário possui em determinada startup
  double getUserTokens(String startupId) => _userTokens[startupId] ?? 0.0;

  /// Startups onde o usuário tem pelo menos 1 token
  List<Map<String, String>> getStartupsWithUserTokens() {
    return allStartups
        .where((s) => (_userTokens[s['id']] ?? 0.0) > 0)
        .toList();
  }

  // ── Mutações ───────────────────────────────────────────────────────────

  void addOffer(OfferModel offer) {
    _offers.add(offer);
  }

  void cancelOffer(String offerId) {
    final idx = _offers.indexWhere((o) => o.id == offerId);
    if (idx != -1) {
      _offers[idx] = _offers[idx].copyWith(status: OrderStatus.cancelada);
    }
  }

  /// Subtrai tokens do usuário após uma compra bem-sucedida (mock)
  void addUserTokens(String startupId, double quantidade) {
    _userTokens[startupId] = (_userTokens[startupId] ?? 0.0) + quantidade;
  }
}
