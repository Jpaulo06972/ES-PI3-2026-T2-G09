// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684
// Feito originalmente por: Tomás Toniato RA: 25004211

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/startups/services/getStartup.dart';
import 'startup_colors.dart';

/// Aba que exibe o histórico e próximos eventos da startup.
class EventosTab extends StatefulWidget {
  final String startupName;
  final StartupService service;

  const EventosTab({super.key, required this.startupName, required this.service});

  @override
  State<EventosTab> createState() => _EventosTabState();
}

class _EventosTabState extends State<EventosTab> {
  late Future<List<Map<String, dynamic>>> _eventosFuture;

  @override
  void initState() {
    super.initState();
    _eventosFuture = widget.service.listEventos(widget.startupName);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _eventosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: StartupColors.green));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Erro ao carregar eventos:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
            ),
          );
        }

        final eventos = snapshot.data ?? [];

        if (eventos.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_busy_rounded, color: Colors.white12, size: 48),
                SizedBox(height: 12),
                Text('Nenhum evento agendado.',
                    style: TextStyle(color: Colors.white38, fontSize: 15)),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: eventos.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: _SectionTitle('PRÓXIMOS EVENTOS'),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _EventoCard(evento: eventos[index - 1]),
            );
          },
        );
      },
    );
  }
}

class _EventoCard extends StatelessWidget {
  final Map<String, dynamic> evento;
  const _EventoCard({required this.evento});

  @override
  Widget build(BuildContext context) {
    final tipo = evento['tipo'] ?? '';
    final Color tipoColor;
    final IconData tipoIcon;

    switch (tipo) {
      case 'Pitch':
        tipoColor = StartupColors.green;
        tipoIcon = Icons.mic_rounded;
        break;
      case 'Workshop':
        tipoColor = const Color(0xFFF5A623);
        tipoIcon = Icons.school_rounded;
        break;
      default:
        tipoColor = const Color(0xFF4A90E2);
        tipoIcon = Icons.bar_chart_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StartupColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: tipoColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(tipoIcon, color: tipoColor, size: 16),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tipoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tipoColor.withOpacity(0.3)),
                ),
                child: Text(tipo, style: TextStyle(color: tipoColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(evento['titulo'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 8),
          Text(evento['descricao'] ?? '', style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)),
          const SizedBox(height: 14),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: Colors.white38, size: 13),
              const SizedBox(width: 5),
              Text('${evento['data']}  •  ${evento['horario']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.white38, size: 13),
              const SizedBox(width: 5),
              Expanded(child: Text(evento['local'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12))),
            ],
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
    return Text(text, style: const TextStyle(color: StartupColors.green, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5));
  }
}
