// Grupo: G09
// Trabalho: PI3-2026-T2-G09

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesclainvest_f/components/navBar.dart';
import 'package:mesclainvest_f/counter/components/counterToggle.dart';
import 'package:mesclainvest_f/counter/components/orderBookTable.dart';
import 'package:mesclainvest_f/counter/services/counterService.dart';
import 'package:mesclainvest_f/model/offerModel.dart';
import 'package:mesclainvest_f/model/operationModel.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/startups/components/startup_colors.dart';
import 'package:mesclainvest_f/startups/services/getStartup.dart';

class CounterPage extends StatefulWidget {
  final UserModel user;
  const CounterPage({super.key, required this.user});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _tabIndex = 0; // 0=Comprar 1=Vender 2=Minhas Ordens
  final CounterService _service = CounterService();

  // ── Estado assíncrono do Balcão ─────────────────────────────────────────
  List<Map<String, String>> _startupsList = [];
  List<Map<String, String>> _sellStartups = [];
  double _userTokensBalance = 0.0;
  Timer? _offerRefreshTimer;

  // ── Estado da aba Comprar ──────────────────────────────────────────────
  String? _buyStartupId;
  String? _buyStartupNome;
  List<OfferModel> _buyVendaOffers = [];
  List<OfferModel> _buyCompraOffers = [];

  // ── Estado da aba Vender ───────────────────────────────────────────────
  String? _sellStartupId;
  String? _sellStartupNome;
  double _sellQtd = 1;
  final TextEditingController _sellPrecoCtrl = TextEditingController(
    text: '1,00',
  );
  List<OfferModel> _sellVendaOffers = [];
  List<OfferModel> _sellCompraOffers = [];

  @override
  void initState() {
    super.initState();
    _loadStartups();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _offerRefreshTimer?.cancel();
    _sellPrecoCtrl.dispose();
    super.dispose();
  }

