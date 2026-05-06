// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote básico de UI do Flutter
import 'package:flutter/material.dart';

// Importa os componentes globais de cabeçalho e barra de navegação
import 'package:mesclainvest_f/components/appBar.dart';
import 'package:mesclainvest_f/components/navBar.dart';

// Importa o modelo de usuário para acessar saldo e dados do usuário logado
import 'package:mesclainvest_f/model/userModel.dart';

// Importa os componentes visuais extraídos da tela de carteira
import 'package:mesclainvest_f/counter/components/saldoCard.dart';
import 'package:mesclainvest_f/counter/components/quickActions.dart';
import 'package:mesclainvest_f/counter/components/quickRecharge.dart';
import 'package:mesclainvest_f/counter/components/transactionHistory.dart';

// Importa a paleta de cores oficial para manter consistência visual com as telas de startups
import 'package:mesclainvest_f/startups/components/startup_colors.dart';

/// Tela de Carteira — exibe saldo, ações rápidas, recarga e extrato de transações.
/// Segue o mesmo padrão visual da tela de Startups (título grande, filtros, lista).
class RechargeMoneyPage extends StatefulWidget {
  // Recebe os dados do usuário logado via construtor
  final UserModel user;

  const RechargeMoneyPage({super.key, required this.user});

  @override
  State<RechargeMoneyPage> createState() =>
      _RechargeMoneyPageState(userModel: user);
}

class _RechargeMoneyPageState extends State<RechargeMoneyPage> {
  // Armazena o modelo do usuário localmente no estado
  final UserModel userModel;

  // Getter que retorna o saldo atual do usuário
  double get saldo => userModel.saldo;

  // Adiciona dinheiro ao saldo (recarga/depósito)
  void setRecharge(double money) {
    setState(() {
      userModel.saldo += money;
    });
  }

  // Subtrai dinheiro do saldo (pagamento)
  void setPay(double money) {
    setState(() {
      userModel.saldo -= money;
    });
  }

  // Controla a visibilidade do saldo (olho aberto/fechado)
  bool _saldoVisible = true;

  // Valor selecionado nos chips de recarga rápida (null = nenhum selecionado)
  double? _selectedQuickValue;

  // Controller para o campo de valor personalizado
  final TextEditingController _customValueController = TextEditingController();

  // Filtro de tipo de transação ativo (null = todas)
  String? _selectedFilter;

  // Controla se o painel de filtros do extrato está expandido
  bool _showFilters = false;

  // Paleta de cores — centralizada em StartupColors para consistência com o resto do app
  static const Color _greenAccent = StartupColors.green;
  static const Color _greenLight = StartupColors.green;

  // Mapa de filtros de tipo de transação (chave = valor técnico, valor = label amigável)
  static const Map<String?, String> _filterOptions = {
    null: 'Todas',
    'deposito': 'Depósitos',
    'investimento': 'Investimentos',
    'rendimento': 'Rendimentos',
  };

  // Lista de transações mockadas para demonstração
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

  // Inicializa o estado com o modelo do usuário recebido
  _RechargeMoneyPageState({required this.userModel});

  @override
  void dispose() {
    // Libera o controller quando a tela é destruída para evitar vazamento de memória
    _customValueController.dispose();
    super.dispose();
  }

  // Filtra a lista de transações pelo tipo selecionado
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
      // Cabeçalho personalizado com avatar e nome do usuário
      appBar: CustomHeader(userModel: userModel),

      body: ListView(
        // Mesmo efeito de scroll elástico da tela de startups
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // ── TÍTULO PRINCIPAL ─────────────────────────────────────────────
          // Mesmo padrão de "Oportunidades Exclusivas" da tela de startups
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

          // ── CARD DO SALDO ─────────────────────────────────────────────────
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

          // ── AÇÕES RÁPIDAS ─────────────────────────────────────────────────
          QuickActions(
            onDepositar: () => _showRechargeDialog(),
            onPagar: () => _showPayDialog(),
            onTransferir: () => _showSnackBar("Transferência em breve!"),
          ),

          const SizedBox(height: 28),

          // ── RECARGA RÁPIDA ────────────────────────────────────────────────
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

          // ── EXTRATO: CABEÇALHO COM BADGE ──────────────────────────────────
          // Mesmo padrão do "Em destaque" + badge de contagem da tela de startups
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
                  // Badge verde com a contagem de transações filtradas
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
              // Botão de filtro — mesma lógica do botão de "tune" da tela de startups
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

          // ── FILTROS DO EXTRATO ────────────────────────────────────────────
          // Chips com animação — mesmo padrão AnimatedCrossFade da tela de startups
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

                  // Cor temática por tipo de operação
                  Color chipColor;
                  if (key == null) {
                    chipColor = const Color(0xFF4A90E2); // Azul para "Todas"
                  } else if (key == 'deposito') {
                    chipColor = _greenLight; // Verde para depósitos
                  } else if (key == 'investimento') {
                    chipColor = const Color(0xFFF5A623); // Laranja para investimentos
                  } else {
                    chipColor = const Color(0xFF00B4D8); // Ciano para rendimentos
                  }

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = key;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
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
                          // Indicador circular quando selecionado
                          if (isSelected) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: chipColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            label,
                            style: TextStyle(
                              color:
                                  isSelected ? chipColor : Colors.white60,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
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

          // ── EXTRATO VAZIO ─────────────────────────────────────────────────
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white24,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nenhuma transação encontrada.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                    if (_selectedFilter != null) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedFilter = null;
                          });
                        },
                        child: const Text(
                          'Limpar filtro',
                          style: TextStyle(
                            color: _greenLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            // ── LISTA DE TRANSAÇÕES ─────────────────────────────────────────
            TransactionHistory(
              transactions: filtered,
              onViewAll: () => _showSnackBar("Histórico completo em breve!"),
            ),

          // Espaçamento inferior para não colar na barra de navegação
          const SizedBox(height: 30),
        ],
      ),

      // Barra inferior com o ícone de Carteira destacado (index 3)
      bottomNavigationBar: CustomNavBar(userModel: userModel, currentIndex: 3),
    );
  }

  // =====================================================================
  // LÓGICA DE NEGÓCIO — confirmação de recarga e diálogos
  // =====================================================================

  // Processa a confirmação de recarga: chip selecionado ou valor digitado
  void _handleRechargeConfirm() {
    double? valor = _selectedQuickValue;
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

  // Exibe o diálogo de depósito com campo de valor
  void _showRechargeDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Depositar",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final valor = double.tryParse(
                controller.text.replaceAll(',', '.'),
              );
              if (valor != null && valor > 0) {
                setRecharge(valor);
                Navigator.pop(ctx);
                _showSnackBar(
                  "Depósito de R\$ ${valor.toStringAsFixed(2)} realizado!",
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _greenAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Confirmar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Exibe o diálogo de pagamento com campo de valor e validação de saldo
  void _showPayDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Pagar",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final valor = double.tryParse(
                controller.text.replaceAll(',', '.'),
              );
              if (valor != null && valor > 0 && valor <= saldo) {
                setPay(valor);
                Navigator.pop(ctx);
                _showSnackBar(
                  "Pagamento de R\$ ${valor.toStringAsFixed(2)} realizado!",
                );
              } else if (valor != null && valor > saldo) {
                _showSnackBar("Saldo insuficiente!");
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: StartupColors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Confirmar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Exibe um SnackBar com mensagem informativa na parte inferior da tela
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: StartupColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
