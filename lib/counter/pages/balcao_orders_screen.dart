import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/counter/components/place_buy_offer_sheet.dart';
import 'package:mesclainvest_f/startups/components/startup_colors.dart';
import 'package:mesclainvest_f/counter/services/trading_logic_service.dart';

class BalcaoOrdersScreen extends StatefulWidget {
  final String startupId;
  final String startupName;
  final UserModel userModel;

  const BalcaoOrdersScreen({
    super.key,
    required this.startupId,
    required this.startupName,
    required this.userModel,
  });

  @override
  State<BalcaoOrdersScreen> createState() => _BalcaoOrdersScreenState();
}

class _BalcaoOrdersScreenState extends State<BalcaoOrdersScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  // Form Fields
  String _orderType = 'Limitada'; // 'Limitada' or 'Mercado'
  double _qty = 10;
  double _price = 0.0;
  String _validity = 'Hoje'; // 'Hoje', '7 dias', '30 dias'

  final TextEditingController _priceCtrl = TextEditingController();

  double _userBrlBalance = 0.0;
  double _userTokenHolding = 0.0;
  double _currentMarketPrice = 1.0;
  
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialMarketPrice();
    _priceCtrl.text = _price.toStringAsFixed(2).replaceAll('.', ',');
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
        setState(() {
          _currentMarketPrice = cents > 0 ? cents / 100 : 1.0;
          _price = _currentMarketPrice;
          _priceCtrl.text = _price.toStringAsFixed(2).replaceAll('.', ',');
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final double totalEstimated = _qty * _price;

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(widget.userModel.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final data = userSnapshot.data!.data() as Map<String, dynamic>;
          _userBrlBalance = (data['saldo'] ?? data['balance'] ?? 0.0).toDouble();
        } else {
          _userBrlBalance = widget.userModel.saldo;
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('startups')
              .doc(widget.startupId)
              .collection('investors')
              .doc(widget.userModel.uid)
              .snapshots(),
          builder: (context, investorSnapshot) {
            if (investorSnapshot.hasData && investorSnapshot.data!.exists) {
              final data = investorSnapshot.data!.data() as Map<String, dynamic>;
              _userTokenHolding = (data['tokens'] ?? 0.0).toDouble();
            } else {
              _userTokenHolding = 0.0;
            }

            return Scaffold(
              backgroundColor: StartupColors.pageBg,
              appBar: AppBar(
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
                    const Text(
                      'Negociações no Balcão',
                      style: TextStyle(
                        color: StartupColors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        children: [
                          // 1. Tipo de ordem dropdown
                          _buildFieldLabel('Tipo de ordem'),
                          _buildDropdownBorder(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _orderType,
                                dropdownColor: StartupColors.cardBg,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                                isExpanded: true,
                                items: ['Limitada', 'Mercado'].map((String val) {
                                  return DropdownMenuItem<String>(
                                    value: val,
                                    child: Text(val),
                                  );
                                }).toList(),
                                onChanged: (newVal) {
                                  if (newVal != null) {
                                    setState(() {
                                      _orderType = newVal;
                                      if (_orderType == 'Mercado') {
                                        _price = _currentMarketPrice;
                                        _priceCtrl.text = _price.toStringAsFixed(2).replaceAll('.', ',');
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 2. Quantity stepper row
                          _buildFieldLabel('Quantidade'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFF141416),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.06)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text('Qtd ', style: TextStyle(color: Colors.white38, fontSize: 14)),
                                    Text(
                                      _qty.toInt().toString(),
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, color: StartupColors.green, size: 20),
                                      onPressed: () {
                                        if (_qty > 1) {
                                          setState(() => _qty--);
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.add, color: StartupColors.green, size: 20),
                                      onPressed: () {
                                        setState(() => _qty++);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 3. Preço por token input + Validade dropdown
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel('Preço de compra'),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF141416),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                                      ),
                                      child: TextField(
                                        controller: _priceCtrl,
                                        enabled: _orderType == 'Limitada',
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        style: TextStyle(
                                          color: _orderType == 'Limitada' ? Colors.white : Colors.white38,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          prefixText: 'R\$ ',
                                          prefixStyle: TextStyle(color: Colors.white38, fontSize: 15),
                                        ),
                                        onChanged: (val) {
                                          final cleanVal = val.replaceAll(',', '.');
                                          setState(() {
                                            _price = double.tryParse(cleanVal) ?? 0.0;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel('Validade'),
                                    _buildDropdownBorder(
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _validity,
                                          dropdownColor: StartupColors.cardBg,
                                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                                          isExpanded: true,
                                          items: ['Hoje', '7 dias', '30 dias'].map((String val) {
                                            return DropdownMenuItem<String>(
                                              value: val,
                                              child: Text(val),
                                            );
                                          }).toList(),
                                          onChanged: (newVal) {
                                            if (newVal != null) {
                                              setState(() => _validity = newVal);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 4. Info rows: Saldo disponível, Valor estimado
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Saldo disponível', style: TextStyle(color: Colors.white54, fontSize: 13)),
                              Text(
                                'R\$ ${_userBrlBalance.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Valor estimado', style: TextStyle(color: Colors.white54, fontSize: 13)),
                              Text(
                                'R\$ ${totalEstimated.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: const TextStyle(color: StartupColors.green, fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 5. Embedded tabs (Posição | Ofertas | Ordens)
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06), width: 1)),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicatorColor: StartupColors.green,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicatorWeight: 2.5,
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.white38,
                              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              dividerColor: Colors.transparent,
                              tabs: const [
                                Tab(text: 'Posição'),
                                Tab(text: 'Ofertas'),
                                Tab(text: 'Ordens'),
                              ],
                            ),
                          ),

                          // Tab contents container
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
                      ),
                    ),

                    // Bottom: "Vender" and "Comprar" buttons side by side
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: StartupColors.cardBg,
                        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.04))),
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
                                    side: const BorderSide(color: Color(0xFFE74C3C), width: 1),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _isProcessing ? null : () => _placeOrder('sell'),
                                child: _isProcessing 
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFFE74C3C), strokeWidth: 2))
                                    : const Text(
                                        'Vender',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
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
                                onPressed: _isProcessing ? null : () => _placeOrder('buy'),
                                child: _isProcessing 
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text(
                                        'Comprar',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildDropdownBorder({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: child,
    );
  }

  // ──── TAB 1: POSIÇÃO ────
  Widget _buildPosicaoTab() {
    final double valorPosicao = _userTokenHolding * _currentMarketPrice;
    final double simulatedAvgPrice = _currentMarketPrice * 0.9;
    final double simulatedProfitLoss = valorPosicao * 0.1;
    final double simulatedProfitPercent = 10.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141416),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPosicaoRow('Posição', 'R\$ ${valorPosicao.toStringAsFixed(2).replaceAll('.', ',')}', isBig: true),
            const Divider(color: Colors.white10, height: 20),
            _buildPosicaoRow('Quantidade', '${_userTokenHolding.toInt()} tokens'),
            const SizedBox(height: 8),
            _buildPosicaoRow('Preço Médio', 'R\$ ${simulatedAvgPrice.toStringAsFixed(2).replaceAll('.', ',')}'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lucro/Perda', style: TextStyle(color: Colors.white38, fontSize: 13)),
                Text(
                  '+ R\$ ${simulatedProfitLoss.toStringAsFixed(2).replaceAll('.', ',')} | + ${simulatedProfitPercent.toStringAsFixed(2)}%',
                  style: const TextStyle(color: StartupColors.green, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosicaoRow(String label, String value, {bool isBig = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isBig ? 17 : 14,
            fontWeight: isBig ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ──── TAB 2: OFERTAS (ORDER BOOK) ────
  Widget _buildOfertasTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('offers')
          .where('startupId', isEqualTo: widget.startupId)
          .where('status', isEqualTo: 'open')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: StartupColors.green));
        }

        final offers = snapshot.data?.docs ?? [];
        if (offers.isEmpty) {
          return const Center(
            child: Text(
              'Sem outras ofertas ativas no mercado.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          );
        }

        // Ordena: compras decrescentes, vendas crescentes
        final buyOffers = offers.where((doc) => doc['type'] == 'buy').toList();
        final sellOffers = offers.where((doc) => doc['type'] == 'sell').toList();

        buyOffers.sort((a, b) => (b['pricePerToken'] as num).compareTo(a['pricePerToken'] as num));
        sellOffers.sort((a, b) => (a['pricePerToken'] as num).compareTo(b['pricePerToken'] as num));

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            if (sellOffers.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('Ofertas de Venda (Pedindo)', style: TextStyle(color: Color(0xFFE74C3C), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              ...sellOffers.map((doc) => _buildBookItem(doc, isBuy: false)),
            ],
            if (buyOffers.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('Ofertas de Compra (Pagando)', style: TextStyle(color: StartupColors.green, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              ...buyOffers.map((doc) => _buildBookItem(doc, isBuy: true)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBookItem(DocumentSnapshot doc, {required bool isBuy}) {
    final data = doc.data() as Map<String, dynamic>;
    final double price = (data['pricePerToken'] ?? 0.0).toDouble();
    final double qty = (data['remainingQuantity'] ?? data['quantity'] ?? 0.0).toDouble();
    final double total = qty * price;
    final String ownerId = data['userId'] ?? '';

    final bool isOurs = ownerId == widget.userModel.uid;

    return InkWell(
      onTap: () {
        setState(() {
          _qty = qty;
          _price = price;
          _priceCtrl.text = _price.toStringAsFixed(2).replaceAll('.', ',');
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isOurs ? Colors.white.withOpacity(0.03) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isOurs ? StartupColors.green.withOpacity(0.15) : Colors.transparent),
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
                    color: isBuy ? StartupColors.green : const Color(0xFFE74C3C),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${qty.toInt()} tokens',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                if (isOurs) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: StartupColors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                    child: const Text('MEU', style: TextStyle(color: StartupColors.green, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            Row(
              children: [
                Text(
                  'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 14),
                Text(
                  'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ──── TAB 3: MINHAS ORDENS ────
  Widget _buildOrdensTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('offers')
          .where('userId', isEqualTo: widget.userModel.uid)
          .where('startupId', isEqualTo: widget.startupId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: StartupColors.green));
        }

        final userOffers = snapshot.data?.docs ?? [];
        if (userOffers.isEmpty) {
          return const Center(
            child: Text(
              'Nenhuma oferta registrada por você.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          );
        }

        // Ordena por timestamp decrescente
        final sortedOffers = List<DocumentSnapshot>.from(userOffers)
          ..sort((a, b) {
            final tA = a['timestamp'] as Timestamp?;
            final tB = b['timestamp'] as Timestamp?;
            if (tA == null) return 1;
            if (tB == null) return -1;
            return tB.compareTo(tA);
          });

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: sortedOffers.length,
          itemBuilder: (context, index) {
            final offerDoc = sortedOffers[index];
            final data = offerDoc.data() as Map<String, dynamic>;
            final String id = offerDoc.id;
            final double price = (data['pricePerToken'] ?? 0.0).toDouble();
            final double qty = (data['quantity'] ?? 0.0).toDouble();
            final double remQty = (data['remainingQuantity'] ?? 0.0).toDouble();
            final double total = qty * price;
            final String type = data['type'] ?? 'buy';
            final String status = data['status'] ?? 'open';

            final bool isBuy = type == 'buy';
            final bool isOpen = status == 'open';

            Color statusColor = StartupColors.green;
            String statusLabel = 'Ativa';
            if (status == 'filled') {
              statusColor = const Color(0xFF4A90E2);
              statusLabel = 'Executada';
            } else if (status == 'cancelled') {
              statusColor = Colors.white38;
              statusLabel = 'Cancelada';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF141416),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
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
                                color: isBuy ? StartupColors.green : const Color(0xFFE74C3C),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isBuy ? 'COMPRA' : 'VENDA',
                              style: TextStyle(
                                color: isBuy ? StartupColors.green : const Color(0xFFE74C3C),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('${qty.toInt()} tokens', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(width: 6),
                            Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(
                              'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}/t',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                        if (isOpen && remQty < qty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Parcialmente executada: ${(qty - remQty).toInt()} de ${qty.toInt()}',
                            style: const TextStyle(color: StartupColors.green, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          'Total: R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  if (isOpen)
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE74C3C).withOpacity(0.12),
                          foregroundColor: const Color(0xFFE74C3C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFFE74C3C), width: 1),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () => _confirmCancelOffer(id, type, remQty, price),
                        child: const Text('Cancelar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmCancelOffer(String offerId, String type, double remainingQty, double pricePerToken) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        title: const Text('Cancelar Oferta', style: TextStyle(color: Colors.white)),
        content: Text(
          type == 'buy'
              ? 'Deseja realmente cancelar esta oferta de compra? R\$ ${(remainingQty * pricePerToken).toStringAsFixed(2).replaceAll('.', ',')} serão estornados ao seu saldo disponível.'
              : 'Deseja realmente cancelar esta oferta de venda? Os ${remainingQty.toInt()} tokens não casados serão estornados à sua carteira de investimentos.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Voltar', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _cancelOffer(offerId, type, remainingQty, pricePerToken);
            },
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _cancelOffer(String offerId, String type, double remainingQty, double pricePerToken) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final offerRef = _firestore.collection('offers').doc(offerId);
        final offerSnapshot = await transaction.get(offerRef);
        if (!offerSnapshot.exists) throw Exception("Oferta não encontrada.");

        final offerData = offerSnapshot.data()!;
        if (offerData['status'] != 'open') {
          throw Exception("Esta oferta já não está mais ativa.");
        }

        final userRef = _firestore.collection('users').doc(widget.userModel.uid);
        final userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) throw Exception("Conta de usuário não encontrada.");
        
        final double userBrl = (userSnapshot.data()!['saldo'] ?? userSnapshot.data()!['balance'] ?? 0.0).toDouble();

        final investorRef = _firestore
            .collection('startups')
            .doc(widget.startupId)
            .collection('investors')
            .doc(widget.userModel.uid);
        final investorSnapshot = await transaction.get(investorRef);
        final double userTokens = investorSnapshot.exists
            ? (investorSnapshot.data()!['tokens'] ?? 0.0).toDouble()
            : 0.0;

        if (type == 'buy') {
          final double refundBrl = remainingQty * pricePerToken;
          transaction.update(userRef, {
            'saldo': userBrl + refundBrl,
            'balance': userBrl + refundBrl,
          });
        } else {
          transaction.set(investorRef, {
            'userId': widget.userModel.uid,
            'startupId': widget.startupId,
            'tokens': userTokens + remainingQty,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        transaction.update(offerRef, {
          'status': 'cancelled',
        });
      });

      _showSnackBar("Oferta cancelada com sucesso!");
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _placeOrder(String type) async {
    if (_qty <= 0 || _price <= 0) {
      _showSnackBar("Quantidade e preço devem ser maiores que zero", isError: true);
      return;
    }

    setState(() => _isProcessing = true);
    try {
      if (type == 'buy') {
        await TradingLogicService().placeBuyOrder(
          userId: widget.userModel.uid,
          startupId: widget.startupId,
          startupNome: widget.startupName,
          qty: _qty,
          price: _price,
        );
        _showSnackBar('Oferta de compra registrada com sucesso!');
      } else {
        await TradingLogicService().placeSellOrder(
          userId: widget.userModel.uid,
          startupId: widget.startupId,
          startupNome: widget.startupName,
          qty: _qty,
          price: _price,
        );
        _showSnackBar('Oferta de venda registrada com sucesso!');
      }
      
      // Limpa os campos após sucesso
      setState(() {
        _qty = 10; // ou o valor padrão
        if (_orderType == 'Mercado') {
          _price = _currentMarketPrice;
          _priceCtrl.text = _price.toStringAsFixed(2).replaceAll('.', ',');
        }
      });
      
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isError ? const Color(0xFFE74C3C) : StartupColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
