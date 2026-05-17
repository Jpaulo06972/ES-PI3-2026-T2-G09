// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote básico de UI do Flutter
import 'package:flutter/material.dart';
// Importa a paleta de cores oficial do módulo de startups para manter consistência visual
import 'package:mesclainvest_f/startups/components/startup_colors.dart';
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';
import 'package:mesclainvest_f/wallet/pages/operationExtract.dart';

/// Exibe o histórico de transações recentes no estilo das telas de startups.
/// Cada transação é um card com fundo cardBg, bordas sutis e valores coloridos.
class TransactionHistory extends StatelessWidget {
  // Lista de transações — cada item é um Map com icon, title, date, value, isCredit
  final List<Map<String, dynamic>> transactions;

  // Callback quando o botão "Ver tudo" é tocado
  final VoidCallback onViewAll;

  const TransactionHistory({
    super.key,
    required this.transactions,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho da seção no padrão _SectionTitle + botão "Ver tudo" verde
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "ÚLTIMAS TRANSAÇÕES",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            GestureDetector(
              onTap: onViewAll,
              child: const Text(
                "Ver tudo",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Lista de transações renderizada dinamicamente
        ...transactions.map((tx) => _buildTransactionTile(context, tx)),
      ],
    );
  }

  // Constrói um tile individual de transação no estilo cardBg das startups
  Widget _buildTransactionTile(BuildContext context, Map<String, dynamic> tx) {
    final bool isCredit = tx['isCredit'] as bool;
    // Verde para créditos, vermelho para débitos — mesmo padrão de cores das startups
    final Color valueColor = isCredit
        ? const Color(0xFF107649)
        : const Color(0xFFE74C3C);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // Mesmo fundo cardBg das telas de startups
        color: StartupColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        // Borda sutil igual às telas de detalhes
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OperationExtractPage(tx: tx),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
        children: [
          // Ícone dentro de círculo com cor de fundo translúcida
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: valueColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(tx['icon'] as IconData, color: valueColor, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          // Coluna com título e data da transação
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
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  tx['date'] as String,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          // Valor com sinal de + ou - em verde/vermelho
          Text(
            "${isCredit ? '+' : '-'} ${CurrencyInputFormatter.formatValue(tx['value'] as double)}",
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ));
  }
}
