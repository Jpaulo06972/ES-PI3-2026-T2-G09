// Grupo: G09
// Trabalho: PI3-2026-T2-G09

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/counter/components/counterToggle.dart';
import 'package:mesclainvest_f/counter/services/counterService.dart';
import 'package:mesclainvest_f/model/offerModel.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/startups/components/startup_colors.dart';

class CreateOfferPage extends StatefulWidget {
  final UserModel user;
  final CounterService service;

  const CreateOfferPage({
    super.key,
    required this.user,
    required this.service,
  });

  @override
  State<CreateOfferPage> createState() => _CreateOfferPageState();
}

class _CreateOfferPageState extends State<CreateOfferPage> {
  int _tabIndex = 0; // 0=Comprar 1=Vender
  String _selectedStartup = 'EcoTech PUC';
  String _selectedStartupId = 'startup_eco';
  double _quantidade = 50;
  final TextEditingController _precoController =
      TextEditingController(text: '1,45');

  static const List<Map<String, String>> _startups = [
    {'nome': 'EcoTech PUC', 'id': 'startup_eco'},
    {'nome': 'MedConnect', 'id': 'startup_med'},
    {'nome': 'AgriSmart', 'id': 'startup_agri'},
    {'nome': 'FinEduca', 'id': 'startup_fin'},
  ];

  @override
  void dispose() {
    _precoController.dispose();
    super.dispose();
  }

  double get _preco {
    final raw = _precoController.text
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(raw) ?? 0.0;
  }

  double get _total => _quantidade * _preco;

  void _submit() {
    if (_quantidade <= 0 || _preco <= 0) {
      _showSnackBar('Preencha todos os campos corretamente.', isError: true);
      return;
    }

    final offer = OfferModel(
      id: 'offer_${DateTime.now().millisecondsSinceEpoch}',
      startupId: _selectedStartupId,
      startupNome: _selectedStartup,
      vendedorId: widget.user.uid,
      vendedorNome: widget.user.firstName,
      quantidade: _quantidade,
      precoPorToken: _preco,
      tipo: _tabIndex == 0 ? OrderType.compra : OrderType.venda,
      criadoEm: DateTime.now(),
    );

    widget.service.addOffer(offer);
    _showSnackBar('Oferta publicada com sucesso!');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StartupColors.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Balcão',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                'Nova Oferta',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CounterToggle(
              selectedIndex: _tabIndex,
              onChanged: (i) => setState(() => _tabIndex = i),
              tabs: const ['Comprar', 'Vender'],
            ),

            const SizedBox(height: 28),

            // ── Startup ────────────────────────────────────────────────────
            const _FieldLabel(text: 'Startup'),
            const SizedBox(height: 8),
            _buildDropdown(),

            const SizedBox(height: 24),

            // ── Quantidade ─────────────────────────────────────────────────
            const _FieldLabel(text: 'Quantidade de tokens'),
            const SizedBox(height: 8),
            _buildQuantityInput(),

            const SizedBox(height: 24),

            // ── Preço ──────────────────────────────────────────────────────
            const _FieldLabel(text: 'Preço por token (R\$)'),
            const SizedBox(height: 8),
            _buildPriceInput(),

            const SizedBox(height: 28),

            // ── Resumo ─────────────────────────────────────────────────────
            _buildSummary(),

            const SizedBox(height: 28),

            // ── Botão ──────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF107649),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _submit,
                child: Text(
                  _tabIndex == 0
                      ? 'Publicar Ordem de Compra'
                      : 'Publicar Ordem de Venda',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF262629),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStartup,
          isExpanded: true,
          dropdownColor: const Color(0xFF262629),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          items: _startups
              .map((s) => DropdownMenuItem(
                    value: s['nome'],
                    child: Text(s['nome']!),
                  ))
              .toList(),
          onChanged: (val) {
            if (val == null) return;
            final match =
                _startups.firstWhere((s) => s['nome'] == val);
            setState(() {
              _selectedStartup = match['nome']!;
              _selectedStartupId = match['id']!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildQuantityInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF262629),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF107649).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          _buildStepButton(
            Icons.remove,
            () {
              if (_quantidade > 1) setState(() => _quantidade--);
            },
          ),
          Expanded(
            child: Text(
              _quantidade.toInt().toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _buildStepButton(
            Icons.add,
            () => setState(() => _quantidade++),
          ),
        ],
      ),
    );
  }

  Widget _buildStepButton(IconData icon, VoidCallback onTap) {
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

  Widget _buildPriceInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF262629),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF107649).withValues(alpha: 0.4)),
      ),
      child: TextField(
        controller: _precoController,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
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
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF262629),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Tokens',
            value: '${_quantidade.toInt()}',
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Preço/token',
            value:
                'R\$ ${_preco.toStringAsFixed(2).replaceAll('.', ',')}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Color(0xFF3A3A3A), height: 1),
          ),
          _SummaryRow(
            label: 'Total estimado',
            value:
                'R\$ ${_total.toStringAsFixed(2).replaceAll('.', ',')}',
            highlight: true,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Saldo atual',
            value:
                'R\$ ${widget.user.saldo.toStringAsFixed(2).replaceAll('.', ',')}',
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
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor:
            isError ? const Color(0xFFE74C3C) : const Color(0xFF107649),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SummaryRow({
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
            fontWeight:
                highlight ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
