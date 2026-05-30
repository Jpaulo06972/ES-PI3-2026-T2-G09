import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesclainvest_f/counter/services/counterService.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/wallet/services/getListOperation.dart';
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';

class DashboardChart extends StatefulWidget {
  final UserModel userModel;
  const DashboardChart({super.key, required this.userModel});

  @override
  State<DashboardChart> createState() => _DashboardChartState();
}

class _DashboardChartState extends State<DashboardChart> {
  String _selectedPeriod = '1A';
  final List<String> _periods = ['1M', '6M', '1A', 'Tudo'];

  static const Color _greenAccent = Color(0xFF107649);
  static const Color _greenLight = Color(0xFF1A9B5F);

  List<FlSpot> _mainSpots = [];
  List<FlSpot> _benchmarkSpots = [];
  List<String> _apiDates = [];
  bool _isLoading = false;
  double _growthAbs = 0.0;
  double _growthPct = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPriceHistory();
  }

  void _setFlatZeroLine() {
    List<FlSpot> emptySpots = [];
    List<FlSpot> emptyBenchmark = [];

    for (int i = 0; i < 5; i++) {
      emptySpots.add(FlSpot(i.toDouble(), 0));
      emptyBenchmark.add(FlSpot(i.toDouble(), 0));
    }

    if (mounted) {
      setState(() {
        _mainSpots = emptySpots;
        _benchmarkSpots = emptyBenchmark;
        _apiDates = []; // will fallback to _getDateLabels() dynamically
        _isLoading = false;
      });
    }
  }

  DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is Timestamp) return val.toDate();
    if (val is Map) {
      final seconds = val['_seconds'] ?? val['seconds'];
      if (seconds != null)
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
    if (val is String) {
      DateTime? d = DateTime.tryParse(val);
      if (d != null) return d;
    }
    return DateTime.now();
  }

  void _loadPriceHistory() async {
    setState(() => _isLoading = true);
    try {
      final userId = widget.userModel.uid;

      String apiPeriod = 'monthly';
      DateTime filterDate;
      final now = DateTime.now();

      if (_selectedPeriod == '1M') {
        apiPeriod = 'monthly';
        filterDate = now.subtract(const Duration(days: 30));
      } else if (_selectedPeriod == '6M') {
        apiPeriod = '6months';
        filterDate = now.subtract(const Duration(days: 180));
      } else if (_selectedPeriod == '1A') {
        apiPeriod = 'ytd';
        filterDate = now.subtract(const Duration(days: 365));
      } else {
        apiPeriod = 'all';
        filterDate = DateTime.fromMillisecondsSinceEpoch(0);
      }

      // Fetch ALL transactions from the user (fiat + tokens)
      final operations = await GetListOperation().getOperations(userId: userId);

      // Log para debug do desenvolvedor
      print(
        'Total de operações encontradas para o gráfico: ${operations.length}',
      );

      if (operations.isEmpty) {
        _setFlatZeroLine();
        return;
      }

      // Order ascending by date to replay history
      operations.sort((a, b) {
        final dateA = _parseDate(a['createdAt']);
        final dateB = _parseDate(b['createdAt']);
        return dateA.compareTo(dateB);
      });

      double cashDeposited = 0.0;
      double cashBalance = 0.0;
      Map<String, int> startupTokens = {};
      List<Map<String, dynamic>> timeline = [];

      Set<String> allStartupIds = {};

      for (var op in operations) {
        final type =
            op['type'] ?? op['operation'] ?? op['typeOfOperation'] ?? '';
        final date = _parseDate(op['createdAt']);

        double amount = 0.0;
        if (op.containsKey('totalCents')) {
          amount = ((op['totalCents'] as num?)?.toDouble() ?? 0.0) / 100.0;
        } else if (op.containsKey('amountCents')) {
          amount = ((op['amountCents'] as num?)?.toDouble() ?? 0.0) / 100.0;
        } else if (op.containsKey('amount')) {
          amount = (op['amount'] as num?)?.toDouble() ?? 0.0;
        } else if (op.containsKey('valor')) {
          amount = (op['valor'] as num?)?.toDouble() ?? 0.0;
        }

        if (type == 'deposito') {
          cashDeposited += amount;
          cashBalance += amount;
        } else if (type == 'saque' ||
            type == 'transferencia' ||
            type == 'pagar') {
          cashBalance -= amount;
          // If they withdrew more than they had (unlikely), keep at 0
          if (cashBalance < 0) cashBalance = 0;
        } else if (type == 'buy_from_startup' ||
            type == 'buy_from_user' ||
            type == 'investimento') {
          // Checa se o usuário é o comprador
          bool isBuyer =
              (op['buyerId'] == userId) ||
              (type == 'buy_from_startup' &&
                  (op['authorUid'] == userId || op['authorID'] == userId)) ||
              (type == 'investimento' &&
                  (op['authorUid'] == userId || op['authorID'] == userId));

          if (isBuyer) {
            cashBalance -= amount;
            if (cashBalance < 0) cashBalance = 0; // Sanity check

            final sId = op['startupId']?.toString();
            final qty = (op['quantity'] as num?)?.toInt() ?? 0;
            if (sId != null && qty > 0) {
              allStartupIds.add(sId);
              startupTokens[sId] = (startupTokens[sId] ?? 0) + qty;
            }
          }
        } else if (type == 'sell_to_user') {
          bool isSeller =
              (op['sellerId'] == userId) ||
              (op['authorUid'] == userId || op['authorID'] == userId);
          if (isSeller) {
            cashBalance += amount;

            final sId = op['startupId']?.toString();
            final qty = (op['quantity'] as num?)?.toInt() ?? 0;
            if (sId != null && qty > 0) {
              int currentTokens = startupTokens[sId] ?? 0;
              startupTokens[sId] = (currentTokens - qty > 0)
                  ? (currentTokens - qty)
                  : 0;
            }
          }
        }

        timeline.add({
          'date': date,
          'cashDeposited': cashDeposited,
          'cashBalance': cashBalance,
          'tokens': Map<String, int>.from(startupTokens),
        });
      }

      // Fetch historical prices only for startups we traded
      Map<String, List<Map<String, dynamic>>> priceHistories = {};
      for (String sid in allStartupIds) {
        final hist = await CounterService().getPriceHistory(sid, apiPeriod);
        priceHistories[sid] = hist;
      }

      // Determine X axis timestamps
      Set<String> uniqueTimestamps = {};
      for (var hist in priceHistories.values) {
        for (var point in hist) {
          uniqueTimestamps.add(point['timestamp'] as String);
        }
      }
      List<String> sortedTimestamps = uniqueTimestamps.toList();
      sortedTimestamps.sort(
        (a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)),
      );

      // If no valid tokens but we have cash history, we mock timestamps based on selected period
      if (sortedTimestamps.isEmpty) {
        int numPoints = 6;
        DateTime startPlot = _selectedPeriod == 'Tudo'
            ? timeline.first['date']
            : filterDate;
        int diffMs = now.difference(startPlot).inMilliseconds;
        for (int i = 0; i < numPoints; i++) {
          DateTime dt = startPlot.add(
            Duration(milliseconds: (diffMs * i / (numPoints - 1)).round()),
          );
          sortedTimestamps.add(dt.toIso8601String());
        }
      }

      // Prepare final spots within the filtered timeframe
      List<FlSpot> newMainSpots = [];
      List<FlSpot> newBenchmarkSpots = [];
      List<String> newDates = [];

      int spotIndex = 0;

      for (int i = 0; i < sortedTimestamps.length; i++) {
        String tsStr = sortedTimestamps[i];
        DateTime dt = DateTime.parse(tsStr);

        // Filter out dates outside our period (except "Tudo")
        if (_selectedPeriod != 'Tudo' && dt.isBefore(filterDate)) {
          continue;
        }

        newDates.add(
          "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}",
        );

        Map<String, dynamic>? activeState;
        for (var state in timeline) {
          DateTime stateDate = state['date'];
          if (stateDate.isBefore(dt) || stateDate.isAtSameMomentAs(dt)) {
            activeState = state;
          } else {
            break;
          }
        }

        double currentPortfolioValue = 0.0;
        double investedBaseline = 0.0;

        if (activeState != null) {
          investedBaseline = activeState['cashDeposited'];
          currentPortfolioValue = activeState['cashBalance'];

          Map<String, int> tokens = activeState['tokens'];

          tokens.forEach((sid, qty) {
            if (qty > 0) {
              double historicalPrice = 0.0;
              if (priceHistories.containsKey(sid) &&
                  priceHistories[sid]!.isNotEmpty) {
                for (var point in priceHistories[sid]!) {
                  DateTime pointDt = DateTime.parse(point['timestamp']);
                  if (pointDt.isBefore(dt) || pointDt.isAtSameMomentAs(dt)) {
                    historicalPrice = (point['price'] as num).toDouble();
                  } else {
                    break;
                  }
                }
              }

              // If the API didn't return a price for this date, default to a sensible fallback
              if (historicalPrice == 0.0) {
                // Try getting the very first price available if the holding is older than the chart history
                if (priceHistories.containsKey(sid) &&
                    priceHistories[sid]!.isNotEmpty) {
                  historicalPrice = (priceHistories[sid]!.first['price'] as num)
                      .toDouble();
                }
              }

              currentPortfolioValue += (qty * historicalPrice);
            }
          });
        }

        // Save the raw cash deposited for calculating relative baseline
        double rawDeposits = activeState != null
            ? activeState['cashDeposited']
            : 0.0;

        newMainSpots.add(
          FlSpot(spotIndex.toDouble(), currentPortfolioValue / 1000.0),
        );
        // We temporarily store the raw deposits in benchmark. We will fix it in the next loop.
        newBenchmarkSpots.add(
          FlSpot(spotIndex.toDouble(), rawDeposits / 1000.0),
        );
        spotIndex++;
      }

      // Fix 1: Anchor the baseline to start exactly at the portfolio's starting value
      if (newMainSpots.isNotEmpty && newBenchmarkSpots.isNotEmpty) {
        double startingPortfolio = newMainSpots.first.y;
        double startingDeposits = newBenchmarkSpots.first.y;

        for (int i = 0; i < newBenchmarkSpots.length; i++) {
          double currentDeposits = newBenchmarkSpots[i].y;
          double netNewDeposits = currentDeposits - startingDeposits;
          newBenchmarkSpots[i] = FlSpot(
            newBenchmarkSpots[i].x,
            startingPortfolio + netNewDeposits,
          );
        }
      }

      // New Feature: Performance Summary Calculation
      double growthAbs = 0.0;
      double growthPct = 0.0;

      if (newMainSpots.isNotEmpty) {
        double currentTotalValue = newMainSpots.last.y * 1000.0;

        // Calculate totalInvested as instructed: sum of amount fields from deposit/purchase operations
        double totalInvested = 0.0;
        for (var op in operations) {
          String t =
              op['type'] ?? op['operation'] ?? op['typeOfOperation'] ?? '';
          bool isBuyer =
              (op['buyerId'] == userId) ||
              (t == 'buy_from_startup' &&
                  (op['authorUid'] == userId || op['authorID'] == userId)) ||
              (t == 'investimento' &&
                  (op['authorUid'] == userId || op['authorID'] == userId));

          if (t == 'deposito' || isBuyer) {
            double amt = 0.0;
            if (op.containsKey('totalCents')) {
              amt = ((op['totalCents'] ?? 0) as num).toDouble() / 100.0;
            } else if (op.containsKey('amountCents')) {
              amt = ((op['amountCents'] ?? 0) as num).toDouble() / 100.0;
            } else if (op.containsKey('amount')) {
              amt = ((op['amount'] ?? 0) as num).toDouble();
            } else if (op.containsKey('valor')) {
              amt = ((op['valor'] ?? 0) as num).toDouble();
            }
            totalInvested += amt;
          }
        }

        // Ensure totalInvested is not zero
        if (totalInvested == 0.0) totalInvested = 1.0;

        growthAbs = currentTotalValue - totalInvested;
        growthPct = (growthAbs / totalInvested) * 100.0;
      }

      print('Total de pontos gerados no grafico: ${newMainSpots.length}');

      if (mounted) {
        setState(() {
          _mainSpots = newMainSpots.isNotEmpty
              ? newMainSpots
              : [const FlSpot(0, 0)];
          _benchmarkSpots = newBenchmarkSpots.isNotEmpty
              ? newBenchmarkSpots
              : [const FlSpot(0, 0)];
          _apiDates = newDates.isNotEmpty ? newDates : [''];
          _growthAbs = growthAbs;
          _growthPct = growthPct;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar o grafico baseando nas transacoes: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<FlSpot> _getMainSpots() {
    return _mainSpots;
  }

  List<FlSpot> _getBenchmarkSpots() {
    return _benchmarkSpots;
  }

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

  Widget _buildPerformanceIndicator() {
    if (_isLoading) {
      return const SizedBox(height: 24);
    }

    bool isPositive = _growthAbs >= 0;
    Color color = isPositive ? _greenLight : const Color(0xFFE74C3C);
    IconData icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    String formattedAbs =
        'R\$ ${(_growthAbs.abs()).toStringAsFixed(2).replaceAll('.', ',')}';
    String formattedPct =
        '${_growthPct.abs().toStringAsFixed(1).replaceAll('.', ',')}%';

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          '$formattedAbs ($formattedPct)',
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

    // Fix 2: Determine Max Y to scale correctly
    double maxY = -double.maxFinite;
    double minY = double.maxFinite;

    for (var spot in mainSpots) {
      if (spot.y > maxY) maxY = spot.y;
      if (spot.y < minY) minY = spot.y;
    }
    for (var spot in benchmarkSpots) {
      if (spot.y > maxY) maxY = spot.y;
      if (spot.y < minY) minY = spot.y;
    }

    if (maxY == -double.maxFinite) {
      maxY = 1;
      minY = 0;
    }

    double diff = maxY - minY;
    if (diff == 0) diff = 1;

    maxY = maxY + (diff * 0.1);
    minY = minY - (diff * 0.1);
    if (minY < 0) minY = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Performance Indicator below total balance
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: _buildPerformanceIndicator(),
        ),

        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8, left: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: _periods.map((period) {
              final isSelected = period == _selectedPeriod;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedPeriod = period);
                  _loadPriceHistory();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
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

        SizedBox(
          height: 180,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _greenLight),
                  )
                : mainSpots.isEmpty
                ? const Center(
                    child: Text(
                      "Nenhum dado de investimento no período selecionado.",
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: minY,
                      maxY: maxY,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: diff / 4 > 0 ? diff / 4 : 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.white.withOpacity(0.05),
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          );
                        },
                      ),
                      extraLinesData: ExtraLinesData(
                        horizontalLines: mainSpots.isNotEmpty
                            ? [
                                HorizontalLine(
                                  y: mainSpots.last.y,
                                  color: _greenLight.withOpacity(0.5),
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
                                    labelResolver: (line) =>
                                        CurrencyInputFormatter.formatValue(
                                          line.y * 1000.0,
                                        ),
                                  ),
                                ),
                              ]
                            : [],
                      ),
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
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              if (spot.barIndex == 0)
                                return null; // Ignore benchmark line
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
                        LineChartBarData(
                          spots: benchmarkSpots,
                          isCurved: false,
                          color: _greenLight.withOpacity(0.4),
                          barWidth: 1.5,
                          dashArray: [6, 4],
                          dotData: const FlDotData(show: false),
                        ),
                        // Linha 2: Valor do Portfolio
                        LineChartBarData(
                          spots: mainSpots,
                          isCurved: true,
                          color: _greenLight,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            checkToShowDot: (spot, barData) {
                              return spot.x ==
                                  barData
                                      .spots
                                      .last
                                      .x; // Mostrar ponto apenas no último dia
                            },
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: _greenLight,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                _greenLight.withOpacity(0.3),
                                _greenLight.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
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
