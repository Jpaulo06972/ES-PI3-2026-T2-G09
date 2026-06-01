// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

// Importações assíncronas e de estado para controlar streams e subscriptions
import 'dart:async';
// Biblioteca de gráficos de linha usada para desenhar o gráfico do portfólio
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
// Acesso ao Firestore para buscar as operações reais do usuário
import 'package:cloud_firestore/cloud_firestore.dart';
// Modelo do usuário que carrega o UID e dados da conta
import 'package:mesclainvest_f/model/userModel.dart';
// Utilitário de formatação de valores monetários em Real (R$)
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';

// Controlador reativo que calcula saldo cash + valor de mercado dos tokens
import 'package:mesclainvest_f/dashboard/controllers/wealth_controller.dart';

/// Widget de gráfico que exibe a evolução do portfólio do investidor ao longo
/// do tempo, comparando com o valor total investido (linha benchmark).
/// É um StatefulWidget porque reage a mudanças de período e a novas operações.
class DashboardChart extends StatefulWidget {
  // Dados do usuário necessários para filtrar operações no Firestore
  final UserModel userModel;
  // Controller que emite notificações quando o valor de mercado muda (pode ser null)
  final WealthController? wealthController;

  const DashboardChart({
    super.key,
    required this.userModel,
    this.wealthController,
  });

  @override
  State<DashboardChart> createState() => _DashboardChartState();
}

class _DashboardChartState extends State<DashboardChart> {
  // Período atualmente selecionado pelo usuário (começa em 1 mês)
  String _selectedPeriod = '1M';
  // Opções de período disponíveis na barra de seleção
  final List<String> _periods = ['1M', '6M', '1A', 'Tudo'];

  // Cores fixas para manter a identidade visual do gráfico
  static const Color _greenAccent = Color(0xFF107649);
  static const Color _greenLight = Color(0xFF1A9B5F);

  // Pontos da linha principal (valor do portfólio ao longo do tempo)
  List<FlSpot> _mainSpots = [
    const FlSpot(0, 0),
    const FlSpot(1, 0),
    const FlSpot(2, 0),
    const FlSpot(3, 0),
    const FlSpot(4, 0),
  ];
  // Pontos da linha de benchmark (total investido como referência)
  List<FlSpot> _benchmarkSpots = [
    const FlSpot(0, 0),
    const FlSpot(1, 0),
    const FlSpot(2, 0),
    const FlSpot(3, 0),
    const FlSpot(4, 0),
  ];
  // Rótulos de data exibidos no eixo X do gráfico
  List<String> _apiDates = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4', 'Hoje'];
  // Quantidade de dias que o período selecionado representa
  int _periodDays = 365;
  // Indica se o gráfico ainda está buscando ou processando dados
  bool _isLoading = false;
  // Variação absoluta (em R$) calculada no período
  double _growthAbs = 0.0;
  // Variação percentual calculada no período
  double _growthPct = 0.0;

  // Subscription da stream de operações — precisamos guardar para poder cancelar no dispose
  StreamSubscription<List<Map<String, dynamic>>>? _operationsSubscription;
  // Última lista de operações recebida da stream (null enquanto não carregou)
  List<Map<String, dynamic>>? _latestOperations;

  @override
  void initState() {
    super.initState();
    // Registra o listener para receber atualizações do WealthController em tempo real
    widget.wealthController?.addListener(_onWealthUpdated);
    // Inicia a escuta das operações assim que o widget é criado
    _updateOperationsStream();
  }

  @override
  void dispose() {
    // Remove o listener do WealthController para evitar chamadas em widget desmontado
    widget.wealthController?.removeListener(_onWealthUpdated);
    // Cancela a subscription do Firestore para liberar recursos
    _operationsSubscription?.cancel();
    super.dispose();
  }

  /// Chamado sempre que o WealthController emite um novo valor.
  /// Reprocessa as operações para atualizar o ponto final do gráfico.
  void _onWealthUpdated() {
    if (!mounted) return;
    // When real-time wealth updates, refresh chart with current value at the end
    _processOperations();
  }

