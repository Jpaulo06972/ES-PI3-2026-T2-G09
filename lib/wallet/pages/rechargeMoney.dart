// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesclainvest_f/components/appBar.dart';
import 'package:mesclainvest_f/components/navBar.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/wallet/components/saldoCard.dart';
import 'package:mesclainvest_f/wallet/components/quickActions.dart';
import 'package:mesclainvest_f/wallet/components/quickRecharge.dart';
import 'package:mesclainvest_f/wallet/components/transactionHistory.dart';
import 'package:mesclainvest_f/wallet/components/animatedCrossFade.dart';
import 'package:mesclainvest_f/wallet/components/walletHeader.dart';
import 'package:mesclainvest_f/wallet/components/statementHeader.dart';
import 'package:mesclainvest_f/wallet/components/emptyTransactions.dart';
import 'package:mesclainvest_f/wallet/components/operationMapper.dart';
import 'package:mesclainvest_f/wallet/services/getListOperation.dart';
import 'package:mesclainvest_f/enum/typeOfOperation.dart';
import 'package:mesclainvest_f/wallet/services/operationService.dart';
import 'package:mesclainvest_f/wallet/pages/transactionActionPage.dart';
import 'package:mesclainvest_f/wallet/pages/statementPage.dart';

/// Tela principal da Carteira Digital.
/// Permite gerenciar o saldo, realizar depósitos, pagamentos e visualizar o histórico.
class RechargeMoneyPage extends StatefulWidget {
  final UserModel user; // Usuário logado recebido da navegação

  const RechargeMoneyPage({super.key, required this.user});

  @override
  State<RechargeMoneyPage> createState() =>
      _RechargeMoneyPageState(userModel: user);
}

class _RechargeMoneyPageState extends State<RechargeMoneyPage> {
  final UserModel
  userModel; // Instância local do usuário para manipulação de estado

  // Getter para facilitar o acesso ao saldo atualizado
  double get saldo => userModel.saldo;

  // Instância do serviço de comandos (escrita)
  final OperationService _operationCommandService = OperationService();

  // Função para aumentar o saldo (Depósito) enviando para o backend
  Future<void> setRecharge(double money) async {
    final success = await _operationCommandService.createOperation(
      amount: money,
      type: TypeOfOperation.deposito,
      text: "Depósito via App",
    );

    if (success) {
      await _refreshUserBalance(); // Sincroniza o saldo real do banco
      _fetchOperations(); // Recarrega o histórico dinâmico
    } else {
      _showSnackBar("Erro ao processar depósito no servidor.");
    }
  }

  // Função para diminuir o saldo (Pagamento/Investimento) enviando para o backend
  Future<void> setPay(double money) async {
    final success = await _operationCommandService.createOperation(
      amount: money,
      type: TypeOfOperation.pagar,
      text: "Pagamento realizado",
    );

    if (success) {
      await _refreshUserBalance(); // Sincroniza o saldo real do banco
      _fetchOperations(); // Recarrega o histórico dinâmico
    } else {
      _showSnackBar("Erro ao processar pagamento no servidor.");
    }
  }

  // Controle de visibilidade do saldo (ícone do olho)
  bool _saldoVisible = true;

  // Valor selecionado nos botões de recarga rápida
  double? _selectedQuickValue;

