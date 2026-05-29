import 'package:flutter/material.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/counter/services/counterService.dart';

class SellerApprovalScreen extends StatefulWidget {
  final UserModel userModel;

  const SellerApprovalScreen({super.key, required this.userModel});

  @override
  State<SellerApprovalScreen> createState() => _SellerApprovalScreenState();
}

class _SellerApprovalScreenState extends State<SellerApprovalScreen> {
  final CounterService _service = CounterService();
  List<Map<String, dynamic>> _pendingApprovals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingApprovals();
  }

  Future<void> _loadPendingApprovals() async {
    setState(() => _isLoading = true);
    try {
      final list = await _service.getPendingApprovals();
      if (mounted) {
        setState(() {
          _pendingApprovals = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color greenTheme = Color(0xFF1A9B5F);
    const Color bgTheme = Color(0xFF0B0F0D);
    const Color cardTheme = Color(0xFF161A18);

    return Scaffold(
      backgroundColor: bgTheme,
      appBar: AppBar(
        backgroundColor: cardTheme,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Aprovações Pendentes',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: greenTheme))
            : _pendingApprovals.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: Colors.white24, size: 54),
                          SizedBox(height: 14),
                          Text(
                            'Nenhuma proposta de compra abaixo do mercado para aprovação no momento.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white38, fontSize: 14, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    itemCount: _pendingApprovals.length,
                    itemBuilder: (context, index) {
                      final item = _pendingApprovals[index];
                      final offerId = item['id'].toString();
                      final buyerName = item['buyerName'].toString();
                      final startupName = item['startupName'].toString();
                      final qty = (item['quantity'] as num).toDouble();
                      final offerPrice = (item['pricePerToken'] as num).toDouble();
                      final marketPrice = (item['currentMarketPrice'] as num).toDouble();
                      final discount = (item['discountPercent'] as num).toInt();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardTheme,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withOpacity(0.04)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    startupName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$discount% abaixo',
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Colors.white10, height: 1),
                            const SizedBox(height: 12),
                            _buildInfoRow('Proposta de:', buyerName),
                            const SizedBox(height: 6),
                            _buildInfoRow('Quantidade:', '${qty.toInt()} tokens'),
                            const SizedBox(height: 6),
                            _buildInfoRow(
                              'Preço Ofertado:',
                              'R\$ ${offerPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                              highlight: true,
                            ),
                            const SizedBox(height: 6),
                            _buildInfoRow(
                              'Preço de Mercado:',
                              'R\$ ${marketPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: greenTheme,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        elevation: 0,
                                      ),
                                      onPressed: () => _approveOffer(offerId),
                                      child: const Text(
                                        'Aprovar',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Colors.white24, width: 1.2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () => _rejectOffer(offerId),
                                      child: const Text(
                                        'Recusar',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: highlight ? const Color(0xFF1A9B5F) : Colors.white,
            fontSize: 13,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _approveOffer(String offerId) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        title: const Text('Aprovar Proposta', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Deseja realmente aprovar esta proposta de compra? Os fundos do comprador serão creditados na sua carteira e os correspondentes tokens de venda serão debitados.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A9B5F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final success = await _service.approveOffer(offerId);
              if (success) {
                _loadPendingApprovals();
                _showSnackBar('Proposta aprovada com sucesso!');
              } else {
                _showSnackBar('Falha ao aprovar proposta. Certifique-se de que você tem uma oferta de venda aberta para cobrir o lote.', isError: true);
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _rejectOffer(String offerId) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        title: const Text('Recusar Proposta', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Deseja realmente recusar esta proposta? O saldo reservado do comprador será devolvido à carteira dele imediatamente.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final success = await _service.rejectOffer(offerId);
              if (success) {
                _loadPendingApprovals();
                _showSnackBar('Proposta recusada e removida!');
              } else {
                _showSnackBar('Falha ao recusar proposta.', isError: true);
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isError ? const Color(0xFFE74C3C) : const Color(0xFF107649),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