  /// Cancela a subscription anterior e abre uma nova.
  /// Necessário ao trocar de período, pois a lógica de data muda.
  void _updateOperationsStream() {
    _operationsSubscription?.cancel();

    final userId = widget.userModel.uid;
    // Mostra o indicador de carregamento enquanto a nova busca não retorna
    setState(() {
      _isLoading = true;
    });
    // Exibe a linha zerada enquanto aguarda os dados
    _setFlatZeroLine(isLoading: true);

    // Assina a stream combinada (balcão + compras diretas) e reprocessa a cada update
    _operationsSubscription = _getOperationsStream(userId).listen(
      (operations) {
        _latestOperations = operations;
        _processOperations();
      },
      onError: (err) {
        debugPrint('Erro na stream de operações: $err');
        // Em caso de erro, considera lista vazia para não travar o gráfico
        _latestOperations = [];
        _processOperations();
      },
    );
  }

  /// Cria uma stream que combina tokenOperations (balcão) e operations (compras diretas).
  /// O merge é feito por ID para evitar duplicatas caso um documento apareça nas duas coleções.
  Stream<List<Map<String, dynamic>>> _getOperationsStream(String userId) {
    // Mescla tokenOperations (balcão) + operations (compras diretas) para cobrir todos os períodos
    final streamA = FirebaseFirestore.instance
        .collection('tokenOperations')
        .where('buyerId', isEqualTo: userId)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList(),
        );

