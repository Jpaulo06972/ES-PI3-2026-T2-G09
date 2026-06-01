// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';
import 'package:mesclainvest_f/wallet/pages/operationExtract.dart';

/// Aquela linha (Tile) de transação individual que aparece na lista do extrato.
///
/// O design é bem "clean", estilo Nubank: ícone redondinho na esquerda,
/// título e subtítulo no meio, e o valor com a hora na direita.
/// Além disso, ele é clicável e leva pros detalhes (comprovante) da transação.
class StatementTransactionTile extends StatelessWidget {
  // Recebe um "Map" que é basicamente um dicionário com todos os dados da transação
  // já mastigados pelo OperationMapper.
  final Map<String, dynamic> tx;

  const StatementTransactionTile({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    // É dinheiro entrando ou saindo?
    final bool isCredit = tx['isCredit'] as bool;

    // Define a cor base da linha.
    // Entrou = Verde (Sucesso). Saiu = Vermelho (Atenção/Débito).
    // Usamos cores em hex com opacidade 100% (0xFF) pros textos brilharem na tela escura.
    final Color valueColor = isCredit
        ? const Color(0xFF2ECC71) // Verde esmeralda bem vivo
        : const Color(0xFFE74C3C); // Vermelho alaranjado

    return Container(
      // Margin cria espaço FORA do card. Padding cria espaço DENTRO.
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        // Fundo com 4% de opacidade de branco. Isso dá um cinza super hiper mega
        // escuro que destaca a linha do fundo "preto" do app.
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      // InkWell é o cara que faz aquele efeito de "ondinha" (ripple) quando toca!
      child: InkWell(
        onTap: () {
          // Quando o usuário tocar na linha, abrimos a página de "Comprovante"
          // passando a transação atual inteirinha pra ela.
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OperationExtractPage(tx: tx)),
          );
        },
        // O borderRadius no InkWell impede que a ondinha do clique "vaze" pelos
        // cantos arredondados do Container.
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            // ── ÍCONE CIRCULAR ──
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                // Usa a cor do valor (verde ou vermelho) mas quase transparente.
                color: valueColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  tx['icon']
                      as IconData, // Pega o ícone certo (Pix, Depósito, etc)
                  color: valueColor, // Pinta o ícone com a cor viva
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14), // Respiro lateral
            // ── TÍTULO E SUBTÍTULO ──
            // O Expanded aqui é VITAL! Se o título for gigante, o texto vai bater
            // no valor lá da direita e quebrar o layout (o famoso RenderFlex overflowed).
            // O Expanded diz: "Cresça até bater no widget vizinho e então pare".
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    // Se o texto não couber, coloca "..." (reticências) no final.
                    overflow: TextOverflow.ellipsis,
                  ),
                  // O if dentro da lista (collection if) só renderiza o subtítulo
                  // se ele realmente existir (não for vazio).
                  if ((tx['subtitle'] as String).isNotEmpty) ...[
                    const SizedBox(
                      height: 2,
                    ), // Espaço minúsculo entre titulo e subtitulo
                    Text(
                      tx['subtitle'] as String,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // ── VALOR E HORÁRIO ──
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end, // Alinha tudo pra direita
              children: [
                Text(
                  // Coloca "+" ou "-" antes do número e formata com R$.
                  "${isCredit ? '+' : '-'} ${CurrencyInputFormatter.formatValue(tx['value'] as double)}",
                  style: TextStyle(
                    color: valueColor, // Verde se entrou, Vermelho se saiu
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  // Extrai só a hora ("15:30") da data completa ("12/04/2026 15:30")
                  _extractTime(tx['date'] as String),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 11, // Fonte bem pequenininha, só de contexto
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Pega a string de data (que vem do banco tipo "14/05/2026 14:32")
  /// e devolve só a hora ("14:32"). Como as transações já estão agrupadas por DIA,
  /// não precisamos repetir o dia em cada linha. Apenas a hora importa aqui.
  String _extractTime(String dateStr) {
    // Quebra a string no espaço vazio. Resulta num array: ["14/05/2026", "14:32"]
    final parts = dateStr.split(' ');
    // Se o array tiver 2 pedaços, retorna o segundo (a hora).
    if (parts.length >= 2) {
      return parts[1];
    }
    // Se não tiver (talvez o formato veio zuado do banco), retorna vazio
    // pra não dar erro na tela.
    return '';
  }
}
