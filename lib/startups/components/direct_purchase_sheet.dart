import 'package:flutter/material.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/counter/services/counterService.dart';

class DirectPurchaseSheet extends StatefulWidget {
  final String startupId;
  final String startupName;
  final double pricePerToken;
  final UserModel userModel;
  final double userHoldings;

  const DirectPurchaseSheet({
    super.key,
    required this.startupId,
    required this.startupName,
    required this.pricePerToken,
    required this.userModel,
    required this.userHoldings,
  });

  @override
  State<DirectPurchaseSheet> createState() => _DirectPurchaseSheetState();
}

class _DirectPurchaseSheetState extends State<DirectPurchaseSheet> {
  final CounterService _service = CounterService();
  double _qty = 1;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final double totalCost = _qty * widget.pricePerToken;
    final double availableBalance = widget.userModel.saldo;
    final bool hasBalance = availableBalance >= totalCost;

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
                          'COMPRA DIRETA DA STARTUP',
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
              const SizedBox(height: 24),

              // Info Cards (Preço por token + Seus tokens)
              Row(
                children: [
                  Expanded(
                    child: _buildInfoBox(
                      'Preço por token',
                      'R\$ ${widget.pricePerToken.toStringAsFixed(2).replaceAll('.', ',')}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoBox(
                      'Seus tokens',
                      widget.userHoldings.toInt().toString(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stepper / Quantity Input
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
                    color: const Color(0xFF107649).withOpacity(0.3),
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
                          fontSize: 22,
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
              const SizedBox(height: 24),

              // Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141416),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      'Total a pagar',
                      'R\$ ${totalCost.toStringAsFixed(2).replaceAll('.', ',')}',
                      highlight: true,
                    ),
                    const SizedBox(height: 10),
                    _buildSummaryRow(
                      'Saldo disponível',
                      'R\$ ${availableBalance.toStringAsFixed(2).replaceAll('.', ',')}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Error or Warning Display
              if (!hasBalance)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFE74C3C), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Saldo disponível insuficiente',
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

              // Action button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasBalance && !_isSubmitting
                        ? const Color(0xFF107649)
                        : Colors.white12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: hasBalance && !_isSubmitting ? _confirmPurchase : null,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Confirmar Compra',
                          style: TextStyle(
                            color: hasBalance && !_isSubmitting ? Colors.white : Colors.white38,
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

  Widget _buildInfoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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

  Widget _buildSummaryRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: highlight ? const Color(0xFF1A9B5F) : Colors.white,
            fontSize: 14,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _confirmPurchase() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await _service.buyTokens(widget.startupId, _qty);
      if (result['success'] == true) {
        // Atualiza o saldo do usuário localmente
        setState(() {
          widget.userModel.saldo = result['updatedBalance'];
        });
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Falha ao processar compra de tokens.';
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
