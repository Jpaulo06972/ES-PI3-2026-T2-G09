// Feito por: Tomás Toniato RA: 25004211
// Integrado por: João Paulo Ferreira RA: 25000684

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'startup_colors.dart';
import 'inline_video_player.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/counter/services/counterService.dart';
import 'package:mesclainvest_f/counter/pages/balcao_orders_screen.dart';

class SobreTab extends StatefulWidget {
  final Map<String, dynamic> data;
  final UserModel userModel;
  final VoidCallback? onRefresh;

  const SobreTab({
    super.key,
    required this.data,
    required this.userModel,
    this.onRefresh,
  });

  @override
  State<SobreTab> createState() => _SobreTabState();
}

class _SobreTabState extends State<SobreTab> {
  final CounterService _counterService = CounterService();
  double _userHoldings = 0.0;
  bool _loadingHoldings = true;

  @override
  void initState() {
    super.initState();
    _loadUserHoldings();
  }

  @override
  void didUpdateWidget(covariant SobreTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data['id'] != widget.data['id']) {
      _loadUserHoldings();
    }
  }

  Future<void> _loadUserHoldings() async {
    setState(() => _loadingHoldings = true);
    try {
      final holdings = await _counterService.getUserTokens(widget.data['id'] ?? '');
      if (mounted) {
        setState(() {
          _userHoldings = holdings;
          _loadingHoldings = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingHoldings = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final startupId = (widget.data['id'] ?? '').toString();
    final startupName = (widget.data['name'] ?? 'Startup').toString();
    final rawTokens = widget.data['totalTokensIssued'] ?? widget.data['tokens'] ?? 0;
    final rawCapital = widget.data['capitalRaisedCents'] ?? widget.data['capital'] ?? 0;
    final rawTokenPrice = widget.data['currentTokenPriceCents'] ?? 0;
    
    final int totalTokens = int.tryParse(rawTokens.toString()) ?? 0;
    final int tokensSold = int.tryParse((widget.data['tokensSold'] ?? 0).toString()) ?? 0;
    final availableTokens = widget.data['availableTokens'] ?? widget.data['available'] ?? (totalTokens - tokensSold);
    final description =
        (widget.data['description'] ?? widget.data['descricao'] ?? '').toString().trim();
    final demoVideos = (widget.data['demoVideos'] as List<dynamic>? ?? [])
        .map((e) => e.toString().trim())
        .where((url) => url.isNotEmpty)
        .toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(value: _formatTokenPrice(rawTokenPrice), label: 'Preço\ntoken')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(value: _formatTokens(rawTokens), label: 'Tokens\nemitidos')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(value: _formatCapital(rawCapital), label: 'Captado')),
          ],
        ),
        const SizedBox(height: 24),

        // WIDGET DE COMPRA/VENDA DIRETA OU REDIRECIONAMENTO AO BALCÃO
        _buildTradingWidget(startupId, startupName, rawTokenPrice, availableTokens),

        const SizedBox(height: 24),
        const _SectionTitle('SUMÁRIO EXECUTIVO'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: StartupColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Text(
            description.isNotEmpty ? description : '--',
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
          ),
        ),
        const SizedBox(height: 28),
        const _SectionTitle('VÍDEO DEMO'),
        const SizedBox(height: 12),
        _DemoVideosSection(demoVideos: demoVideos),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTradingWidget(
    String startupId,
    String startupName,
    dynamic rawTokenPrice,
    dynamic availableTokensVal,
  ) {
    final int available = int.tryParse(availableTokensVal.toString()) ?? 0;
    final double pricePerToken = (num.tryParse(rawTokenPrice.toString()) ?? 0) / 100;

    final bool hasTokensAvailable = available > 0;

    if (hasTokensAvailable) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: StartupColors.cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF1A9B5F).withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tokens disponíveis',
              style: TextStyle(
                color: Color(0xFF1A9B5F),
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Preço atual:',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                Text(
                  'R\$ ${pricePerToken.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tokens disponíveis:',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                Text(
                  NumberFormat('#,##0', 'pt_BR').format(available),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Seus tokens:',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                _loadingHoldings
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: StartupColors.green,
                        ),
                      )
                    : Text(
                        NumberFormat('#,##0', 'pt_BR').format(_userHoldings.toInt()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF107649),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => _openTradeScreen(startupId, startupName, 'buy'),
                      child: const Text(
                        'Comprar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _userHoldings > 0
                            ? const Color(0xFFE74C3C)
                            : Colors.white12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _userHoldings > 0
                          ? () => _openTradeScreen(startupId, startupName, 'sell')
                          : null,
                      child: Text(
                        'Vender',
                        style: TextStyle(
                          color: _userHoldings > 0 ? Colors.white : Colors.white38,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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
    } else {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: StartupColors.cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tokens esgotados pela startup',
              style: TextStyle(
                color: Color(0xFFE74C3C),
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Preço atual:',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                Text(
                  'R\$ ${pricePerToken.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Seus tokens:',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                _loadingHoldings
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: StartupColors.green,
                        ),
                      )
                    : Text(
                        NumberFormat('#,##0', 'pt_BR').format(_userHoldings.toInt()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF107649),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BalcaoOrdersScreen(
                        startupId: startupId,
                        startupName: startupName,
                        userModel: widget.userModel,
                      ),
                    ),
                  ).then((_) {
                    _loadUserHoldings();
                    if (widget.onRefresh != null) {
                      widget.onRefresh!();
                    }
                  });
                },
                icon: const Icon(Icons.swap_horizontal_circle_outlined, color: Colors.white),
                label: const Text(
                  'Ver Negociações no Balcão',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (!_loadingHoldings && _userHoldings > 0) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE74C3C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => _openTradeScreen(startupId, startupName, 'sell'),
                  child: const Text(
                    'Vender meus tokens',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }
  }

  void _openTradeScreen(String startupId, String startupName, String mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BalcaoOrdersScreen(
          startupId: startupId,
          startupName: startupName,
          userModel: widget.userModel,
          initialMode: mode,
        ),
      ),
    ).then((_) {
      _loadUserHoldings();
      if (widget.onRefresh != null) {
        widget.onRefresh!();
      }
    });
  }

  String _formatTokens(dynamic value) {
    final num v = num.tryParse(value.toString()) ?? 0;
    if (v == 0) return '--';
    return NumberFormat('#,##0', 'pt_BR').format(v);
  }

  String _formatCapital(dynamic value) {
    final num v = num.tryParse(value.toString()) ?? 0;
    if (v == 0) return '--';
    final double reais = v / 100;
    if (reais >= 1000000) return 'R\$${(reais / 1000000).toStringAsFixed(1)}M';
    if (reais >= 1000) return 'R\$${(reais / 1000).toStringAsFixed(0)}k';
    return 'R\$${reais.toStringAsFixed(0)}';
  }

  String _formatTokenPrice(dynamic value) {
    final num v = num.tryParse(value.toString()) ?? 0;
    if (v == 0) return '--';
    return 'R\$${(v / 100).toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: StartupColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: StartupColors.green,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _DemoVideosSection extends StatelessWidget {
  final List<String> demoVideos;

  const _DemoVideosSection({required this.demoVideos});

  @override
  Widget build(BuildContext context) {
    if (demoVideos.isEmpty) {
      return Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: StartupColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off_rounded, color: Colors.white24, size: 36),
              SizedBox(height: 8),
              Text('Nenhum vídeo disponível',
                  style: TextStyle(color: Colors.white38, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: List.generate(demoVideos.length, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: i < demoVideos.length - 1 ? 16 : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (demoVideos.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Vídeo Demo ${i + 1}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              InlineVideoPlayer(videoUrl: demoVideos[i]),
            ],
          ),
        );
      }),
    );
  }
}
