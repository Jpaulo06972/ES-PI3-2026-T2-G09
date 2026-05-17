// Feito por: Tomás Toniato RA: 25004211

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'startup_colors.dart';
import 'inline_video_player.dart';

class SobreTab extends StatelessWidget {
  final Map<String, dynamic> data;

  const SobreTab({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final rawTokens = data['totalTokensIssued'] ?? data['tokens'] ?? 0;
    final rawCapital = data['capitalRaisedCents'] ?? data['capital'] ?? 0;
    final rawTokenPrice = data['currentTokenPriceCents'] ?? 0;
    final description =
        (data['description'] ?? data['descricao'] ?? '').toString().trim();
    final demoVideos = (data['demoVideos'] as List<dynamic>? ?? [])
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
        const SizedBox(height: 28),
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