  void _startRefreshTimer() {
    _offerRefreshTimer?.cancel();
    _offerRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_tabIndex == 0) _refreshBuyBook();
      if (_tabIndex == 1) _refreshSellBook();
    });
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Future<void> _loadStartups() async {
    try {
      final list = await StartupService().listStartups();
      if (mounted) {
        setState(() {
          _startupsList = list
              .map(
                (s) => {
                  'id': (s['id'] ?? '').toString(),
                  'nome': (s['name'] ?? '').toString(),
                },
              )
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _startupsList = CounterService.allStartups;
        });
      }
    }
  }

  void _loadSellStartups() async {
    final list = await _service.getStartupsWithUserTokens();
    if (mounted) {
      setState(() {
        _sellStartups = list;
      });
    }
  }

  void _onBuyStartupSelected(String id, String nome) {
    setState(() {
      _buyStartupId = id;
      _buyStartupNome = nome;
    });
    _refreshBuyBook();
  }

  void _onSellStartupSelected(String id, String nome) async {
    _sellPrecoCtrl.text = '1,00';
    setState(() {
      _sellStartupId = id;
      _sellStartupNome = nome;
      _sellQtd = 1;
    });

    final tokens = await _service.getUserTokens(id);
    if (mounted) {
      setState(() {
        _userTokensBalance = tokens;
      });
    }
    _refreshSellBook();
  }

  Future<List<OfferModel>> _fetchOffersFromFirestore(String startupId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('balcaoOffers')
          .where('startupId', isEqualTo: startupId)
          .get();
      return snap.docs
          .map((doc) {
            final data = doc.data();
            if (data['status'] != 'open') return null;
            return OfferModel(
              id: doc.id,
              startupId: data['startupId'] ?? '',
              startupNome: data['startupNome'] ?? '',
              vendedorId: data['userId'] ?? '',
              vendedorNome: 'Investidor',
              quantidade: (data['quantity'] as num?)?.toDouble() ?? 0,
              precoPorToken: (data['pricePerToken'] as num?)?.toDouble() ?? 0,
              tipo: data['type'] == 'buy' ? OrderType.compra : OrderType.venda,
              status: OrderStatus.aberta,
              criadoEm: data['createdAt'] is Timestamp
                  ? (data['createdAt'] as Timestamp).toDate()
                  : DateTime.now(),
            );
          })
          .whereType<OfferModel>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _refreshBuyBook() async {
    if (_buyStartupId == null) return;
    final all = await _fetchOffersFromFirestore(_buyStartupId!);
    if (mounted) {
      setState(() {
        _buyVendaOffers = all.where((o) => o.tipo == OrderType.venda).toList()
          ..sort((a, b) => a.precoPorToken.compareTo(b.precoPorToken));
        _buyCompraOffers = all.where((o) => o.tipo == OrderType.compra).toList()
          ..sort((a, b) => b.precoPorToken.compareTo(a.precoPorToken));
      });
    }
  }

  void _refreshSellBook() async {
    if (_sellStartupId == null) return;
    final all = await _fetchOffersFromFirestore(_sellStartupId!);
    if (mounted) {
      setState(() {
        _sellVendaOffers = all.where((o) => o.tipo == OrderType.venda).toList()
          ..sort((a, b) => a.precoPorToken.compareTo(b.precoPorToken));
        _sellCompraOffers =
            all.where((o) => o.tipo == OrderType.compra).toList()
              ..sort((a, b) => b.precoPorToken.compareTo(a.precoPorToken));
      });
    }
  }

  double get _sellPreco {
    final raw = _sellPrecoCtrl.text
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(raw) ?? 0.0;
  }

  // ── Build principal ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: StartupColors.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: CounterToggle(
                selectedIndex: _tabIndex,
                onChanged: (i) {
                  setState(() => _tabIndex = i);
                  if (i == 1) {
                    _loadSellStartups();
                  }
                },
                tabs: const ['Comprar', 'Vender', 'Minhas Ordens'],
              ),
            ),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        userModel: widget.user,
        currentIndex: 2,
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Balcão',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tabIndex) {
      case 0:
        return _buildComprarTab();
      case 1:
        return _buildVenderTab();
      case 2:
        return _buildMinhasOrdensTab();
      default:
        return const SizedBox();
    }
  }

  // ── Aba COMPRAR ──────────────────────────────────────────────────────────
  // Fluxo: seleciona startup → vê tabela de ordens → clica em oferta de venda → compra

  Widget _buildComprarTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      physics: const BouncingScrollPhysics(),
      children: [
        const _FieldLabel(text: 'Selecione a startup'),
        const SizedBox(height: 8),
        _buildStartupDropdown(
          startups: _startupsList.isEmpty
              ? CounterService.allStartups
              : _startupsList,
          selectedId: _buyStartupId,
          onSelected: _onBuyStartupSelected,
        ),
        if (_buyStartupId == null) ...[
          const SizedBox(height: 60),
          const _EmptyPrompt(
            message: 'Selecione uma startup para ver as ordens disponíveis',
          ),
        ] else ...[
          const SizedBox(height: 24),
          _SectionLabel(
            text: 'LIVRO DE ORDENS — ${_buyStartupNome!.toUpperCase()}',
          ),
          const SizedBox(height: 10),
          OrderBookTable(
            vendaOrders: _buyVendaOffers,
            compraOrders: _buyCompraOffers,
          ),
          const SizedBox(height: 24),
          const _SectionLabel(text: 'CLIQUE EM UMA OFERTA PARA COMPRAR'),
          const SizedBox(height: 10),
          if (_buyVendaOffers.isEmpty)
            const _EmptyPrompt(
              message: 'Nenhuma oferta de venda para esta startup',
            )
          else
            ..._buyVendaOffers.map(
              (offer) => _OfferRowCompra(
                offer: offer,
                onTap: () => _showBuySheet(offer),
              ),
            ),
        ],
      ],
    );
  }

  void _showBuySheet(OfferModel offer) {
    double qty = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final total = qty * offer.precoPorToken;
          final hasSaldo = widget.user.saldo >= total;
          final maxQty = offer.quantidade;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: const BoxDecoration(
                color: Color(0xFF262629),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Título
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Comprar Tokens',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            offer.startupNome,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'R\$ ${offer.precoPorToken.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: const TextStyle(
                              color: Color(0xFF1A9B5F),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            '/token',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),
                  Text(
                    'Disponível: ${offer.quantidade.toInt()} tokens',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),

                  const SizedBox(height: 20),

                  // Stepper de quantidade
                  const Text(
                    'Quantidade',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF107649).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        _SheetStepBtn(
                          icon: Icons.remove,
                          onTap: () {
                            if (qty > 1) setSheet(() => qty--);
                          },
                        ),
                        Expanded(
                          child: Text(
                            qty.toInt().toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _SheetStepBtn(
                          icon: Icons.add,
                          onTap: () {
                            if (qty < maxQty) setSheet(() => qty++);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Resumo
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _SheetSummaryRow(
                          label: 'Total',
                          value:
                              'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
                          highlight: true,
                        ),
                        const SizedBox(height: 8),
                        _SheetSummaryRow(
                          label: 'Saldo disponível',
                          value:
                              'R\$ ${widget.user.saldo.toStringAsFixed(2).replaceAll('.', ',')}',
                        ),
                      ],
                    ),
                  ),

                  if (!hasSaldo) ...[
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFE74C3C),
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Saldo insuficiente para esta compra',
                          style: TextStyle(
                            color: Color(0xFFE74C3C),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasSaldo
                            ? const Color(0xFF107649)
                            : Colors.white12,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                        elevation: 0,
                      ),
                      onPressed: hasSaldo
                          ? () async {
                              Navigator.pop(ctx);
                              final result = await _service.buyTokens(
                                offer.startupId,
                                qty,
                              );
                              if (result['success'] == true) {
                                if (mounted) {
                                  setState(() {
                                    widget.user.saldo =
                                        result['updatedBalance'];
                                  });
                                }
                                _refreshBuyBook();
                                _showSnackBar(
                                  'Compra de ${qty.toInt()} tokens de ${offer.startupNome} realizada!',
                                );
                              } else {
                                _showSnackBar(
                                  result['error'] ??
                                      'Erro ao processar compra.',
                                  isError: true,
                                );
                              }
                            }
                          : null,
                      child: Text(
                        'Confirmar Compra',
                        style: TextStyle(
                          color: hasSaldo ? Colors.white : Colors.white38,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Aba VENDER ───────────────────────────────────────────────────────────
  // Fluxo: seleciona startup (onde tem tokens) → vê tabela → define qtd + preço → publica

  Widget _buildVenderTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      physics: const BouncingScrollPhysics(),
      children: [
        const _FieldLabel(text: 'Startup onde você possui tokens'),
        const SizedBox(height: 8),
        _buildStartupDropdown(
          startups: _sellStartups,
          selectedId: _sellStartupId,
          onSelected: _onSellStartupSelected,
          hint: _sellStartups.isEmpty
              ? 'Você não possui tokens'
              : 'Selecione a startup',
        ),
        if (_sellStartupId == null) ...[
          const SizedBox(height: 60),
          const _EmptyPrompt(
            message: 'Selecione uma startup para publicar uma oferta de venda',
          ),
        ] else ...[
          const SizedBox(height: 12),

          // Badge com saldo de tokens do usuário
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF107649).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF107649).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.toll_rounded,
                  color: Color(0xFF1A9B5F),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Seus tokens: $_userTokensBalance $_sellStartupNome',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _SectionLabel(
            text: 'LIVRO DE ORDENS — ${_sellStartupNome!.toUpperCase()}',
          ),
          const SizedBox(height: 10),
          OrderBookTable(
            vendaOrders: _sellVendaOffers,
            compraOrders: _sellCompraOffers,
          ),

          const SizedBox(height: 24),
          const _SectionLabel(text: 'PUBLICAR OFERTA DE VENDA'),
          const SizedBox(height: 12),
          _buildSellForm(),
        ],
      ],
    );
  }

  Widget _buildSellForm() {
    final userTokens = _userTokensBalance;
    final total = _sellQtd * _sellPreco;
    final enoughTokens = _sellQtd <= userTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quantidade
        const _FieldLabel(text: 'Quantidade de tokens'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF262629),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF107649).withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              _FormStepBtn(
                icon: Icons.remove,
                onTap: () {
                  if (_sellQtd > 1) setState(() => _sellQtd--);
                },
              ),
              Expanded(
                child: Text(
                  _sellQtd.toInt().toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _FormStepBtn(
                icon: Icons.add,
                onTap: () {
                  if (_sellQtd < userTokens) setState(() => _sellQtd++);
                },
              ),
            ],
          ),
        ),

        if (!enoughTokens) ...[
          const SizedBox(height: 6),
          Text(
            'Você possui apenas ${userTokens.toInt()} tokens',
            style: const TextStyle(color: Color(0xFFE74C3C), fontSize: 12),
          ),
        ],

        const SizedBox(height: 16),

        // Preço por token
        const _FieldLabel(text: 'Preço por token (R\$)'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF262629),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF107649).withValues(alpha: 0.4),
            ),
          ),
          child: TextField(
            controller: _sellPrecoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              prefixText: 'R\$ ',
              prefixStyle: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),

        const SizedBox(height: 16),

        // Resumo
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF262629),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              _SheetSummaryRow(
                label: 'Tokens a vender',
                value: '${_sellQtd.toInt()}',
              ),
              const SizedBox(height: 8),
              _SheetSummaryRow(
                label: 'Preço/token',
                value:
                    'R\$ ${_sellPreco.toStringAsFixed(2).replaceAll('.', ',')}',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Color(0xFF3A3A3A), height: 1),
              ),
              _SheetSummaryRow(
                label: 'Total estimado',
                value: 'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
                highlight: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: enoughTokens && _sellPreco > 0
                  ? const Color(0xFF107649)
                  : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              elevation: 0,
            ),
            onPressed: enoughTokens && _sellPreco > 0
                ? _publishSellOffer
                : null,
            child: Text(
              'Publicar Oferta de Venda',
              style: TextStyle(
                color: enoughTokens && _sellPreco > 0
                    ? Colors.white
                    : Colors.white38,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _publishSellOffer() async {
    final offer = OfferModel(
      id: '',
      startupId: _sellStartupId!,
      startupNome: _sellStartupNome!,
      vendedorId: widget.user.uid,
      vendedorNome: widget.user.firstName,
      quantidade: _sellQtd,
      precoPorToken: _sellPreco,
      tipo: OrderType.venda,
      criadoEm: DateTime.now(),
    );

    final success = await _service.addOffer(offer);

    if (success) {
      _refreshSellBook();
      _sellPrecoCtrl.text = '1,00';
      final publishedQty =
          _sellQtd; // Guarda a quantidade publicada antes de resetar
      setState(() {
        _sellQtd = 1;
      });
      _showSnackBar(
        'Oferta de ${publishedQty.toInt()} tokens publicada na tabela!',
      );
    } else {
      _showSnackBar('Erro ao publicar oferta de venda.', isError: true);
    }
  }

  // ── Aba MINHAS ORDENS ────────────────────────────────────────────────────

  Widget _buildMinhasOrdensTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('operations')
          .where('buyerId', isEqualTo: widget.user.uid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(color: Color(0xFF107649)),
            ),
          );
        }

        final docs = snap.data?.docs ?? [];
        final ops =
            docs
                .map(
                  (d) => OperationModel.fromMap(
                    d.id,
                    d.data() as Map<String, dynamic>,
                  ),
                )
                .toList()
              ..sort(
                (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                  a.createdAt ?? DateTime(0),
                ),
              );

        if (ops.isEmpty) {
          return const _EmptyPrompt(
            message: 'Você ainda não tem operações registradas',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          physics: const BouncingScrollPhysics(),
          itemCount: ops.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: _SectionLabel(text: 'MINHAS OPERAÇÕES'),
              );
            }
            return _OperationCard(op: ops[i - 1]);
          },
        );
      },
    );
  }

  // ── Shared widgets inline ────────────────────────────────────────────────

  Widget _buildStartupDropdown({
    required List<Map<String, String>> startups,
    required String? selectedId,
    required void Function(String id, String nome) onSelected,
    String hint = 'Selecione a startup',
  }) {
    final matches = startups.where((s) => s['id'] == selectedId).toList();
    final selectedNome = matches.isEmpty ? null : matches.first['nome'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF262629),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedNome,
          hint: Text(
            hint,
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
          isExpanded: true,
          dropdownColor: const Color(0xFF262629),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          items: startups
              .map(
                (s) =>
                    DropdownMenuItem(value: s['nome'], child: Text(s['nome']!)),
              )
              .toList(),
          onChanged: startups.isEmpty
              ? null
              : (val) {
                  if (val == null) return;
                  final match = startups.firstWhere((s) => s['nome'] == val);
                  onSelected(match['id']!, match['nome']!);
                },
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isError
            ? const Color(0xFFE74C3C)
            : const Color(0xFF107649),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ── Componentes privados da página ─────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _EmptyPrompt extends StatelessWidget {
  final String message;
  const _EmptyPrompt({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white38, fontSize: 14),
        ),
      ),
    );
  }
}

