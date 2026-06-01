// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

import 'package:flutter/material.dart';
import 'startup_colors.dart';

/// [SociosTab] é o componente visual onde o investidor olha quem está pilotando o barco.
/// Investidores não investem apenas em ideias, investem em PESSOAS.
/// 
/// Por que ser Stateless?
/// Porque a lista de sócios raramente muda em tempo real. Não tem ninguém comprando e 
/// vendendo sócios no mercado secundário (rs). Então o pai já passa a lista pronta e a gente só pinta.
class SociosTab extends StatelessWidget {
  final List<Map<String, dynamic>> founders;

  const SociosTab({super.key, required this.founders});

  @override
  Widget build(BuildContext context) {
    // Caso extremo: A startup mandou mal e não cadastrou a galera no sistema ainda.
    // É sempre melhor mostrar um aviso bonitinho do que uma tela branca que parece bug.
    if (founders.isEmpty) {
      return const Center(
        child: Text('Nenhum sócio cadastrado.',
            style: TextStyle(color: Colors.white38, fontSize: 15)),
      );
    }

    // ListView é ótimo aqui porque permite rolar a tela se a startup tiver 20 sócios.
    return ListView(
      physics: const BouncingScrollPhysics(), // Efeitinho elástico do iOS quando bate no fim
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        // O famoso Cap Table (Capitalization Table) desenhado.
        const _SectionTitle('COMPOSIÇÃO SOCIETÁRIA'),
        const SizedBox(height: 16),
        
        // A barrinha que mostra as fatias da pizza
        _EquityBar(founders: founders),
        const SizedBox(height: 8),
        
        // A legenda pra gente saber quem é quem nas fatias
        _EquityLegend(founders: founders),
        const SizedBox(height: 28),

        // Lista do time principal
        const _SectionTitle('SÓCIOS E FUNDADORES'),
        const SizedBox(height: 16),
        
        // Espalha a lista (spread operator "...") pra criar os cards de perfil
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

/// [_EquityBar] cria aquela barra horizontal dividida em bloquinhos coloridos.
/// É uma "pizza" mas no formato de barrinha.
class _EquityBar extends StatelessWidget {
  final List<Map<String, dynamic>> founders;

  const _EquityBar({required this.founders});

  @override
  Widget build(BuildContext context) {
    // Corta as pontas quadradas para ficar suave e redondo.
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 18,
        // Row com Flexibles: O jeito mais seguro de fazer barras proporcionais no Flutter.
        child: Row(
          children: List.generate(founders.length, (i) {
            // Se vier zuado do banco de dados, o "?? 0" salva o dia.
            final pct = (founders[i]['equityPercent'] as num?)?.toDouble() ?? 0;
            
            // Truque ninja do "Módulo (%)": Se tivermos 10 fundadores e só 5 cores na paleta,
            // o módulo faz a cor voltar pro índice 0 e recomeçar. Nunca dá erro de "Index Out of Bounds".
            final color = StartupColors.chartColors[i % StartupColors.chartColors.length];
            
            return Flexible(
              // Flex exige um número inteiro. Então 15.5% vira 1550 (vezes 100).
              flex: (pct * 100).round(),
              child: Container(color: color),
            );
          }),
        ),
      ),
    );
  }
}

/// [_EquityLegend] são aquelas bolinhas e os nomes embaixo da barra.
class _EquityLegend extends StatelessWidget {
  final List<Map<String, dynamic>> founders;

  const _EquityLegend({required this.founders});

  @override
  Widget build(BuildContext context) {
    // Wrap é maravilhoso! Se os nomes não couberem na tela do celular,
    // ele joga o próximo pro andar de baixo automaticamente. Sem aquele erro da fita zebrada.
    return Wrap(
      spacing: 16,     // Espaço do lado
      runSpacing: 8,   // Espaço pra baixo
      children: List.generate(founders.length, (i) {
        final name = (founders[i]['name'] as String?) ?? '';
        final pct = (founders[i]['equityPercent'] as num?)?.toDouble() ?? 0;
        final color = StartupColors.chartColors[i % StartupColors.chartColors.length];
        
        return Row(
          mainAxisSize: MainAxisSize.min, // Ocupa só o espacinho dele
          children: [
            // A bolinha colorida
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              '$name • ${pct.toStringAsFixed(0)}%', // Arredonda a % pra ficar mais bonito
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        );
      }),
    );
  }
}

/// [_FounderCard] é o currículo em miniatura de cada sócio.
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

    // Algoritmo pra tirar as iniciais ("Steve Jobs" -> "SJ").
    // O where previne espaços duplos zoados no meio do nome que estragariam o split.
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
              // Avatar com as iniciais do sujeito
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15), // Fundo translúcido da cor dele
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
              
              // Dados de crachá
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
              
              // Etiqueta bonita mostrando a fatia do bolo dele
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
          
          // Se o cara tiver biografia, a gente traça uma linha e mostra a história dele.
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),
            Text(bio, style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)),
          ],
          const SizedBox(height: 12),
          
          // Um gráfico linear debaixo do card só pra gente ter a noção de tamanho
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100, // LinearProgress pede sempre um número de 0.0 a 1.0 (então dividimos por 100).
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

/// [_SectionTitle] é o nosso cabeçalho padrão, com as letras separadas.
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
