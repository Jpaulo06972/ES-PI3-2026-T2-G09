// Feito por: Tomás Toniato RA: 25004211

import 'package:flutter/material.dart';
import 'startup_colors.dart';

class SociosTab extends StatelessWidget {
  final List<Map<String, dynamic>> founders;

  const SociosTab({super.key, required this.founders});

  @override
  Widget build(BuildContext context) {
    if (founders.isEmpty) {
      return const Center(
        child: Text('Nenhum sócio cadastrado.',
            style: TextStyle(color: Colors.white38, fontSize: 15)),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        const _SectionTitle('COMPOSIÇÃO SOCIETÁRIA'),
        const SizedBox(height: 16),
        _EquityBar(founders: founders),
        const SizedBox(height: 8),
        _EquityLegend(founders: founders),
        const SizedBox(height: 28),
        const _SectionTitle('SÓCIOS E FUNDADORES'),
        const SizedBox(height: 16),
        ...List.generate(
          founders.length,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FounderCard(founder: founders[i], colorIndex: i),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _EquityBar extends StatelessWidget {
  final List<Map<String, dynamic>> founders;

  const _EquityBar({required this.founders});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 18,
        child: Row(
          children: List.generate(founders.length, (i) {
            final pct = (founders[i]['equityPercent'] as num?)?.toDouble() ?? 0;
            final color = StartupColors.chartColors[i % StartupColors.chartColors.length];
            return Flexible(
              flex: (pct * 100).round(),
              child: Container(color: color),
            );
          }),
        ),
      ),
    );
  }
}

class _EquityLegend extends StatelessWidget {
  final List<Map<String, dynamic>> founders;

  const _EquityLegend({required this.founders});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: List.generate(founders.length, (i) {
        final name = (founders[i]['name'] as String?) ?? '';
        final pct = (founders[i]['equityPercent'] as num?)?.toDouble() ?? 0;
        final color = StartupColors.chartColors[i % StartupColors.chartColors.length];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              '$name • ${pct.toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        );
      }),
    );
  }
}

class _FounderCard extends StatelessWidget {
  final Map<String, dynamic> founder;
  final int colorIndex;

  const _FounderCard({required this.founder, required this.colorIndex});

  @override
  Widget build(BuildContext context) {
    final name = (founder['name'] as String?) ?? '';
    final role = (founder['role'] as String?) ?? '';
    final pct = (founder['equityPercent'] as num?)?.toDouble() ?? 0;
    final bio = (founder['bio'] as String?)?.trim() ?? '';
    final color = StartupColors.chartColors[colorIndex % StartupColors.chartColors.length];

    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StartupColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(role, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),
            Text(bio, style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
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
