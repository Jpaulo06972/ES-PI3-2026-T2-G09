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
  // initialMode mantido por compatibilidade, mas a tela só faz compra direta
  final String initialMode;

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

  double _qty = 1;
  double _currentMarketPrice = 0.0;

  double _userBrlBalance = 0.0;
  int _userTokenHolding = 0;
  int _averagePriceCents = 0;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialMarketPrice();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialMarketPrice() async {
    try {
      final doc = await _firestore
          .collection('startups')
          .doc(widget.startupId)
          .get();
      if (doc.exists) {
        final cents = (doc.data()!['currentTokenPriceCents'] ?? 0) as num;
        if (mounted) {
          setState(() {
            _currentMarketPrice = cents > 0 ? cents / 100.0 : 1.0;
          });
        }
      }
    } catch (_) {}
  }

  String _fmtBRL(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  double get _totalEstimated => _qty * _currentMarketPrice;

  double get _profitLoss {
    if (_averagePriceCents <= 0 || _userTokenHolding <= 0) return 0;
    return _userTokenHolding *
        (_currentMarketPrice - _averagePriceCents / 100.0);
  }

  double get _profitPercent {
    if (_averagePriceCents <= 0) return 0;
    final avg = _averagePriceCents / 100.0;
    return avg > 0 ? ((_currentMarketPrice - avg) / avg) * 100 : 0;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('users')
          .doc(widget.userModel.uid)
          .snapshots(),
      builder: (context, userSnap) {
        if (userSnap.hasData && userSnap.data!.exists) {
          final d = userSnap.data!.data() as Map<String, dynamic>;
          _userBrlBalance = (d['saldo'] as num? ?? 0).toDouble();
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
              _averagePriceCents =
                  (d['averagePriceCents'] as num? ?? 0).toInt();
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
                fontWeight: FontWeight.bold),
          ),
          const Text(
            'Compra de Tokens',
            style: TextStyle(
                color: StartupColors.green,
                fontSize: 11,
                fontWeight: FontWeight.w600),
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
                    fontWeight: FontWeight.bold),
              ),
              const Text('Preço atual',
                  style: TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              _buildBuyForm(),
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

  // ─── Formulário de compra ─────────────────────────────────────────────────

  Widget _buildBuyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Quantidade de tokens'),
        _quantityStepper(),
        const SizedBox(height: 14),
        _fieldLabel('Preço por token (fixado pelo mercado)'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF141416),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('R\$',
                  style: TextStyle(color: Colors.white38, fontSize: 15)),
              Text(
                _currentMarketPrice.toStringAsFixed(2).replaceAll('.', ','),
                style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );

  Widget _quantityStepper() {
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
                onPressed: () => setState(() => _qty++),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Info rows ─────────────────────────────────────────────────────────────

  Widget _buildInfoRows() {
    final pl = _profitLoss;
    final plPct = _profitPercent;
    final plColor =
        pl >= 0 ? StartupColors.green : const Color(0xFFE74C3C);

    return Column(
      children: [
        _infoRow('Saldo disponível', _fmtBRL(_userBrlBalance)),
        const SizedBox(height: 8),
        _infoRow('Valor estimado', _fmtBRL(_totalEstimated),
            highlight: true),
        const SizedBox(height: 8),
        _infoRow('Seus tokens', '$_userTokenHolding tokens'),
        if (_averagePriceCents > 0) ...[
          const SizedBox(height: 8),
          _infoRow(
              'Preço médio', _fmtBRL(_averagePriceCents / 100.0)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Lucro / Perda',
                  style:
                      TextStyle(color: Colors.white54, fontSize: 13)),
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
      ],
    );
  }

  Widget _infoRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(color: Colors.white54, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: highlight ? StartupColors.green : Colors.white,
            fontSize: highlight ? 15 : 14,
            fontWeight:
                highlight ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── Tabs embarcadas ────────────────────────────────────────────────────────

  Widget _buildBottomTabs() {
    return Column(
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 1)),
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
          height: 280,
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

  // ─── Tab 1: Posição ────────────────────────────────────────────────────────

  Widget _buildPosicaoTab() {
    if (_userTokenHolding == 0) {
      return const Center(
        child: Text('Você não possui tokens desta startup.',
            style:
                TextStyle(color: Colors.white38, fontSize: 13)),
      );
    }

    final avgBRL = _averagePriceCents / 100.0;
    final positionValue = _userTokenHolding * _currentMarketPrice;
    final investedValue = _userTokenHolding * avgBRL;
    final pl = _profitLoss;
    final plPct = _profitPercent;
    final plColor =
        pl >= 0 ? StartupColors.green : const Color(0xFFE74C3C);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141416),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _posRow('Posição atual', _fmtBRL(positionValue),
                big: true),
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
                    style: TextStyle(
                        color: Colors.white38, fontSize: 13)),
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
            style: const TextStyle(
                color: Colors.white38, fontSize: 13)),
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

  // ─── Tab 2: Ofertas (balcaoOffers) ────────────────────────────────────────

  Widget _buildOfertasTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('balcaoOffers')
          .where('startupId', isEqualTo: widget.startupId)
          .where('status', isEqualTo: 'open')
          .snapshots(),
      builder: (context, snap) {
        final offers = snap.data?.docs ?? [];
        final sellOffers = offers
            .where(
                (d) => (d.data() as Map)['type'] == 'sell')
            .toList();

        sellOffers.sort((a, b) =>
            ((a.data() as Map)['pricePerToken'] as num)
                .compareTo(
                    (b.data() as Map)['pricePerToken'] as num));

        if (sellOffers.isEmpty) {
          return const Center(
            child: Text(
              'Sem ofertas de venda no mercado secundário.',
              style: TextStyle(
                  color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('Ofertas de Venda',
                  style: TextStyle(
                      color: Color(0xFFE74C3C),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
            ...sellOffers.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final double price =
                  (data['pricePerToken'] ?? 0.0).toDouble();
              final double qty = (data['remainingQuantity'] ??
                      data['quantity'] ??
                      0.0)
                  .toDouble();
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 10),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE74C3C),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${qty.toInt()} tokens',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13)),
                      ],
                    ),
                    Text(
                      _fmtBRL(price),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // ─── Tab 3: Minhas Ordens (Firestore stream) ─────────────────────────────

  Widget _buildOrdensTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? widget.userModel.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('operations')
          .where('buyerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: StartupColors.green));
        }

        final docs = snap.data?.docs ?? [];
        final ops = docs
            .map((d) => OperationModel.fromMap(
                d.id, d.data() as Map<String, dynamic>))
            .where((op) => op.startupId == widget.startupId)
            .toList()
          ..sort((a, b) =>
              (b.createdAt ?? DateTime(0))
                  .compareTo(a.createdAt ?? DateTime(0)));

        if (ops.isEmpty) {
          return const Center(
            child: Text(
              'Nenhuma compra registrada.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: ops.length,
          itemBuilder: (context, index) => _operationCard(ops[index]),
        );
      },
    );
  }

  Widget _operationCard(OperationModel op) {
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
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.04)),
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
                      decoration: const BoxDecoration(
                          color: StartupColors.green,
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    const Text('COMPRA',
                        style: TextStyle(
                            color: StartupColors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            statusColor.withValues(alpha: 0.12),
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
                Text('${op.quantity} tokens @ ${_fmtBRL(op.pricePerToken)}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text('Total: ${_fmtBRL(op.total)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Barra de ação ────────────────────────────────────────────────────────

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: StartupColors.cardBg,
        border: Border(
            top: BorderSide(
                color: Colors.white.withValues(alpha: 0.04))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: StartupColors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          onPressed: _isProcessing ? null : _confirmBuy,
          child: _isProcessing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(
                  'Comprar ${_qty.toInt()} token${_qty.toInt() != 1 ? 's' : ''} · ${_fmtBRL(_totalEstimated)}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  // ─── Execução da compra ───────────────────────────────────────────────────

  Future<void> _confirmBuy() async {
    if (_qty <= 0 || _currentMarketPrice <= 0) {
      _showSnackBar('Preço de mercado ainda carregando.',
          isError: true);
      return;
    }

    final double total = _totalEstimated;
    if (_userBrlBalance < total) {
      _showSnackBar(
          'Saldo insuficiente. Você tem ${_fmtBRL(_userBrlBalance)} e a compra custa ${_fmtBRL(total)}.',
          isError: true);
      return;
    }

    setState(() => _isProcessing = true);
    try {
      await _tradeService.buyFromStartup(
        startupId: widget.startupId,
        quantity: _qty.toInt(),
      );
      _showSnackBar(
          '${_qty.toInt()} token(s) comprado(s) com sucesso!');
      setState(() => _qty = 1);
    } catch (e) {
      _showSnackBar(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true);
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
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        backgroundColor:
            isError ? const Color(0xFFE74C3C) : StartupColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