    // Combina as duas listas, deduplica por id e ordena por data
    return streamA.asyncMap((listA) async {
      // Busca a segunda coleção de forma assíncrona toda vez que listA atualiza
      final listB = await FirebaseFirestore.instance
          .collection('operations')
          .where('authorUid', isEqualTo: userId)
          .get()
          .then(
            (snap) => snap.docs.map((doc) {
              final data = doc.data();
              // Prefixo 'ops_' evita colisão de IDs com tokenOperations
              data['id'] = 'ops_${doc.id}';
              return data;
            }).toList(),
          );

      // Usa um Map para garantir unicidade por ID
      final merged = <String, Map<String, dynamic>>{};
      for (final op in [...listA, ...listB]) {
        merged[op['id'].toString()] = op;
      }
      return merged.values.toList();
    });
  }

  /// Define os pontos do gráfico como uma linha reta no zero.
  /// Usado durante o carregamento ou quando não há dados para o período.
  void _setFlatZeroLine({bool isLoading = false}) {
    List<String> labels = [];
    List<FlSpot> emptySpots = [];

    // Para cada período, define rótulos e posições X dos pontos zerados
    switch (_selectedPeriod) {
      case '1M':
        labels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4', 'Hoje'];
        emptySpots = [
          const FlSpot(0, 0),
          const FlSpot(7, 0),
          const FlSpot(14, 0),
          const FlSpot(21, 0),
          const FlSpot(30, 0),
        ];
        break;
      case '6M':
        labels = ['Out', 'Dez', 'Fev', 'Abr'];
        emptySpots = [
          const FlSpot(0, 0),
          const FlSpot(45, 0),
          const FlSpot(90, 0),
          const FlSpot(135, 0),
          const FlSpot(180, 0),
        ];
        break;
      case '1A':
        labels = ['Mai/25', 'Ago/25', 'Nov/25', 'Fev/26', 'Abr/26'];
        emptySpots = [
          const FlSpot(0, 0),
          const FlSpot(91, 0),
          const FlSpot(182, 0),
          const FlSpot(273, 0),
          const FlSpot(365, 0),
        ];
        break;
      case 'Tudo':
        labels = ['2024', 'Jul/24', 'Jan/25', 'Abr/26'];
        emptySpots = [
          const FlSpot(0, 0),
          const FlSpot(91, 0),
          const FlSpot(182, 0),
          const FlSpot(273, 0),
          const FlSpot(365, 0),
        ];
        break;
      default:
        labels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4', 'Hoje'];
        emptySpots = [
          const FlSpot(0, 0),
          const FlSpot(7, 0),
          const FlSpot(14, 0),
          const FlSpot(21, 0),
          const FlSpot(30, 0),
        ];
        break;
    }

    // Só atualiza o estado se o widget ainda estiver na árvore
    if (mounted) {
      setState(() {
        _mainSpots = emptySpots;
        _benchmarkSpots = List.from(emptySpots);
        _apiDates = labels;
        if (!isLoading) {
          // Reseta crescimento somente quando não é loading (evita piscar zeros)
          _growthAbs = 0.0;
          _growthPct = 0.0;
          _isLoading = false;
        }
      });
    }
  }

  /// Converte diferentes formatos de data do Firestore para um DateTime nativo.
  /// Suporta Timestamp, Map com _seconds, e String ISO 8601.
  DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is Timestamp) return val.toDate();
    if (val is Map) {
      // Suporte ao formato serializado de Timestamp em alguns clientes
      final seconds = val['_seconds'] ?? val['seconds'];
      if (seconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    }
    if (val is String) {
      DateTime? d = DateTime.tryParse(val);
      if (d != null) return d;
    }
    // Fallback seguro: assume que é "agora"
    return DateTime.now();
  }

  /// Pega a lista de operações e constrói os pontos do gráfico.
  /// A lógica simula um "replay" das operações para calcular o patrimônio em cada data.
  void _processOperations() {
    if (_latestOperations == null) return;

    try {
      // Ordena as operações cronologicamente para o replay funcionar corretamente
      final operations = List<Map<String, dynamic>>.from(_latestOperations!);
      operations.sort(
        (a, b) =>
            _parseDate(a['createdAt']).compareTo(_parseDate(b['createdAt'])),
      );

      final now = DateTime.now();

      // Determine period window
      int periodDays;
      DateTime startDate;
      switch (_selectedPeriod) {
        case '1M':
          periodDays = 30;
          break;
        case '6M':
          periodDays = 180;
          break;
        case '1A':
          periodDays = 365;
          break;
        default: // 'Tudo'
          // Para "Tudo", o início é a data da primeira operação registrada
          final firstDate = operations.isNotEmpty
              ? _parseDate(operations.first['createdAt'])
              : now.subtract(const Duration(days: 30));
          periodDays = now.difference(firstDate).inDays.clamp(7, 3650);
      }
      startDate = now.subtract(Duration(days: periodDays));

      // Replay ops that occurred BEFORE the window to get the starting state
      // (garante que a linha começa do valor correto, não de zero)
      double currentCash = 0.0;
      double currentInvestedCost = 0.0;
      double cumulativeDeposits = 0.0;
      for (var op in operations) {
        if (!_parseDate(op['createdAt']).isBefore(startDate)) break;
        _applyOp(op, currentCash, currentInvestedCost, cumulativeDeposits, (
          c,
          ic,
          d,
        ) {
          currentCash = c;
          currentInvestedCost = ic;
          cumulativeDeposits = d;
        });
      }

      // Primeiro snapshot: sempre em x=0 (início do período selecionado)
      final snapshots = <Map<String, dynamic>>[];
      snapshots.add({
        'x': 0.0,
        'value': (currentCash + currentInvestedCost).clamp(
          0.0,
          double.maxFinite,
        ),
        'bench': cumulativeDeposits.clamp(0.0, double.maxFinite),
      });

      // Processa as operações que caem dentro da janela do período selecionado
      for (var op in operations) {
        final dt = _parseDate(op['createdAt']);
        if (dt.isBefore(startDate) || dt.isAfter(now)) continue;
        _applyOp(op, currentCash, currentInvestedCost, cumulativeDeposits, (
          c,
          ic,
          d,
        ) {
          currentCash = c;
          currentInvestedCost = ic;
          cumulativeDeposits = d;
        });
        snapshots.add({
          // Converte a data em "dias desde o início do período" para o eixo X
          'x': dt.difference(startDate).inMinutes / 1440.0,
          'value': (currentCash + currentInvestedCost).clamp(
            0.0,
            double.maxFinite,
          ),
          'bench': cumulativeDeposits.clamp(0.0, double.maxFinite),
        });
      }

      // Ponto final: usa valor total consolidado (tokens + saldo) para bater com o header
      final cashOffset = widget.wealthController?.cashBalance ?? 0.0;
      final consolidatedTotal =
          (widget.wealthController?.consolidatedTotal ??
                  (widget.wealthController?.tokensMarketValue ??
                          currentInvestedCost) +
                      cashOffset)
              .clamp(0.0, double.maxFinite);

      // Adiciona o ponto final no extremo direito do gráfico (hoje)
      snapshots.add({
        'x': periodDays.toDouble(),
        'value': consolidatedTotal,
        'bench': (currentInvestedCost + cashOffset).clamp(
          0.0,
          double.maxFinite,
        ),
      });

      // Adiciona o saldo cash a todos os pontos intermediários para consistência com o ponto final
      for (int i = 0; i < snapshots.length - 1; i++) {
        snapshots[i]['value'] = ((snapshots[i]['value'] as double) + cashOffset)
            .clamp(0.0, double.maxFinite);
        snapshots[i]['bench'] = ((snapshots[i]['bench'] as double) + cashOffset)
            .clamp(0.0, double.maxFinite);
      }

      // Dense interpolation between every pair of snapshots
      // (cria pontos intermediários para suavizar a linha do gráfico)
      final allSpots = _buildInterpolatedSpots(snapshots, periodDays);

      // Calcula a variação do último dia comparando o valor atual com o de ontem
      final yOffset = (periodDays - 1).toDouble();
      double yesterdayValue = 0.0;
      double minDiff = double.maxFinite;
      for (var s in allSpots) {
        final diff = ((s['x'] as double) - yOffset).abs();
        if (diff < minDiff) {
          minDiff = diff;
          yesterdayValue = s['value'] as double;
        }
      }
      final growthAbs = consolidatedTotal - yesterdayValue;
      // Evita divisão por zero quando não há histórico
      final growthPct = yesterdayValue > 0
          ? (growthAbs / yesterdayValue) * 100.0
          : 0.0;

      // Gera 5 rótulos de data igualmente espaçados para o eixo X
      final dateLabels = List.generate(5, (i) {
        final d = startDate.add(Duration(days: (periodDays * i / 4).round()));
        return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}";
      });

      // Divide por 1000 para que os valores no gráfico fiquem menores (evita números gigantes no eixo)
      final mainSpots = allSpots
          .map((s) => FlSpot(s['x'] as double, (s['value'] as double) / 1000.0))
          .toList();
      final benchSpots = allSpots
          .map((s) => FlSpot(s['x'] as double, (s['bench'] as double) / 1000.0))
          .toList();

      if (mounted) {
        setState(() {
          _periodDays = periodDays;
          // Se a lista gerada estiver vazia, usa pelo menos dois pontos para o gráfico não quebrar
          _mainSpots = mainSpots.isNotEmpty
              ? mainSpots
              : [FlSpot(0, 0), FlSpot(periodDays.toDouble(), 0)];
          _benchmarkSpots = benchSpots.isNotEmpty
              ? benchSpots
              : [FlSpot(0, 0), FlSpot(periodDays.toDouble(), 0)];
          _apiDates = dateLabels;
          _growthAbs = growthAbs;
          _growthPct = growthPct;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao processar operações: $e');
      // Em caso de erro inesperado, volta ao estado zerado para não mostrar dados errados
      _setFlatZeroLine();
    }
  }

  /// Aplica uma operação ao estado atual de caixa, custo investido e depósitos.
  /// O callback [out] recebe os valores atualizados após a operação.
  void _applyOp(
    Map<String, dynamic> op,
    double cash,
    double invested,
    double deposits,
    void Function(double c, double ic, double d) out,
  ) {
    // Normaliza o campo de tipo que pode vir com nomes diferentes dependendo da coleção
    final type = (op['type'] ?? op['operation'] ?? op['typeOfOperation'] ?? '')
        .toString();
    double amount = 0.0;
    // Extrai o valor da operação — pode estar em centavos ou em reais, dependendo do campo
    if (op.containsKey('amountCents')) {
      amount = ((op['amountCents'] as num?)?.toDouble() ?? 0) / 100.0;
    } else if (op.containsKey('totalCents')) {
      amount = ((op['totalCents'] as num?)?.toDouble() ?? 0) / 100.0;
    } else if (op.containsKey('totalValue')) {
      amount = (op['totalValue'] as num?)?.toDouble() ?? 0;
    } else if (op.containsKey('amount')) {
      amount = (op['amount'] as num?)?.toDouble() ?? 0;
    } else if (op.containsKey('valor')) {
      amount = (op['valor'] as num?)?.toDouble() ?? 0;
    }

    // Aplica o efeito da operação nos três contadores de patrimônio
    switch (type) {
      case 'deposito':
        // Depósito aumenta o caixa e o total de aportes acumulados
        cash += amount;
        deposits += amount;
        break;
      case 'saque':
        // Saque reduz o caixa e o total de aportes
        cash -= amount;
        deposits -= amount;
        break;
      case 'buy_from_startup':
      case 'investimento':
        // Compra direta: dinheiro sai do caixa e entra como custo de tokens
        cash -= amount;
        invested += amount;
        break;
      case 'venda_para_startup':
        // Venda de volta para a startup: tokens viram dinheiro novamente
        cash += amount;
        invested -= amount;
        break;
      case 'buy':
      case 'buy_from_user':
        if (op['buyerId'] == widget.userModel.uid) {
          // Only track cost basis — cash is tracked separately via WealthController
          invested += amount;
        }
        break;
      case 'sell':
      case 'sell_to_user':
        if ((op['sellerId'] ?? op['vendedorId']) == widget.userModel.uid) {
          invested -= amount;
          // Garante que o custo não fique negativo por arredondamento
          if (invested < 0) invested = 0;
        }
        break;
    }
    // Proteção final: custo investido nunca pode ser negativo
    if (invested < 0) invested = 0;
    // Devolve os valores atualizados via callback (Dart não tem múltiplos retornos)
    out(cash, invested, deposits);
  }

  /// Preenche os espaços entre snapshots esparsos com pontos interpolados.
  /// Usa uma curva ease-in-out para que a variação pareça orgânica e não linear.
  // Fills gaps between sparse snapshots with smooth ease-in-out intermediate points
  List<Map<String, dynamic>> _buildInterpolatedSpots(
    List<Map<String, dynamic>> snapshots,
    int periodDays,
  ) {
    if (snapshots.length < 2) return snapshots;

    // Denser for shorter periods
    // Para períodos curtos, mais pontos = curva mais suave
    final int stepDays = periodDays > 90 ? 2 : 1;

    final result = <Map<String, dynamic>>[];
    for (int i = 0; i < snapshots.length - 1; i++) {
      final a = snapshots[i];
      final b = snapshots[i + 1];
      result.add(a);

      final double xA = a['x'] as double;
      final double xB = b['x'] as double;
      final double vA = a['value'] as double;
      final double vB = b['value'] as double;
      final double bA = a['bench'] as double;
      final double bB = b['bench'] as double;
      final double gap = xB - xA;

      // Só interpola se o intervalo for maior que um passo
      if (gap > stepDays) {
        int steps = (gap / stepDays).floor();
        for (int s = 1; s < steps; s++) {
          final double t = (s * stepDays) / gap;
          // Ease-in-out para uma curva de valorização mais natural (não linear)
          // Ease-in-out for a natural appreciation curve
          final double eased = t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
          result.add({
            'x': xA + s * stepDays,
            // O portfólio usa easing para suavizar; o benchmark é linear (sem emoção)
            'value': (vA + (vB - vA) * eased).clamp(0.0, double.maxFinite),
            'bench': (bA + (bB - bA) * t).clamp(0.0, double.maxFinite),
          });
        }
      }
    }
    result.add(snapshots.last);
    return result;
  }

  // Retorna a lista de pontos da linha principal (portfólio)
  List<FlSpot> _getMainSpots() {
    return _mainSpots;
  }

  // Retorna a lista de pontos da linha de benchmark (total investido)
  List<FlSpot> _getBenchmarkSpots() {
    return _benchmarkSpots;
  }

  /// Retorna os rótulos de data para o eixo X.
  /// Se já temos datas calculadas da API, usa elas; senão usa os rótulos fixos.
  List<String> _getDateLabels() {
    if (_apiDates.isNotEmpty) {
      return _apiDates;
    }
    switch (_selectedPeriod) {
      case '1M':
        return ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4', 'Hoje'];
      case '6M':
        return ['Out', 'Dez', 'Fev', 'Abr'];
      case '1A':
        return ['Mai/25', 'Ago/25', 'Nov/25', 'Fev/26', 'Abr/26'];
      case 'Tudo':
        return ['2024', 'Jul/24', 'Jan/25', 'Abr/26'];
      default:
        return [];
    }
  }

  /// Constrói o indicador de performance (+R$X / +X%) abaixo do saldo total.
  /// Usa AnimatedBuilder para reagir aos ticks do WealthController em tempo real.
  Widget _buildPerformanceIndicator() {
    final wc = widget.wealthController;

    if (wc == null) {
      // Sem controller, usa os valores calculados localmente pelas operações
      if (_isLoading) return const SizedBox(height: 24);
      return _indicatorRow(_growthAbs, _growthPct);
    }

    // AnimatedBuilder reconstrói o indicador a cada notifyListeners() do WealthController
    // (disparado a cada tick do PriceSimulatorService, a cada 10 segundos)
    return AnimatedBuilder(
      animation: wc,
      builder: (_, _) => _indicatorRow(wc.dailyChangeAbs, wc.dailyChangePct),
    );
  }

  /// Linha visual do indicador: ícone de seta + valor formatado em R$ + percentual.
  Widget _indicatorRow(double changeAbs, double changePct) {
    // Verde se positivo, vermelho se negativo
    final isPositive = changeAbs >= 0;
    final color = isPositive ? _greenLight : const Color(0xFFE74C3C);
    return Row(
      children: [
        Icon(
          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          // Formata como "R$ 1.234,56 (1,23%)"
          '${CurrencyInputFormatter.formatValue(changeAbs.abs())} '
          '(${changePct.abs().toStringAsFixed(2).replaceAll('.', ',')}%)',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainSpots = _getMainSpots();
    final benchmarkSpots = _getBenchmarkSpots();

    // Dynamic Y-axis: zoom into the data range so appreciation is visible
    // Calcula os limites do eixo Y dinamicamente para maximizar a visibilidade da variação
    double minY = double.maxFinite;
    double maxY = 0.0;

    for (var spot in mainSpots) {
      if (spot.y > maxY) maxY = spot.y;
      if (spot.y < minY) minY = spot.y;
    }
    for (var spot in benchmarkSpots) {
      if (spot.y > maxY) maxY = spot.y;
    }

    if (maxY <= 0.0) {
      // Sem dados: usa escala mínima para não quebrar o gráfico
      maxY = 1.0;
      minY = 0.0;
    } else {
      final range = maxY - (minY == double.maxFinite ? 0 : minY);
      final floor = minY == double.maxFinite ? 0.0 : minY;
      // Se variation <20% do max, dá zoom para tornar a curva bem visível
      // If variation is <20% of max, zoom in to make the curve clearly visible
      if (range > 0 && range < maxY * 0.20) {
        minY = (floor - range * 0.5).clamp(0.0, double.maxFinite);
      } else {
        minY = 0.0;
      }
      // Margem de 12% no topo para o rótulo de valor não ser cortado
      maxY = maxY * 1.12;
    }

    // Always span the full selected period so the line never starts mid-chart
    const double minX = 0.0;
    final double maxX = _periodDays.toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Performance Indicator below total balance
        // Indicador de variação posicionado abaixo do saldo total
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: _buildPerformanceIndicator(),
        ),

        // Barra de seleção de período (1M, 6M, 1A, Tudo)
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8, left: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: _periods.asMap().entries.map((entry) {
              int index = entry.key;
              String period = entry.value;
              final isSelected = period == _selectedPeriod;

              return GestureDetector(
                onTap: () {
                  // Ao selecionar novo período, atualiza o estado e reinicia a stream
                  setState(() {
                    _selectedPeriod = _periods[index];
                  });
                  _updateOperationsStream();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    // Fundo verde para o período selecionado, transparente para os demais
                    color: isSelected ? _greenAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? _greenAccent : Colors.white24,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    period,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Área do gráfico com altura fixa de 200px
        SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              children: [
                LineChart(
                  LineChartData(
                    minX: minX,
                    maxX: maxX,
                    minY: minY,
                    maxY: maxY,
                    // Corta as linhas nas bordas para não vazar para fora da área
                    clipData: const FlClipData.all(),
                    // Remove a borda visual ao redor do gráfico
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      // Linhas horizontais sutis para facilitar a leitura dos valores
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 4 > 0 ? maxY / 4 : 1.0,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.white.withValues(alpha: 0.05),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        );
                      },
                    ),
                    extraLinesData: ExtraLinesData(
                      // Linha horizontal tracejada no valor atual do portfólio com rótulo
                      horizontalLines: mainSpots.isNotEmpty
                          ? [
                              HorizontalLine(
                                y: mainSpots.last.y,
                                color: _greenLight.withValues(alpha: 0.5),
                                strokeWidth: 1,
                                dashArray: [5, 5],
                                label: HorizontalLineLabel(
                                  show: true,
                                  alignment: Alignment.topRight,
                                  padding: const EdgeInsets.only(
                                    right: 5,
                                    bottom: 5,
                                  ),
                                  style: const TextStyle(
                                    color: _greenLight,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  // Converte de volta para R$ (havíamos dividido por 1000 para o gráfico)
                                  labelResolver: (line) =>
                                      CurrencyInputFormatter.formatValue(
                                        line.y * 1000.0,
                                      ),
                                ),
                              ),
                            ]
                          : [],
                    ),
                    // Esconde todos os rótulos de eixo (usamos os nossos próprios abaixo)
                    titlesData: const FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    // Tooltip ao tocar no gráfico: mostra apenas o valor do portfólio (não o benchmark)
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            if (spot.barIndex == 0) {
                              return null; // Ignore benchmark line
                            }
                            return LineTooltipItem(
                              CurrencyInputFormatter.formatValue(
                                spot.y * 1000.0,
                              ),
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      // Linha 1: "Investido" (Benchmark estático para comparar)
                      // Linha tracejada mostrando quanto dinheiro foi aportado (sem valorização)
                      LineChartBarData(
                        spots: benchmarkSpots,
                        isCurved: false,
                        color: _greenLight.withValues(alpha: 0.4),
                        barWidth: 1.5,
                        dashArray: [6, 4],
                        dotData: const FlDotData(show: false),
                      ),
                      // Linha 2: Valor do Portfolio
                      // Linha sólida mostrando o valor real do portfólio com preços de mercado
                      LineChartBarData(
                        spots: mainSpots,
                        isCurved: true,
                        curveSmoothness: 0.2,
                        preventCurveOverShooting: true,
                        color: _greenLight,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          checkToShowDot: (spot, barData) {
                            // Mostrar ponto apenas no último dia (valor atual)
                            return spot.x ==
                                barData
                                    .spots
                                    .last
                                    .x; // Mostrar ponto apenas no último dia
                          },
                          getDotPainter: (spot, percent, barData, index) {
                            // Ponto branco com borda verde para destacar o valor final
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: _greenLight,
                            );
                          },
                        ),
                        // Gradiente suave abaixo da linha para sensação de área preenchida
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              _greenLight.withValues(alpha: 0.3),
                              _greenLight.withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Overlay de loading: aparece enquanto os dados estão sendo processados
                if (_isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.1),
                      child: const Center(
                        child: CircularProgressIndicator(color: _greenLight),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Rótulos de data distribuídos igualmente abaixo do gráfico
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _getDateLabels()
                .map(
                  (label) => Text(
                    label,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
