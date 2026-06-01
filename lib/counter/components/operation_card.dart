// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

// Card de operação executada, exibido no histórico "Minhas Operações".
// Diferentemente do BalcaoOperationCard (específico do Balcão), este card
// suporta múltiplos status (Concluída / Cancelada) e usa o OperationModel
// diretamente, cobrindo tanto compras do Balcão quanto da startup.
// O ponto colorido e o badge de status facilitam a leitura rápida do histórico.

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';
import 'package:mesclainvest_f/model/operationModel.dart';

/// Um card de histórico de operações.
/// Mostra pro usuário o que ele fez no passado (ex: Compra de tokens).
class OperationCard extends StatelessWidget {
  /// O objeto OperationModel que contém os dados a serem exibidos.
  final OperationModel op; 
  
  const OperationCard({super.key, required this.op});

  @override
  Widget build(BuildContext context) {
    // Configura as cores e textos do "Badge" de acordo com o status da operação
    Color statusColor;
    String statusLabel;
    
    // Switch maroto pra tratar os diferentes status.
    switch (op.status) {
      case OperationStatus.accepted:
        statusColor = const Color(0xFF1A9B5F); // Verde de sucesso
        statusLabel = 'Concluída';
        break;
      case OperationStatus.cancelled:
        statusColor = Colors.white38; // Cinza apagado pra cancelado
        statusLabel = 'Cancelada';
        break;
    }

    // Formata o dinheiro usando o utilitário pra colocar aquele "R$" bonitão
    final priceStr = CurrencyInputFormatter.formatValue(op.pricePerToken);
    final totalStr = CurrencyInputFormatter.formatValue(op.total);

    return Container(
      // Margin bottom afasta um histórico do outro
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF262629), // Fundo em tom escuro
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)), // Bordinha sutil
      ),
      child: Row(
        children: [
          // Aquele pontinho verde na esquerda, dá um charme visual
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF1A9B5F), // Verde (pois todas as operações são de compra no MVP)
              shape: BoxShape.circle, // Arredonda pra virar uma bolinha
            ),
          ),
          const SizedBox(width: 12),

          // Coluna Central com os detalhes em texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome da Startup onde rolou o investimento
                Text(
                  op.startupName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                // O descritivo do que rolou: "Compra - N tokens a R$ X"
                Text(
                  'Compra · ${op.quantity} tokens @ $priceStr',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),

          // Coluna da Direita com o Total Gasto e o Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Total R$ da operação
              Text(
                totalStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              // O badge com o status (Concluída ou Cancelada)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  // Fundo é a mesma cor do texto mas com 15% de opacidade
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor, // A cor do texto acompanha a cor decidida no switch
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
