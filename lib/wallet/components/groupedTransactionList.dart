// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/wallet/components/statementTransactionTile.dart';

/// Lista de transações agrupada por data com separadores estilosos (tipo Nubank).
///
/// Por que agrupar por data? Imagina ler um extrato gigante onde toda linha
/// repete a data... é cansativo para os olhos, né? Agrupando por dia e colocando
/// um separador visual ("HOJE", "ONTEM"), o usuário escaneia a lista muito mais rápido.
class GroupedTransactionList extends StatelessWidget {
  // A lista já vem formatada (mapeada pelo OperationMapper).
  // Ela contém todos os dados que precisamos exibir.
  final List<Map<String, dynamic>> transactions;

  // Nossa cor verde principal definida como constante para manter o código limpo
  // e evitar de digitar o hex errado espalhado por aí.
  static const Color primaryGreen = Color(0xFF107649);

  // O construtor. Sempre use o const nas declarações quando possível,
  // ajuda o Flutter a economizar memória!
  const GroupedTransactionList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Primeiro passo: pegamos o "linguição" de transações e separamos em
    // potinhos por dia. Cada chave do Map será uma data.
    final grouped = _groupByDate(transactions);

    // Pegamos só as chaves (as datas em si) para podermos iterar sobre elas
    // e criar um grupo para cada uma na tela.
    final dateKeys = grouped.keys.toList();

    // ListView.builder é a melhor escolha para listas que podem crescer bastante.
    // Em vez de renderizar tudo de uma vez (o que travaria o app), ele só desenha
    // na tela o que o usuário está vendo no momento (lazy loading).
    return ListView.builder(
      // BouncingScrollPhysics dá aquele efeitinho de "elástico" gostoso
      // quando você chega no final da lista, típico do iOS.
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      // A quantidade de itens na nossa lista principal será a quantidade de DIAS (grupos),
      // e não de transações individuais.
      itemCount: dateKeys.length,

      // O builder vai ser chamado uma vez para cada dia.
      itemBuilder: (context, groupIndex) {
        final dateKey =
            dateKeys[groupIndex]; // A data deste grupo (ex: "14/05/2026")
        final items = grouped[dateKey]!; // As transações que rolaram nesse dia

        return Column(
          // Alinhamos o separador à esquerda.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Esse Padding cria o nosso cabeçalho de data (o separador).
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Row(
                children: [
                  // Aqui formatamos a data para algo amigável ("HOJE", "ONTEM").
                  Text(
                    _formatDateLabel(dateKey),
                    style: TextStyle(
                      // Usamos um branco bem transparente para ficar sutil
                      // e não roubar a atenção dos valores das transações.
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // O Expanded vai empurrar essa linha até o final do espaço disponível.
                  // É como se dissesse: "preencha todo o espaço que sobrou na Row".
                  Expanded(
                    child: Container(
                      height: 1, // Altura de 1 pixel = uma linha fininha.
                      color: Colors.white.withValues(
                        alpha:
                            0.06, // Quase invisível, apenas um charme visual.
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // O "spread operator" (...) é sensacional aqui. Ele pega a nossa lista de
            // transações e "despeja" cada item dentro da Column como um StatementTransactionTile.
            // Sem isso, teríamos que fazer um loop ou usar um Column dentro de Column.
            ...items.map((tx) => StatementTransactionTile(tx: tx)),
          ],
        );
      },
    );
  }

  /// Pega uma lista plana de transações e a transforma em um Map
  /// onde a chave é a data e o valor é a lista de transações daquele dia.
  /// Isso é como pegar uma caixa cheia de recibos e separar em pastas por dia.
  Map<String, List<Map<String, dynamic>>> _groupByDate(
    List<Map<String, dynamic>> transactions,
  ) {
    // O Dart usa LinkedHashMap por padrão, o que é ótimo porque ele preserva
    // a ordem em que inserimos as coisas. Assim, a ordem cronológica não se perde!
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final tx in transactions) {
      // Nosso campo 'date' costuma vir "dd/MM/yyyy HH:mm".
      // Com o split(' '), quebramos no espaço e pegamos só a primeira parte (a data).
      final dateStr = (tx['date'] as String).split(' ').first;

      // O putIfAbsent é uma mão na roda. Ele checa: "já tem lista pra essa data?"
      // Se não tem, ele cria uma lista vazia. Se tem, não faz nada.
      grouped.putIfAbsent(dateStr, () => []);

      // Aí sim, garantimos que a lista existe e adicionamos a transação nela.
      grouped[dateStr]!.add(tx);
    }
    return grouped;
  }

  /// Formata a string de data para uma label mais humana.
  /// Se foi hoje, mostra "HOJE". Se foi ontem, "ONTEM".
  /// Se for mais antigo, "14 MAI 2026".
  /// Por que fazemos isso? Porque o cérebro do usuário processa "HOJE"
  /// muito mais rápido do que "14/05/2026". UX na veia!
  String _formatDateLabel(String dateStr) {
    try {
      final parts = dateStr.split('/');
      // Garantimos que a string de data tenha as três partes: dia, mês e ano.
      if (parts.length >= 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);

        final date = DateTime(year, month, day); // Data da transação
        final now = DateTime.now(); // Data de hoje

        // Dica de ouro: ao comparar datas, sempre "zere" a hora, minuto e segundo.
        // Se comparar só `now` com `date`, vai dar falso porque o `now` tem horas e o `date` não.
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(
          const Duration(days: 1),
        ); // Dia de ontem

        // Mágica da UX: se for hoje ou ontem, não mostramos a data por extenso.
        if (date == today) return 'HOJE';
        if (date == yesterday) return 'ONTEM';

        // Array de meses. O índice 0 é vazio porque os meses começam em 1 no Dart (1=JAN).
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

        // padLeft(2, '0') garante que dias menores que 10 ganhem um zero na frente.
        // Exemplo: 7 vira "07". Fica muito mais alinhadinho na tela.
        return '${day.toString().padLeft(2, '0')} ${months[month]} $year';
      }
    } catch (_) {
      // Se der qualquer zica na hora de converter as datas (parse falhar, por exemplo),
      // a gente cai em pé e retorna a data original bruta em vez de crashar o app.
      // O usuário pode achar feio, mas pelo menos vê a informação!
    }
    // Retorno de fallback.
    return dateStr;
  }
}
