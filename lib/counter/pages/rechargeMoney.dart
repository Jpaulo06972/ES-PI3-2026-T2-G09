// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importação básica de UI do Flutter
import 'package:flutter/material.dart';

// Componentes globais do aplicativo (Cabeçalho e Barra de Navegação)
import 'package:mesclainvest_f/components/appBar.dart';
import 'package:mesclainvest_f/components/navBar.dart';

// Modelo de Usuário para gerenciar saldo e perfil
import 'package:mesclainvest_f/model/userModel.dart';

// Componentes modulares da tela de Carteira
import 'package:mesclainvest_f/counter/components/saldoCard.dart';
import 'package:mesclainvest_f/counter/components/quickActions.dart';
import 'package:mesclainvest_f/counter/components/quickRecharge.dart';
import 'package:mesclainvest_f/counter/components/transactionHistory.dart';

// Paleta de cores oficial do projeto MesclaInvest
import 'package:mesclainvest_f/startups/components/startup_colors.dart';

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
  final UserModel userModel; // Instância local do usuário para manipulação de estado

  // Getter para facilitar o acesso ao saldo atualizado
  double get saldo => userModel.saldo;

  // Função para aumentar o saldo (Depósito)
  void setRecharge(double money) {
    setState(() {
      userModel.saldo += money;
    });
  }

  // Função para diminuir o saldo (Pagamento/Investimento)
  void setPay(double money) {
    setState(() {
      userModel.saldo -= money;
    });
  }

  // Controle de visibilidade do saldo (ícone do olho)
  bool _saldoVisible = true;

  // Valor selecionado nos botões de recarga rápida
  double? _selectedQuickValue;

  // Controller do campo de entrada de valor manual
  final TextEditingController _customValueController = TextEditingController();

  // Filtro ativo no histórico de transações
  String? _selectedFilter;

  // Controle de exibição do painel de filtros
  bool _showFilters = false;

  // Atalhos de cores premium do projeto
  static const Color _greenLight = StartupColors.green;

  // Opções disponíveis no filtro de transações
  static const Map<String?, String> _filterOptions = {
    null: 'Todas',
    'deposito': 'Depósitos',
    'investimento': 'Investimentos',
    'rendimento': 'Rendimentos',
  };

  // Histórico de transações (Mock/Simulação para demonstração visual)
  final List<Map<String, dynamic>> _transactions = [
    {
      'icon': Icons.add_circle,
      'title': 'Depósito via Pix',
      'date': '05 Mai 2026',
      'value': 500.00,
      'isCredit': true,
      'type': 'deposito',
    },
    {
      'icon': Icons.rocket_launch,
      'title': 'Investimento — TechNova',
      'date': '03 Mai 2026',
      'value': 150.00,
      'isCredit': false,
      'type': 'investimento',
    },
    {
      'icon': Icons.add_circle,
      'title': 'Depósito via Boleto',
      'date': '01 Mai 2026',
      'value': 1000.00,
      'isCredit': true,
      'type': 'deposito',
    },
    {
      'icon': Icons.rocket_launch,
      'title': 'Investimento — GreenFarm',
      'date': '28 Abr 2026',
      'value': 200.00,
      'isCredit': false,
      'type': 'investimento',
    },
    {
      'icon': Icons.trending_up,
      'title': 'Rendimento CDI',
      'date': '27 Abr 2026',
      'value': 12.35,
      'isCredit': true,
      'type': 'rendimento',
    },
  ];

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
    return _transactions
        .where((tx) => tx['type'] == _selectedFilter)
        .toList();
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
          // Título e Subtítulo da Página
          const Text(
            'Minha Carteira',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Gerencie seu saldo, recarregue e acompanhe seu extrato.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 15,
              height: 1.4,
            ),
          ),

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

          // Barra de Ações Rápidas (Depósito, Pagamento, Transferência)
          QuickActions(
            onDepositar: () => _showRechargeDialog(),
            onPagar: () => _showPayDialog(),
            onTransferir: () => _showSnackBar("Transferência em breve!"),
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

          // Cabeçalho do Extrato com Filtro dinâmico
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Extrato',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Badge com a contagem de itens visíveis
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _greenLight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${filtered.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              // Botão que expande os filtros
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _showFilters || _selectedFilter != null
                        ? _greenLight
                        : const Color(0xFF3A3A3D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: _showFilters || _selectedFilter != null
                        ? Colors.white
                        : Colors.white70,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),

          // Lista de Chips de Filtro (Animada)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _showFilters
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _filterOptions.entries.map((entry) {
                  final key = entry.key;
                  final label = entry.value;
                  final isSelected = _selectedFilter == key;

                  // Cores temáticas para cada tipo de transação
                  Color chipColor;
                  if (key == null) {
                    chipColor = const Color(0xFF4A90E2);
                  } else if (key == 'deposito') {
                    chipColor = _greenLight;
                  } else if (key == 'investimento') {
                    chipColor = const Color(0xFFF5A623);
                  } else {
                    chipColor = const Color(0xFF00B4D8);
                  }

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = key;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? chipColor.withOpacity(0.2)
                            : const Color(0xFF2C2C30),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? chipColor
                              : Colors.white.withOpacity(0.08),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: chipColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? chipColor : Colors.white60,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // Seção que exibe a lista ou aviso de "vazio"
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: Colors.white24, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Nenhuma transação encontrada.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            // Componente que renderiza a lista de transações formatada
            TransactionHistory(
              transactions: filtered,
              onViewAll: () => _showSnackBar("Histórico completo em breve!"),
            ),

          const SizedBox(height: 30),
        ],
      ),

      // Barra de navegação inferior com foco na Carteira (Índice 3)
      bottomNavigationBar: CustomNavBar(userModel: userModel, currentIndex: 3),
    );
  }

  // ── LÓGICA DE NEGÓCIO E DIÁLOGOS ─────────────────────────────────────────

  /// Valida e confirma a recarga feita pela área de QuickRecharge
  void _handleRechargeConfirm() {
    double? valor = _selectedQuickValue;
    // Se não houver chip selecionado, tenta ler o que foi digitado
    if (valor == null && _customValueController.text.isNotEmpty) {
      valor = double.tryParse(_customValueController.text.replaceAll(',', '.'));
    }
    if (valor != null && valor > 0) {
      setRecharge(valor);
      setState(() {
        _selectedQuickValue = null;
        _customValueController.clear();
      });
      _showSnackBar("Depósito de R\$ ${valor.toStringAsFixed(2)} realizado!");
    } else {
      _showSnackBar("Selecione ou digite um valor válido.");
    }
  }

  /// Mostra um pop-up moderno para entrada de valor de depósito
  void _showRechargeDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Depositar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Valor (R\$)",
            hintStyle: const TextStyle(color: Colors.white30),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: StartupColors.green),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              final valor = double.tryParse(controller.text.replaceAll(',', '.'));
              if (valor != null && valor > 0) {
                setRecharge(valor);
                Navigator.pop(ctx);
                _showSnackBar("Depósito de R\$ ${valor.toStringAsFixed(2)} realizado!");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: StartupColors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("Confirmar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Mostra um pop-up moderno para entrada de valor de pagamento com validação de saldo
  void _showPayDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Pagar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Valor (R\$)",
            hintStyle: const TextStyle(color: Colors.white30),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: StartupColors.green),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              final valor = double.tryParse(controller.text.replaceAll(',', '.'));
              if (valor != null && valor > 0 && valor <= saldo) {
                setPay(valor);
                Navigator.pop(ctx);
                _showSnackBar("Pagamento de R\$ ${valor.toStringAsFixed(2)} realizado!");
              } else if (valor != null && valor > saldo) {
                _showSnackBar("Saldo insuficiente!");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: StartupColors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("Confirmar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Exibe um feedback visual rápido para o usuário na base da tela
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: StartupColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
