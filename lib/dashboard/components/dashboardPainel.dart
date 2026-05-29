import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mesclainvest_f/counter/services/counterService.dart';
import 'package:mesclainvest_f/startups/services/getStartup.dart';

class DashboardChart extends StatefulWidget {
  const DashboardChart({super.key});

  @override
  State<DashboardChart> createState() => _DashboardChartState();
}

class _DashboardChartState extends State<DashboardChart> {
  String _selectedPeriod = '1A';
  final List<String> _periods = ['1M', '6M', '1A', 'Tudo'];

  static const Color _greenAccent = Color(0xFF107649);
  static const Color _greenLight = Color(0xFF1A9B5F);

  List<FlSpot> _apiSpots = [];
  List<String> _apiDates = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPriceHistory();
  }

  void _loadPriceHistory() async {
    setState(() => _isLoading = true);
    try {
      final startups = await StartupService().listStartups();
      if (startups.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }
      final startupId = startups.first['id'];

      String apiPeriod = 'monthly';
      if (_selectedPeriod == '1M') {
        apiPeriod = 'monthly';
      } else if (_selectedPeriod == '6M') {
        apiPeriod = '6months';
      } else if (_selectedPeriod == '1A') {
        apiPeriod = 'ytd';
      } else if (_selectedPeriod == 'Tudo') {
        apiPeriod = 'all';
      }

      final history = await CounterService().getPriceHistory(startupId, apiPeriod);

      if (mounted) {
        setState(() {
          _apiSpots = List.generate(history.length, (i) {
            final double price = (history[i]['price'] as num).toDouble();
            // Multiplica por 1000 se for para se adequar à escala do tooltip legada (opc. spot.y * 1000)
            // Mantemos a escala real dividida por 1000 no Spot para alinhar com o "getTooltipItems: spot.y * 1000" do João Paulo!
            return FlSpot(i.toDouble(), price / 1000);
          });

          _apiDates = history.map((h) {
            try {
              final dt = DateTime.parse(h['timestamp']);
              return "${dt.day}/${dt.month}";
            } catch (e) {
              return "Data";
            }
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<FlSpot> _getMainSpots() {
    if (_apiSpots.isNotEmpty) {
      return _apiSpots;
    }
    switch (_selectedPeriod) {
      case '1M':
        return const [
          FlSpot(0, 14.2),
          FlSpot(1, 14.5),
          FlSpot(2, 14.1),
          FlSpot(3, 14.8),
          FlSpot(4, 15.0),
        ];
      case '6M':
        return const [
          FlSpot(0, 12.0),
          FlSpot(1, 12.5),
          FlSpot(2, 11.8),
          FlSpot(3, 13.0),
          FlSpot(4, 13.5),
          FlSpot(5, 14.2),
          FlSpot(6, 15.0),
        ];
      case '1A':
        return const [
          FlSpot(0, 8.0),
          FlSpot(1, 8.5),
          FlSpot(2, 9.2),
          FlSpot(3, 8.8),
          FlSpot(4, 10.0),
          FlSpot(5, 10.5),
          FlSpot(6, 11.2),
          FlSpot(7, 11.8),
          FlSpot(8, 12.5),
          FlSpot(9, 13.0),
          FlSpot(10, 14.0),
          FlSpot(11, 14.5),
          FlSpot(12, 15.0),
        ];
      case 'Tudo':
        return const [
          FlSpot(0, 2.0),
          FlSpot(1, 3.5),
          FlSpot(2, 3.0),
          FlSpot(3, 4.5),
          FlSpot(4, 5.0),
          FlSpot(5, 6.2),
          FlSpot(6, 5.8),
          FlSpot(7, 7.0),
          FlSpot(8, 8.5),
          FlSpot(9, 9.0),
          FlSpot(10, 10.5),
          FlSpot(11, 11.0),
          FlSpot(12, 12.5),
          FlSpot(13, 13.0),
          FlSpot(14, 14.5),
          FlSpot(15, 15.0),
        ];
      default:
        return const [];
    }
  }

  List<FlSpot> _getBenchmarkSpots() {
    final mainSpots = _getMainSpots();
    if (mainSpots.isEmpty) return [];
    final firstX = mainSpots.first.x;
    final lastX = mainSpots.last.x;
    final firstY = mainSpots.first.y * 0.9;
    final lastY = mainSpots.last.y * 0.85;
    return [FlSpot(firstX, firstY), FlSpot(lastX, lastY)];
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


  @override
  Widget build(BuildContext context) {
    // Busca os pontos do gráfico de acordo com o período selecionado
    final mainSpots = _getMainSpots();

    // Coluna que empilha: botões de período + gráfico + legendas de datas
    return Column(
      children: [
        // ---- SELETOR DE PERÍODO ----
        // Linha de botões (1M, 6M, 1A, Tudo) alinhados à esquerda
        Padding(
          // Espaçamento: 16px acima, 8px abaixo, 12px à esquerda (compensa a margem do 1º botão)
          padding: const EdgeInsets.only(top: 16, bottom: 8, left: 12),
          child: Row(
            // Alinha os botões à esquerda (junto com o saldo acima)
            mainAxisAlignment: MainAxisAlignment.start,
            // Percorre cada opção de período e cria um botão para ela
            children: _periods.map((period) {
              // Verifica se esse botão é o período atualmente selecionado
              final isSelected = period == _selectedPeriod;

              // GestureDetector detecta o toque no botão
              return GestureDetector(
                // Ao tocar, atualiza o estado com o novo período (redesenha o gráfico)
                onTap: () {
                  setState(() => _selectedPeriod = period);
                  _loadPriceHistory();
                },
                child: Container(
                  // Margem horizontal entre cada botão
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  // Padding interno do botão
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  // Estilo visual do botão (arredondado com borda)
                  decoration: BoxDecoration(
                    // Se selecionado: fundo verde; se não: transparente
                    color: isSelected ? _greenAccent : Colors.transparent,
                    // Cantos arredondados em formato de "pílula"
                    borderRadius: BorderRadius.circular(20),
                    // Borda: verde se selecionado, cinza claro se não
                    border: Border.all(
                      color: isSelected ? _greenAccent : Colors.white24,
                      width: 1,
                    ),
                  ),
                  // Texto do botão (ex: "1M", "6M", etc.)
                  child: Text(
                    period,
                    style: TextStyle(
                      // Texto branco se selecionado, acinzentado se não
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 13,
                      // Negrito se selecionado, normal se não
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

        // ---- ÁREA DO GRÁFICO ----
        // O gráfico em si, sem labels no eixo X (as datas ficam numa Row separada abaixo)
        SizedBox(
          // Altura fixa do gráfico
          height: 180,
          child: Padding(
            // Padding lateral para o gráfico não encostar nas bordas da tela
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LineChart(
              LineChartData(
                // Remove a borda ao redor do gráfico
                borderData: FlBorderData(show: false),
                // Remove as linhas de grade do fundo (deixa mais limpo)
                gridData: const FlGridData(show: false),
                // Esconde todos os rótulos dos eixos — as datas são exibidas manualmente
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                // Configuração do tooltip (balão que aparece ao tocar no gráfico)
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    // Garante que o tooltip não sai da tela nas bordas
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    // Formata o texto que aparece no tooltip
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        // Ignora a linha de benchmark (só mostra valor da carteira)
                        if (spot.barIndex == 0) return null;
                        // Converte o valor Y para reais (multiplica por 1000)
                        return LineTooltipItem(
                          'R\$ ${(spot.y * 1000).toStringAsFixed(0)},00',
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
                // Lista com as duas linhas do gráfico
                lineBarsData: [
                  // LINHA 1: Benchmark (referência de mercado)
                  // Linha tracejada branca semitransparente que serve de comparação
                  LineChartBarData(
                    spots: _getBenchmarkSpots(),
                    // Linha reta (sem curvas)
                    isCurved: false,
                    // Branco com 25% de opacidade para não chamar muita atenção
                    color: Colors.white.withOpacity(0.25),
                    barWidth: 1.5,
                    // Padrão tracejado: 6px de linha, 4px de espaço
                    dashArray: [6, 4],
                    // Sem bolinhas nos pontos
                    dotData: const FlDotData(show: false),
                  ),

                  // LINHA 2: Carteira do usuário (linha principal)
                  // Linha verde suavizada que mostra a evolução real do investimento
                  LineChartBarData(
                    spots: mainSpots,
                    // Linha com curvas suaves entre os pontos
                    isCurved: true,
                    // Grau de suavização da curva (0 = reto, 1 = muito curvo)
                    curveSmoothness: 0.25,
                    // Cor verde clara da linha
                    color: _greenLight,
                    // Espessura da linha em pixels
                    barWidth: 2.5,
                    // Configuração da bolinha indicadora no último ponto
                    dotData: FlDotData(
                      show: true,
                      // Só mostra a bolinha no último ponto (valor mais recente)
                      checkToShowDot: (spot, barData) {
                        return spot.x == barData.spots.last.x;
                      },
                      // Personaliza a aparência da bolinha
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: _greenLight,
                          strokeWidth: 2,
                          // Borda branca semitransparente ao redor da bolinha
                          strokeColor: Colors.white.withOpacity(0.6),
                        );
                      },
                    ),
                    // Preenchimento degradê abaixo da linha (efeito "sombra")
                    // Vai de verde semitransparente (no topo) até transparente (na base)
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          // Verde com 35% de opacidade perto da linha
                          _greenAccent.withOpacity(0.35),
                          // Verde quase invisível no meio
                          _greenAccent.withOpacity(0.05),
                          // Totalmente transparente na base
                          Colors.transparent,
                        ],
                        // Define em qual ponto cada cor aparece (0% a 100%)
                        stops: const [0.0, 0.6, 1.0],
                        // Direção do gradiente: de cima para baixo
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
              // Animação suave de 400ms ao trocar de período
              duration: const Duration(milliseconds: 400),
              // Curva de animação com aceleração e desaceleração natural
              curve: Curves.easeInOut,
            ),
          ),
        ),

        // ---- LEGENDAS DE DATAS ----
        // As datas são exibidas numa Row separada do gráfico
        // Isso evita que os labels fiquem cortados ou sobrepostos
        Padding(
          // Mesmo padding lateral do gráfico para ficar alinhado
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            // spaceBetween distribui as datas uniformemente:
            // a primeira fica no início e a última no final
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            // Transforma a lista de datas em widgets Text
            children: _getDateLabels()
                .map(
                  (label) => Text(
                    label,
                    // Estilo discreto: cinza claro e fonte pequena
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
