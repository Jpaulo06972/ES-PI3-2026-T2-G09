import 'package:flutter/material.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/model/offerModel.dart';
import 'package:mesclainvest_f/counter/services/counterService.dart';

class MultiSellerPurchaseSheet extends StatefulWidget {
  final String startupId;
  final String startupName;
  final UserModel userModel;
  final OfferModel initialTargetOffer;

  const MultiSellerPurchaseSheet({
    super.key,
    required this.startupId,
    required this.startupName,
    required this.userModel,
    required this.initialTargetOffer,
  });

  @override
  State<MultiSellerPurchaseSheet> createState() => _MultiSellerPurchaseSheetState();
}

class _MultiSellerPurchaseSheetState extends State<MultiSellerPurchaseSheet> {
  final CounterService _service = CounterService();
  double _qty = 1;
  List<OfferModel> _activeSellOffers = [];
  bool _loadingOffers = true;

  List<Map<String, dynamic>> _simulation = [];
  double _totalCost = 0.0;
  bool _insufficientOffers = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _qty = widget.initialTargetOffer.quantidade;
    _fetchSellOffersAndSimulate();
  }

  Future<void> _fetchSellOffersAndSimulate() async {
    setState(() => _loadingOffers = true);
    try {
      final list = await _service.getVendaForStartup(widget.startupId);
      // Ordena por preço crescente
      list.sort((a, b) => a.precoPorToken.compareTo(b.precoPorToken));
      if (mounted) {
        setState(() {
          _activeSellOffers = list;
          _loadingOffers = false;
          _runSimulation(_qty);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingOffers = false);
    }
  }

  void _runSimulation(double qty) {
    _simulation = [];
    _totalCost = 0.0;
    _insufficientOffers = false;

    if (qty <= 0) return;

    double remaining = qty;
    for (final offer in _activeSellOffers) {
      if (remaining <= 0) break;
      // Impede comprar de si mesmo
      if (offer.vendedorId == widget.userModel.uid) continue;

      double fill = remaining < offer.quantidade ? remaining : offer.quantidade;
      double cost = fill * offer.precoPorToken;

      _simulation.add({
        'sellerName': offer.vendedorNome.isNotEmpty && offer.vendedorNome != 'Outro Usuário'
            ? offer.vendedorNome
            : 'Vendedor #${offer.vendedorId.substring(0, 4).toUpperCase()}',
        'quantity': fill,
        'price': offer.precoPorToken,
        'total': cost
      });

      _totalCost += cost;
      remaining -= fill;
    }

    if (remaining > 0) {
      _insufficientOffers = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double availableBalance = widget.userModel.saldo;
    final bool hasBalance = availableBalance >= _totalCost;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E22),
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
                        const Text(
                          'COMPRAR DO LIVRO DE ORDENS',
                          style: TextStyle(
                            color: Color(0xFF1A9B5F),
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

              // Quantity Inputs
              const Text(
                'Quantidade que deseja comprar',
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
                    color: const Color(0xFF107649).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    _buildStepBtn(
                      icon: Icons.remove,
                      onTap: () {
                        if (_qty > 1) {
                          setState(() {
                            _qty--;
                            _runSimulation(_qty);
                          });
                        }
                      },
                    ),
                    Expanded(
                      child: Text(
                        _qty.toInt().toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _buildStepBtn(
                      icon: Icons.add,
                      onTap: () {
                        setState(() {
                          _qty++;
                          _runSimulation(_qty);
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Simulation / Breakdown Section
              const Text(
                'Simulação de Casamento (Menor Preço Primeiro):',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _loadingOffers
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(color: Color(0xFF1A9B5F)),
                      ),
                    )
                  : Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: _simulation.map((sim) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    sim['sellerName'],
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                  Text(
                                    '${sim['quantity'].toInt()} t × R\$ ${sim['price'].toStringAsFixed(2).replaceAll('.', ',')} = R\$ ${sim['total'].toStringAsFixed(2).replaceAll('.', ',')}',
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

              if (_insufficientOffers)
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFFF5A623), size: 14),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Atenção: Ofertas insuficientes no Balcão. Compra será preenchida parcialmente.',
                          style: TextStyle(color: Color(0xFFF5A623), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white10),

              // Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Estimado:', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(
                    'R\$ ${_totalCost.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(color: Color(0xFF1A9B5F), fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Seu saldo disponível:', style: TextStyle(color: Colors.white38, fontSize: 13)),
                  Text(
                    'R\$ ${availableBalance.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (!hasBalance)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFE74C3C), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Saldo disponível insuficiente.',
                        style: TextStyle(color: Color(0xFFE74C3C), fontSize: 13),
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

              // Confirm button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasBalance && !_isSubmitting && _qty > 0
                        ? const Color(0xFF107649)
                        : Colors.white12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: hasBalance && !_isSubmitting && _qty > 0 ? _confirmPurchase : null,
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
                          'Confirmar Compra',
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
        child: Icon(icon, color: const Color(0xFF107649), size: 22),
      ),
    );
  }

  void _confirmPurchase() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await _service.buyFromOrders(widget.startupId, _qty);
      if (result['success'] == true) {
        setState(() {
          widget.userModel.saldo = widget.userModel.saldo - (result['totalPaid'] as double);
        });
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Falha ao processar a compra de ofertas.';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocorreu um erro ao processar: $e';
        _isSubmitting = false;
      });
    }
  }
}
