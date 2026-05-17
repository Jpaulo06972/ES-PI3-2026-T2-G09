// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/wallet/services/getListOperation.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/wallet/components/emptyTransactions.dart';
import 'package:mesclainvest_f/wallet/components/operationMapper.dart';
import 'package:mesclainvest_f/wallet/components/statementSummaryBanner.dart';
import 'package:mesclainvest_f/wallet/components/statementFilterChips.dart';
import 'package:mesclainvest_f/wallet/components/groupedTransactionList.dart';

/// Tela de extrato completo no estilo Nubank.
/// Exibe todas as transações do usuário agrupadas por data,
/// com filtros, animações suaves e visual premium.
class StatementPage extends StatefulWidget {
  final UserModel user;

  const StatementPage({super.key, required this.user});

  @override
  State<StatementPage> createState() => _StatementPageState();
}

class _StatementPageState extends State<StatementPage>
    with SingleTickerProviderStateMixin {
  // Serviço para buscar operações do Firestore
  final GetListOperation _operationService = GetListOperation();

  // Lista de transações mapeadas para exibição
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  // Filtro ativo
  String? _selectedFilter;

  // Cor principal da aplicação
  static const Color primaryGreen = Color(0xFF107649);

  // Animação de entrada
  late AnimationController _entryAnimController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  // Opções de filtro disponíveis
  static const Map<String?, String> _filterOptions = {
    null: 'Tudo',
    'deposito': 'Entradas',
    'saque': 'Saques',
    'transferencia': 'Transferências',
    'pagar': 'Pagamentos',
    'investimento': 'Investimentos',
  };

  @override
  void initState() {
    super.initState();

    // Animação suave de entrada (fade + slide)
    _entryAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryAnimController, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entryAnimController, curve: Curves.easeOut),
        );
    _entryAnimController.forward();

    _fetchOperations();
  }

  @override
  void dispose() {
    _entryAnimController.dispose();
    super.dispose();
  }

  /// Busca todas as operações do usuário no Firestore e mapeia para exibição
  Future<void> _fetchOperations() async {
    try {
      setState(() => _isLoading = true);

      final rawData = await _operationService.getOperations(
        userId: widget.user.uid,
      );

      // Ordena por data: mais recente primeiro
      OperationMapper.sortByDateDesc(rawData);

      // Mapeia os dados brutos para o formato visual usando ícones de extrato
      final mapped = OperationMapper.mapOperations(
        rawData: rawData,
        currentUserId: widget.user.uid,
        useStatementIcons: true,
      );

      setState(() {
        _transactions = mapped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Transações filtradas
  List<Map<String, dynamic>> get _filteredTransactions {
    if (_selectedFilter == null) return _transactions;
    return _transactions.where((tx) => tx['type'] == _selectedFilter).toList();
  }

  /// Calcula o total de entradas e saídas
  double get _totalEntradas {
    return _filteredTransactions
        .where((tx) => tx['isCredit'] == true)
        .fold(0.0, (total, tx) => total + (tx['value'] as double));
  }

  double get _totalSaidas {
    return _filteredTransactions
        .where((tx) => tx['isCredit'] == false)
        .fold(0.0, (total, tx) => total + (tx['value'] as double));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;

    return Scaffold(
      // ── AppBar estilo Nubank ──────────────────────────────────────
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Extrato',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: Column(
            children: [
              // ── Banner superior verde com resumo ────────────────────
              StatementSummaryBanner(
                saldo: widget.user.saldo,
                totalEntradas: _totalEntradas,
                totalSaidas: _totalSaidas,
              ),

              const SizedBox(height: 16),

              // ── Chips de filtro horizontais ────────────────────────
              StatementFilterChips(
                filterOptions: _filterOptions,
                selectedFilter: _selectedFilter,
                onFilterSelected: (key) {
                  setState(() {
                    _selectedFilter = key;
                  });
                },
              ),

              const SizedBox(height: 12),

              // ── Lista de transações agrupada por data ──────────────
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: primaryGreen),
                      )
                    : filtered.isEmpty
                    ? const EmptyTransactions()
                    : GroupedTransactionList(transactions: filtered),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