  // Função para recarregar o saldo do usuário diretamente do Firestore
  Future<void> _refreshUserBalance() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userModel.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          // Atualiza o saldo local baseado no campo 'saldo' (prioritário) ou 'balance' do banco
          userModel.saldo = (data['saldo'] ?? data['balance'] ?? 0.0)
              .toDouble();
        });
      }
    } catch (e) {
      //debugPrint("Erro ao atualizar saldo: $e");
    }
  }

  void _navigateToTransaction(TypeOfOperation type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TransactionActionPage(user: userModel, type: type),
      ),
    );

    if (result == true) {
      // Se a transação foi concluída, recarregamos o histórico e o saldo real
      _fetchOperations();
      await _refreshUserBalance();
    }
  }

  // Controller do campo de entrada de valor manual
  final TextEditingController _customValueController = TextEditingController();

  // Filtro ativo no histórico de transações
  String? _selectedFilter;

  // Controle de exibição do painel de filtros
  bool _showFilters = false;

  // Opções disponíveis no filtro de transações
  static const Map<String?, String> _filterOptions = {
    null: 'Todas',
    'deposito': 'Depósitos',
    'saque': 'Saques',
    'transferencia': 'Transferências',
  };

  // Instância do serviço para buscar dados do backend
  final GetListOperation _operationService = GetListOperation();

  // Histórico de transações carregado do servidor
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOperations(); // Inicia a busca das transações ao abrir a tela
  }

  /// Busca as operações do usuário no backend e mapeia para o formato visual esperado
  Future<void> _fetchOperations() async {
    try {
      setState(() => _isLoading = true);

      final rawData = await _operationService.getOperations(
        userId: userModel.uid,
      );

      // Ordena por data: mais recente primeiro
      OperationMapper.sortByDateDesc(rawData);

      // Mapeia os dados brutos para o formato visual usando ícones da carteira principal
      final mapped = OperationMapper.mapOperations(
        rawData: rawData,
        currentUserId: userModel.uid,
        useStatementIcons: false,
      );

      setState(() {
        _transactions = mapped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Erro ao carregar extrato dinâmico.");
      //debugPrint("Erro GetListOperation: $e");
    }
  }

  _RechargeMoneyPageState({required this.userModel});

  @override
  void dispose() {
    // Limpeza de recursos para evitar lentidão
    _customValueController.dispose();
    super.dispose();
  }

  // Lógica de filtragem das transações em tempo real
  List<Map<String, dynamic>> get _filteredTransactions {
    if (_selectedFilter == null) return _transactions;
    return _transactions.where((tx) => tx['type'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;

    return Scaffold(
      // Cabeçalho customizado com avatar
      appBar: CustomHeader(userModel: userModel),

      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Título e Subtítulo da Página (Componente modularizado)
          const WalletHeader(),

          const SizedBox(height: 28),

          // Componente do Card de Saldo Principal
          SaldoCard(
            saldo: saldo,
            isVisible: _saldoVisible,
            onToggleVisibility: () {
              setState(() {
                _saldoVisible = !_saldoVisible;
              });
            },
          ),

          const SizedBox(height: 24),

          // Barra de Ações Rápidas (Depósito, Sacar, Transferência)
          QuickActions(
            onDepositar: () => _navigateToTransaction(TypeOfOperation.deposito),
            onSacar: () => _navigateToTransaction(TypeOfOperation.saque),
            onTransferir: () =>
                _navigateToTransaction(TypeOfOperation.transferencia),
          ),

          const SizedBox(height: 28),

          // Seção de Recarga Rápida (Chips de valor e confirmação)
          QuickRecharge(
            selectedValue: _selectedQuickValue,
            customValueController: _customValueController,
            onValueSelected: (value) {
              setState(() {
                _selectedQuickValue = value;
                _customValueController.clear();
              });
            },
            onCustomValueChanged: (value) {
              if (value.isNotEmpty) {
                setState(() {
                  _selectedQuickValue = null;
                });
              }
            },
            onConfirm: _handleRechargeConfirm,
          ),

          const SizedBox(height: 32),

          // Cabeçalho do Extrato com Filtro dinâmico (Componente modularizado)
          StatementHeader(
            count: filtered.length,
            showFilters: _showFilters,
            hasActiveFilter: _selectedFilter != null,
            onToggleFilters: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),

          // Lista de Chips de Filtro (Animada)
          FilterCrossFade(
            showFilters: _showFilters,
            filterOptions: _filterOptions,
            selectedFilter: _selectedFilter,
            onFilterSelected: (key) {
              setState(() {
                _selectedFilter = key;
              });
            },
          ),

          const SizedBox(height: 16),

          // Seção que exibe a lista, aviso de "vazio" ou indicador de carregamento
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF107649)),
              ),
            )
          else if (filtered.isEmpty)
            const EmptyTransactions()
          else
            // Componente que renderiza a lista de transações formatada
            TransactionHistory(
              transactions: filtered,
              onViewAll: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StatementPage(user: userModel),
                  ),
                ).then((_) {
                  _fetchOperations();
                  _refreshUserBalance();
                });
              },
            ),

          const SizedBox(height: 30),
        ],
      ),

      // Barra de navegação inferior com foco na Carteira (Índice 3)
      bottomNavigationBar: CustomNavBar(userModel: userModel, currentIndex: 3),
    );
  }

  // ── LÓGICA DE NEGÓCIO E DIÁLOGOS (LEGADOS) ─────────────────────────────────────────

  /// Valida e confirma a recarga feita pela área de QuickRecharge
  void _handleRechargeConfirm() {
    double? valor = _selectedQuickValue;
    // Se não houver chip selecionado, tenta ler o que foi digitado
    if (valor == null && _customValueController.text.isNotEmpty) {
      valor = double.tryParse(_customValueController.text.replaceAll(',', '.'));
    }
    if (valor != null && valor > 0) {
      setRecharge(valor).then((_) {
        setState(() {
          _selectedQuickValue = null;
          _customValueController.clear();
        });
        _showSnackBar("Solicitação de depósito enviada!");
      });
    } else {
      _showSnackBar("Selecione ou digite um valor válido.");
    }
  }

  /// Exibe um feedback visual rápido para o usuário na base da tela
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF107649),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
