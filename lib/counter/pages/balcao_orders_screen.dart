import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/model/operationModel.dart';
import 'package:mesclainvest_f/startups/components/startup_colors.dart';
import 'package:mesclainvest_f/startups/services/trade_service.dart';

class BalcaoOrdersScreen extends StatefulWidget {
  final String startupId;
  final String startupName;
  final UserModel userModel;
  final String initialMode; // 'buy' or 'sell'

  const BalcaoOrdersScreen({
    super.key,
    required this.startupId,
    required this.startupName,
    required this.userModel,
    this.initialMode = 'buy',
  });

  @override
  State<BalcaoOrdersScreen> createState() => _BalcaoOrdersScreenState();
}

class _BalcaoOrdersScreenState extends State<BalcaoOrdersScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TradeService _tradeService = TradeService();
  late TabController _tabController;

  // Form state
  String _tradeMode = 'buy'; // 'buy' | 'sell'
  String _orderSource = 'startup'; // 'startup' | 'user' (buy mode only)
  double _qty = 1;
  double _price = 0.0;
  String _validity = '1'; // days as string: '1', '7', '30'
  final TextEditingController _priceCtrl = TextEditingController();

  // Market data
  double _currentMarketPrice = 0.0;

  // Live user data (from StreamBuilder)
  double _userBrlBalance = 0.0;
  double _reservedBalance = 0.0;
  int _userTokenHolding = 0;
  int _averagePriceCents = 0;

  bool _isProcessing = false;

  // Ordens tab — loaded once and refreshed manually
  List<OperationModel> _userOperations = [];
  bool _loadingOrdens = false;

  @override
  void initState() {
    super.initState();
    _tradeMode = widget.initialMode;
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialMarketPrice();
    _loadUserOperations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialMarketPrice() async {
    try {
      final doc = await _firestore.collection('startups').doc(widget.startupId).get();
      if (doc.exists) {
        final cents = (doc.data()!['currentTokenPriceCents'] ?? 0) as num;
        if (mounted) {
          setState(() {
            _currentMarketPrice = cents > 0 ? cents / 100.0 : 1.0;
            _price = _currentMarketPrice;
            _priceCtrl.text = _price.toStringAsFixed(2).replaceAll('.', ',');
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadUserOperations() async {
    setState(() => _loadingOrdens = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? widget.userModel.uid;
      final ops = await _tradeService.getOperationsByUser(uid);
      if (mounted) {
        setState(() {
          _userOperations =
              ops.where((op) => op.startupId == widget.startupId).toList();
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingOrdens = false);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _fmtBRL(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  double get _totalEstimated => _qty * _price;

  double get _profitLoss {
    if (_averagePriceCents <= 0 || _userTokenHolding <= 0) return 0;
    final avgBRL = _averagePriceCents / 100.0;
    return _userTokenHolding * (_currentMarketPrice - avgBRL);
  }

  double get _profitPercent {
    if (_averagePriceCents <= 0) return 0;
    final avgBRL = _averagePriceCents / 100.0;
    return avgBRL > 0 ? ((_currentMarketPrice - avgBRL) / avgBRL) * 100 : 0;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(widget.userModel.uid).snapshots(),
      builder: (context, userSnap) {
        if (userSnap.hasData && userSnap.data!.exists) {
          final d = userSnap.data!.data() as Map<String, dynamic>;
          _userBrlBalance = (d['saldo'] as num? ?? 0).toDouble();
          _reservedBalance = (d['reservedBalance'] as num? ?? 0).toDouble();
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('holdings')
              .doc('${widget.userModel.uid}_${widget.startupId}')
              .snapshots(),
          builder: (context, holdingSnap) {
            if (holdingSnap.hasData && holdingSnap.data!.exists) {
              final d = holdingSnap.data!.data() as Map<String, dynamic>;
              _userTokenHolding = (d['quantity'] as num? ?? 0).toInt();
              _averagePriceCents = (d['averagePriceCents'] as num? ?? 0).toInt();
            } else {
              _userTokenHolding = 0;
              _averagePriceCents = 0;
            }

            return Scaffold(
              backgroundColor: StartupColors.pageBg,
              appBar: _buildAppBar(),
              body: SafeArea(child: _buildBody()),
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: StartupColors.cardBg,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.startupName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _fmtBRL(_currentMarketPrice),
            style: const TextStyle(
              color: StartupColors.green,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmtBRL(_currentMarketPrice),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Preço atual',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildModeToggle(),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              if (_tradeMode == 'buy') _buildBuyForm(),
              if (_tradeMode == 'sell') _buildSellForm(),
              const SizedBox(height: 24),
              _buildInfoRows(),
              const SizedBox(height: 24),
              _buildBottomTabs(),
            ],
          ),
        ),
        _buildActionBar(),
      ],
    );
  }

  // ─── COMPRAR / VENDER toggle ──────────────────────────────────────────────

  Widget _buildModeToggle() {
    return Container(
      color: StartupColors.cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(child: _modeBtn('buy', 'COMPRAR', StartupColors.green)),
          const SizedBox(width: 10),
          Expanded(
              child: _modeBtn('sell', 'VENDER', const Color(0xFFE74C3C))),
        ],
      ),
    );
  }

  Widget _modeBtn(String mode, String label, Color activeColor) {
    final bool active = _tradeMode == mode;
    return GestureDetector(
      onTap: () => setState(() {
        _tradeMode = mode;
        // Reset quantity for sell mode to respect holdings cap
        if (mode == 'sell' && _qty > _userTokenHolding) {
          _qty = _userTokenHolding.toDouble().clamp(1, double.infinity);
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? activeColor : Colors.white12,
            width: active ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? activeColor : Colors.white38,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  // ─── Buy form ─────────────────────────────────────────────────────────────

  Widget _buildBuyForm() {
    final bool isStartup = _orderSource == 'startup';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tipo de ordem
        _fieldLabel('Tipo de ordem'),
        _dropdownBox(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _orderSource,
              dropdownColor: StartupColors.cardBg,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'startup', child: Text('Direto da Startup')),
                DropdownMenuItem(
                    value: 'user', child: Text('Comprar de Investidor')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _orderSource = v;
                  if (v == 'startup') {
                    _price = _currentMarketPrice;
                    _priceCtrl.text =
                        _price.toStringAsFixed(2).replaceAll('.', ',');
                  }
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Quantidade
        _fieldLabel('Quantidade'),
        _quantityStepper(maxQty: null),
        const SizedBox(height: 14),

        // Preço + Validade (row)
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Preço por token'),
                  _priceField(locked: isStartup),
                ],
              ),
            ),
            if (!isStartup) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Validade'),
                    _dropdownBox(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _validity,
                          dropdownColor: StartupColors.cardBg,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: Colors.white54),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: '1', child: Text('Hoje')),
                            DropdownMenuItem(
                                value: '7', child: Text('7 dias')),
                            DropdownMenuItem(
                                value: '30', child: Text('30 dias')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _validity = v);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ─── Sell form ────────────────────────────────────────────────────────────

  Widget _buildSellForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quantidade (capped to holdings)
        _fieldLabel('Quantidade (máx: $_userTokenHolding tokens)'),
        _quantityStepper(maxQty: _userTokenHolding.toDouble()),
        const SizedBox(height: 14),

        // Preço de venda
        _fieldLabel('Preço de venda por token'),
        _priceField(locked: false),
      ],
    );
  }

  // ─── Shared form widgets ──────────────────────────────────────────────────

  Widget _fieldLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );

  Widget _dropdownBox({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF141416),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: child,
      );

  Widget _quantityStepper({double? maxQty}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('Qtd ',
                  style: TextStyle(color: Colors.white38, fontSize: 14)),
              Text(
                _qty.toInt().toString(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove,
                    color: StartupColors.green, size: 20),
                onPressed: () {
                  if (_qty > 1) setState(() => _qty--);
                },
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.add,
                    color: StartupColors.green, size: 20),
                onPressed: () {
                  if (maxQty == null || _qty < maxQty) {
                    setState(() => _qty++);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceField({required bool locked}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: locked
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: TextField(
        controller: _priceCtrl,
        enabled: !locked,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(
          color: locked ? Colors.white38 : Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixText: 'R\$ ',
          prefixStyle: TextStyle(color: Colors.white38, fontSize: 15),
        ),
        onChanged: (val) {
          final clean = val.replaceAll(',', '.');
          setState(() => _price = double.tryParse(clean) ?? 0.0);
        },
      ),
    );
  }

  // ─── Info rows ────────────────────────────────────────────────────────────

  Widget _buildInfoRows() {
    final avgBRL = _averagePriceCents / 100.0;
    final positionValue = _userTokenHolding * _currentMarketPrice;
    final pl = _profitLoss;
    final plPct = _profitPercent;
    final plColor = pl >= 0 ? StartupColors.green : const Color(0xFFE74C3C);
    final availableBRL = _userBrlBalance - _reservedBalance;

    return Column(
      children: [
        _infoRow('Saldo disponível',
            _fmtBRL(availableBRL < 0 ? 0 : availableBRL)),
        const SizedBox(height: 8),
        _infoRow(
          'Valor estimado',
          _fmtBRL(_totalEstimated),
          highlight: true,
          highlightColor: _tradeMode == 'sell'
              ? const Color(0xFFE74C3C)
              : StartupColors.green,
        ),
        const SizedBox(height: 8),
        _infoRow(
            'Seus tokens', '${_userTokenHolding.toString()} tokens'),
        const SizedBox(height: 8),
        _infoRow(
          'Preço médio',
          _averagePriceCents > 0 ? _fmtBRL(avgBRL) : '--',
        ),
        const SizedBox(height: 8),
        _infoRow(
          'Posição total',
          positionValue > 0 ? _fmtBRL(positionValue) : '--',
        ),
        if (_averagePriceCents > 0) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Lucro / Perda',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              Text(
                '${pl >= 0 ? '+' : ''}${_fmtBRL(pl)} | '
                '${plPct >= 0 ? '+' : ''}${plPct.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: plColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _infoRow(String label, String value,
      {bool highlight = false, Color highlightColor = StartupColors.green}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: highlight ? highlightColor : Colors.white,
            fontSize: highlight ? 15 : 14,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── Embedded tabs ────────────────────────────────────────────────────────

  Widget _buildBottomTabs() {
    return Column(
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06), width: 1),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: StartupColors.green,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 2.5,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Posição'),
              Tab(text: 'Ofertas'),
              Tab(text: 'Ordens'),
            ],
          ),
        ),
        SizedBox(
          height: 300,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPosicaoTab(),
              _buildOfertasTab(),
              _buildOrdensTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Tab 1: Posição ───────────────────────────────────────────────────────

  Widget _buildPosicaoTab() {
    if (_userTokenHolding == 0) {
      return const Center(
        child: Text(
          'Você não possui tokens desta startup.',
          style: TextStyle(color: Colors.white38, fontSize: 13),
        ),
      );
    }

    final avgBRL = _averagePriceCents / 100.0;
    final positionValue = _userTokenHolding * _currentMarketPrice;
    final investedValue = _userTokenHolding * avgBRL;
    final pl = _profitLoss;
    final plPct = _profitPercent;
    final plColor = pl >= 0 ? StartupColors.green : const Color(0xFFE74C3C);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141416),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _posRow('Posição atual', _fmtBRL(positionValue), big: true),
            const Divider(color: Colors.white10, height: 20),
            _posRow('Quantidade', '$_userTokenHolding tokens'),
            const SizedBox(height: 8),
            _posRow('Preço médio',
                _averagePriceCents > 0 ? _fmtBRL(avgBRL) : '--'),
            const SizedBox(height: 8),
            _posRow('Custo total',
                investedValue > 0 ? _fmtBRL(investedValue) : '--'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lucro / Perda',
                    style: TextStyle(color: Colors.white38, fontSize: 13)),
                Text(
                  '${pl >= 0 ? '+' : ''}${_fmtBRL(pl)} | '
                  '${plPct >= 0 ? '+' : ''}${plPct.toStringAsFixed(2)}%',
                  style: TextStyle(
                      color: plColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _posRow(String label, String value, {bool big = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: big ? 17 : 14,
            fontWeight: big ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── Tab 2: Ofertas (order book + pending buys) ───────────────────────────

  Widget _buildOfertasTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('balcaoOffers')
          .where('startupId', isEqualTo: widget.startupId)
          .where('status', isEqualTo: 'open')
          .snapshots(),
      builder: (context, snap) {
        final offers = snap.data?.docs ?? [];
        final sellOffers =
            offers.where((d) => (d.data() as Map)['type'] == 'sell').toList();
        final buyOffers =
            offers.where((d) => (d.data() as Map)['type'] == 'buy').toList();

        sellOffers.sort((a, b) => ((a.data() as Map)['pricePerToken'] as num)
            .compareTo((b.data() as Map)['pricePerToken'] as num));
        buyOffers.sort((a, b) => ((b.data() as Map)['pricePerToken'] as num)
            .compareTo((a.data() as Map)['pricePerToken'] as num));

        if (offers.isEmpty) {
          return const Center(
            child: Text(
              'Sem ofertas ativas no mercado secundário.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            if (sellOffers.isNotEmpty) ...[
              _offerSectionLabel('Ofertas de Venda', const Color(0xFFE74C3C)),
              ...sellOffers.map((doc) => _offerBookItem(doc, isBuy: false)),
            ],
            if (buyOffers.isNotEmpty) ...[
              const SizedBox(height: 10),
              _offerSectionLabel('Ofertas de Compra', StartupColors.green),
              ...buyOffers.map((doc) => _offerBookItem(doc, isBuy: true)),
            ],
          ],
        );
      },
    );
  }

  Widget _offerSectionLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _offerBookItem(DocumentSnapshot doc, {required bool isBuy}) {
    final data = doc.data() as Map<String, dynamic>;
    final double price = (data['pricePerToken'] ?? 0.0).toDouble();
    final double qty =
        (data['remainingQuantity'] ?? data['quantity'] ?? 0.0).toDouble();
    final bool isOurs = (data['userId'] ?? '') == widget.userModel.uid;

    return InkWell(
      onTap: () => setState(() {
        _qty = qty;
        _price = price;
        _priceCtrl.text = _price.toStringAsFixed(2).replaceAll('.', ',');
      }),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isOurs
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isOurs
                  ? StartupColors.green.withValues(alpha: 0.15)
                  : Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isBuy
                        ? StartupColors.green
                        : const Color(0xFFE74C3C),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text('${qty.toInt()} tokens',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                if (isOurs) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: StartupColors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('MEU',
                        style: TextStyle(
                            color: StartupColors.green,
                            fontSize: 8,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            Row(
              children: [
                Text(
                  _fmtBRL(price),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 14),
                Text(
                  _fmtBRL(qty * price),
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab 3: Minhas Ordens (from operations collection) ───────────────────

  Widget _buildOrdensTab() {
    if (_loadingOrdens) {
      return const Center(
          child: CircularProgressIndicator(color: StartupColors.green));
    }

    if (_userOperations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Nenhuma operação registrada.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _loadUserOperations,
              icon: const Icon(Icons.refresh,
                  color: StartupColors.green, size: 16),
              label: const Text('Atualizar',
                  style: TextStyle(color: StartupColors.green, fontSize: 13)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _userOperations.length,
      itemBuilder: (context, index) {
        final op = _userOperations[index];
        return _operationCard(op);
      },
    );
  }

  Widget _operationCard(OperationModel op) {
    final bool isBuy = op.type == OperationType.buyFromStartup ||
        op.type == OperationType.buyFromUser;
    final Color typeColor =
        isBuy ? StartupColors.green : const Color(0xFFE74C3C);
    final String typeLabel = op.type == OperationType.buyFromStartup
        ? 'COMPRA (Startup)'
        : op.type == OperationType.buyFromUser
            ? 'COMPRA (Investidor)'
            : 'VENDA';

    Color statusColor;
    String statusLabel;
    switch (op.status) {
      case OperationStatus.accepted:
        statusColor = StartupColors.green;
        statusLabel = 'Aceita';
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
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: typeColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(typeLabel,
                        style: TextStyle(
                            color: typeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(statusLabel,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('${op.quantity} tokens',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 6),
                    Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      '${_fmtBRL(op.pricePerToken)}/t',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Total: ${_fmtBRL(op.total)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (op.status == OperationStatus.pending)
            SizedBox(
              height: 34,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFE74C3C).withValues(alpha: 0.12),
                  foregroundColor: const Color(0xFFE74C3C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(
                        color: Color(0xFFE74C3C), width: 1),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: () => _confirmCancelOperation(op),
                child: const Text('Cancelar',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmCancelOperation(OperationModel op) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        title: const Text('Cancelar Operação',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Cancelar esta oferta de ${op.type == OperationType.buyFromUser ? 'compra' : 'venda'} de ${op.quantity} tokens por ${_fmtBRL(op.total)}?'
          '${op.type == OperationType.buyFromUser ? '\n\nO valor reservado será liberado.' : ''}',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Voltar',
                style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _cancelOperation(op.id);
            },
            child: const Text('Confirmar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOperation(String operationId) async {
    try {
      await _tradeService.rejectOperation(operationId);
      _showSnackBar('Operação cancelada com sucesso.');
      _loadUserOperations();
    } catch (e) {
      _showSnackBar(
          e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  // ─── Bottom action bar ────────────────────────────────────────────────────

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: StartupColors.cardBg,
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.04))),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3C1F1F),
                  foregroundColor: const Color(0xFFE74C3C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                        color: Color(0xFFE74C3C), width: 1),
                  ),
                  elevation: 0,
                ),
                onPressed:
                    _isProcessing ? null : () => _placeOrder('sell'),
                child: _isProcessing && _tradeMode == 'sell'
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Color(0xFFE74C3C), strokeWidth: 2))
                    : const Text('Vender',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: StartupColors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed:
                    _isProcessing ? null : () => _placeOrder('buy'),
                child: _isProcessing && _tradeMode == 'buy'
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Comprar',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Order execution ──────────────────────────────────────────────────────

  Future<void> _placeOrder(String side) async {
    if (_qty <= 0 || _price <= 0) {
      _showSnackBar('Quantidade e preço devem ser maiores que zero.',
          isError: true);
      return;
    }

    setState(() {
      _isProcessing = true;
      _tradeMode = side;
    });

    try {
      if (side == 'buy') {
        if (_orderSource == 'startup') {
          await _tradeService.buyFromStartup(
            startupId: widget.startupId,
            quantity: _qty.toInt(),
          );
          _showSnackBar('Compra realizada com sucesso!');
        } else {
          final priceCents = (_price * 100).round();
          await _tradeService.buyFromUser(
            startupId: widget.startupId,
            quantity: _qty.toInt(),
            pricePerTokenCents: priceCents,
            validityDays: int.parse(_validity),
          );
          _showSnackBar('Oferta de compra criada. Aguardando vendedor aceitar.');
        }
      } else {
        if (_userTokenHolding < _qty.toInt()) {
          _showSnackBar('Holdings insuficientes para esta venda.', isError: true);
          setState(() => _isProcessing = false);
          return;
        }
        final priceCents = (_price * 100).round();
        await _tradeService.sell(
          startupId: widget.startupId,
          quantity: _qty.toInt(),
          askedPricePerTokenCents: priceCents,
        );
        _showSnackBar('Oferta de venda criada com sucesso!');
      }

      // Reload operations tab after action
      _loadUserOperations();
    } catch (e) {
      _showSnackBar(
          e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor:
            isError ? const Color(0xFFE74C3C) : StartupColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
