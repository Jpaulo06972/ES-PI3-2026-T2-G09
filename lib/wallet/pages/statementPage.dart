// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesclainvest_f/enum/typeOfOperation.dart';
import 'package:mesclainvest_f/wallet/services/getListOperation.dart';
import 'package:mesclainvest_f/model/operations.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';
import 'package:mesclainvest_f/wallet/components/emptyTransactions.dart';
import 'package:mesclainvest_f/wallet/pages/operationExtract.dart';

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
      rawData.sort((a, b) {
        final dateA = a['createdAt'];
        final dateB = b['createdAt'];

        int secA = 0;
        if (dateA is Timestamp) {
          secA = dateA.seconds;
        } else if (dateA is Map) {
          secA = (dateA['_seconds'] ?? dateA['seconds'] ?? 0);
        }

        int secB = 0;
        if (dateB is Timestamp) {
          secB = dateB.seconds;
        } else if (dateB is Map) {
          secB = (dateB['_seconds'] ?? dateB['seconds'] ?? 0);
        }

        return secB.compareTo(secA);
      });

      final mapped = rawData.map((data) {
        final op = OperationModel.fromMap(data['id'] ?? '', data);

        // Identifica quem é quem na transação
        bool souDestinatario = data['targetUserId'] == widget.user.uid;
        bool souAutor =
            (data['authorUid'] ?? data['authorID']) == widget.user.uid;

        IconData icon = Icons.help_outline;
        String title = op.text ?? 'Operação';
        bool isCredit = false;
        String subtitle = '';

        // Se eu sou o destinatário e não o autor, é um RECEBIMENTO
        if (souDestinatario && !souAutor) {
          isCredit = true;
          icon = Icons.move_to_inbox_rounded;
          title = 'Transferência recebida';
          subtitle = op.text ?? '';
        } else {
          switch (op.operation) {
            case TypeOfOperation.deposito:
              icon = Icons.add_circle_outline_rounded;
              title = 'Depósito';
              subtitle = op.text ?? 'Conta MesclaInvest';
              isCredit = true;
              break;
            case TypeOfOperation.pagar:
              icon = Icons.payment_rounded;
              title = 'Pagamento';
              subtitle = op.text ?? '';
              isCredit = false;
              break;
            case TypeOfOperation.transferencia:
              icon = Icons.arrow_upward_rounded;
              title = 'Transferência enviada';
              subtitle = op.text ?? '';
              isCredit = false;
              break;
            case TypeOfOperation.saque:
              icon = Icons.arrow_downward_rounded;
              title = 'Saque';
              subtitle = op.text ?? 'Conta bancária';
              isCredit = false;
              break;
            case TypeOfOperation.investimento:
              icon = Icons.rocket_launch_rounded;
              title = 'Investimento';
              subtitle = op.text ?? '';
              isCredit = false;
              break;
          }
        }

        // Tipo para filtro
        String filterType;
        if (souDestinatario && !souAutor) {
          filterType = 'transferencia';
        } else {
          filterType = op.operation.name;
        }

        return {
          'icon': icon,
          'title': title,
          'subtitle': subtitle,
          'date': op.createdAt ?? 'Data não informada',
          'value': op.amount,
          'isCredit': isCredit,
          'type': filterType,
          'id': op.id,
        };
      }).toList();

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

  /// Agrupa transações por data (dd/MM/yyyy) para exibir com separadores
  Map<String, List<Map<String, dynamic>>> _groupByDate(
    List<Map<String, dynamic>> transactions,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final tx in transactions) {
      // Pega só a parte da data (sem hora), ex: "14/05/2026"
      final dateStr = (tx['date'] as String).split(' ').first;
      grouped.putIfAbsent(dateStr, () => []);
      grouped[dateStr]!.add(tx);
    }
    return grouped;
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
    final grouped = _groupByDate(filtered);
    final dateKeys = grouped.keys.toList();

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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: const BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Saldo atual
                    Text(
                      'Saldo disponível',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyInputFormatter.formatValue(widget.user.saldo),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Resumo entradas/saídas
                    Row(
                      children: [
                        // Entradas
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_downward_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Entradas',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        CurrencyInputFormatter.formatValue(
                                          _totalEntradas,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Saídas
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_upward_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Saídas',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        CurrencyInputFormatter.formatValue(
                                          _totalSaidas,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Chips de filtro horizontais ────────────────────────
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filterOptions.length,
                  separatorBuilder: (_, _i) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final key = _filterOptions.keys.elementAt(index);
                    final label = _filterOptions.values.elementAt(index);
                    final isActive = _selectedFilter == key;

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
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? primaryGreen
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? primaryGreen
                                : Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
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
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        itemCount: dateKeys.length,
                        itemBuilder: (context, groupIndex) {
                          final dateKey = dateKeys[groupIndex];
                          final items = grouped[dateKey]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Separador de data (estilo Nubank)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 16,
                                  bottom: 8,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _formatDateLabel(dateKey),
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.4,
                                        ),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: Colors.white.withValues(
                                          alpha: 0.06,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Lista de transações daquele dia
                              ...items.map((tx) => _buildTransactionTile(tx)),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formata a label da data para exibir "Hoje", "Ontem" ou a data formatada
  String _formatDateLabel(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length >= 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final date = DateTime(year, month, day);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));

        if (date == today) return 'HOJE';
        if (date == yesterday) return 'ONTEM';

        const months = [
          '',
          'JAN',
          'FEV',
          'MAR',
          'ABR',
          'MAI',
          'JUN',
          'JUL',
          'AGO',
          'SET',
          'OUT',
          'NOV',
          'DEZ',
        ];
        return '${day.toString().padLeft(2, '0')} ${months[month]} $year';
      }
    } catch (_) {}
    return dateStr;
  }

  /// Constrói um tile individual de transação no estilo Nubank
  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    final bool isCredit = tx['isCredit'] as bool;
    final Color valueColor = isCredit
        ? const Color(0xFF2ECC71)
        : const Color(0xFFE74C3C);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OperationExtractPage(tx: tx)),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            // Ícone com fundo circular
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: valueColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  tx['icon'] as IconData,
                  color: valueColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Título + subtítulo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((tx['subtitle'] as String).isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      tx['subtitle'] as String,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Valor + horário
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${isCredit ? '+' : '-'} ${CurrencyInputFormatter.formatValue(tx['value'] as double)}",
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _extractTime(tx['date'] as String),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Extrai só a hora da data "dd/MM/yyyy HH:mm" → "HH:mm"
  String _extractTime(String dateStr) {
    final parts = dateStr.split(' ');
    if (parts.length >= 2) {
      return parts[1];
    }
    return '';
  }
}
