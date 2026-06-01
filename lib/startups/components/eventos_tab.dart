// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/startups/services/getStartup.dart';
import 'startup_colors.dart';

/// Aba bacana que a gente passa lá na tela da Startup pra ver os próximos 
/// eventos que os caras vão participar (Pitches, rodadas, meetups, etc).
///
/// Dica de Sênior: Veja como separamos isso num StatefulWidget à parte. 
/// Assim a gente concentra o state management e as chamadas de rede só no escopo 
/// da tab! A tela mãe (que mostra as 3 abas) fica leve e não precisa gerenciar nada disso.
class EventosTab extends StatefulWidget {
  final String startupName;
  final StartupService service;

  const EventosTab({super.key, required this.startupName, required this.service});

  @override
  State<EventosTab> createState() => _EventosTabState();
}

class _EventosTabState extends State<EventosTab> {
  // A famosa Promise do Dart. Ela vai guardar a promessa da resposta do banco.
  late Future<List<Map<String, dynamic>>> _eventosFuture;

  @override
  void initState() {
    super.initState();
    // Essa é a nossa Decisão Arquitetural Crítica (Anotem aí galera Junior):
    // A gente congela a chamada do banco dentro do initState! Se jogasse isso solto
    // dentro do build, cada piscada do teclado ia gerar um request na API (R$ chovendo no Firebase).
    _eventosFuture = widget.service.listEventos(widget.startupName);
  }

  @override
  Widget build(BuildContext context) {
    // FutureBuilder é o componente mais amigo da rede!
    // Ele desenha a tela de acordo com o momento da vida da nossa Promise.
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _eventosFuture,
      builder: (context, snapshot) {
        // Fase 1: Rodando a manivela (Waiting...)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: StartupColors.green));
        }

        // Fase 2: Ops! A conexão caiu ou a API cuspiu erro.
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

        // Chegou o dado! O "??" salva se o retorno for null.
        final eventos = snapshot.data ?? [];

        // Fase 3: E se o array veio limpo? (Empty state)
        if (eventos.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_busy_rounded, color: Colors.white12, size: 48),
                SizedBox(height: 12),
                Text(
                  'Nenhum evento agendado.',
                  style: TextStyle(color: Colors.white38, fontSize: 15),
                ),
              ],
            ),
          );
        }

        // Fase 4: Sucesso Total. O ListView.builder monta um widget na tela PRA CADA evento 
        // da nossa lista. É absurdamente mais leve que jogar todos em Column().
        return ListView.builder(
          physics: const BouncingScrollPhysics(), // Scroll com mola elástica pros fãs da maçã.
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          // Um macete ninja: item count + 1 porque a gente usa o espaço do item "0" pra o título.
          itemCount: eventos.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: _SectionTitle('PRÓXIMOS EVENTOS'),
              );
            }
            // Lembra do +1 ali no count? Então, o primeiro item real na lista é eventos[0]. 
            // Só que o index aqui agora tá em 1, por isso subtraímos pra fechar a conta certinha.
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

/// O "Card" visual de um evento específico.
/// Componente simples e stateless pra reaproveitar o código.
class _EventoCard extends StatelessWidget {
  final Map<String, dynamic> evento;

  const _EventoCard({required this.evento});

  @override
  Widget build(BuildContext context) {
    final tipo = evento['tipo'] ?? '';
    final Color tipoColor;
    final IconData tipoIcon;

    // Regrinha de negócio visual! Aqui a gente pinta e customiza o evento dependendo do que ele é.
    switch (tipo) {
      case 'Pitch':
        tipoColor = const Color(0xFF1A9B5F); // Verde de grana e negócio.
        tipoIcon = Icons.mic_rounded;
        break;
      case 'Workshop':
        tipoColor = const Color(0xFFF5A623); // Laranja de estudo/aprendizado.
        tipoIcon = Icons.school_rounded;
        break;
      default:
        tipoColor = const Color(0xFF4A90E2); // Um azul tranquilizador genérico.
        tipoIcon = Icons.bar_chart_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StartupColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Essa Row é nossa etiquetinha de categoria ali no topo esquerdo do card
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tipoColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(tipoIcon, color: tipoColor, size: 16),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tipoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tipoColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  tipo,
                  style: TextStyle(color: tipoColor, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Nomezão do evento na lata
          Text(
            evento['titulo'] ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, height: 1.3),
          ),
          const SizedBox(height: 8),

          // Aquela descrição marota pra convencer o cara
          Text(
            evento['descricao'] ?? '',
            style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 14),

          // Divisória sutil
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),

          // Detalhes da hora do show
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: Colors.white38, size: 13),
              const SizedBox(width: 5),
              Text(
                '${evento['data']}  •  ${evento['horario']}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Onde a mágica acontece. A gente usa o Expanded pra se o nome do local for muito longo 
          // ele empurrar certinho sem quebrar a tela!
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.white38, size: 13),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  evento['local'] ?? '',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Apenas o textão verdinho do título da seção. Modularizado pra manter a ordem.
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