// Linha de oferta de venda na aba Comprar — clicável na linha toda
class _OfferRowCompra extends StatelessWidget {
  final OfferModel offer;
  final VoidCallback onTap;

  const _OfferRowCompra({required this.offer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF262629),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.vendedorNome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${offer.quantidade.toInt()} tokens disponíveis',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R\$ ${offer.precoPorToken.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    color: Color(0xFF1A9B5F),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  '/token',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF107649),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Comprar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Stepper do bottom sheet de compra
class _SheetStepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SheetStepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF107649).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: const Color(0xFF107649), size: 22),
      ),
    );
  }
}

// Stepper do formulário de venda
class _FormStepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FormStepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF107649).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: const Color(0xFF107649), size: 22),
      ),
    );
  }
}

// Linha de resumo no sheet / form
class _SheetSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SheetSummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight ? const Color(0xFF1A9B5F) : Colors.white,
            fontSize: 13,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Card de operação na aba Minhas Operações
class _OperationCard extends StatelessWidget {
  final OperationModel op;
  const _OperationCard({required this.op});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    switch (op.status) {
      case OperationStatus.accepted:
        statusColor = const Color(0xFF1A9B5F);
        statusLabel = 'Concluída';
        break;
      case OperationStatus.rejected:
        statusColor = const Color(0xFFE74C3C);
        statusLabel = 'Rejeitada';
        break;
      case OperationStatus.cancelled:
        statusColor = Colors.white38;
        statusLabel = 'Cancelada';
        break;
      case OperationStatus.pending:
        statusColor = const Color(0xFFF39C12);
        statusLabel = 'Pendente';
        break;
    }

    final priceStr =
        'R\$ ${op.pricePerToken.toStringAsFixed(2).replaceAll('.', ',')}';
    final totalStr = 'R\$ ${op.total.toStringAsFixed(2).replaceAll('.', ',')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF262629),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF1A9B5F),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  op.startupName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Compra · ${op.quantity} tokens @ $priceStr',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                totalStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
