// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

// Card genérico de oferta do Balcão.
// Exibe o nome da startup, quantidade disponível, preço por token e um botão
// de ação configurável (ex.: "Comprar", "Cancelar").
// A ação e a cor do botão são injetadas pelo pai, tornando o card reutilizável
// tanto na aba de compra quanto na listagem de ordens próprias.

import 'package:mesclainvest_f/components/currencyInputFormatter.dart';
import 'package:flutter/material.dart';
import 'package:mesclainvest_f/model/offerModel.dart';

/// Card de oferta versátil. 
/// Pense nele como um post-it que mostra "Vende-se N tokens a R$ X".
/// A cor e a função do botão mudam se o usuário estiver comprando ou cancelando
/// a própria ordem.
class OfferCard extends StatelessWidget {
  /// Dados completos da oferta, vindos do Firestore.
  final OfferModel offer; 
  
  /// O que vai escrito no botão (ex: 'Comprar', ou 'Cancelar').
  final String actionLabel; 
  
  /// A cor do botão de ação. Verde pra comprar, vermelho pra cancelar, etc.
  final Color actionColor; 
  
  /// O que acontece quando o cara clica no botão.
  final VoidCallback onAction; 

  const OfferCard({
    super.key,
    required this.offer,
    required this.actionLabel,
    required this.actionColor,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Margin bottom afasta um card do próximo na lista
      margin: const EdgeInsets.only(bottom: 12),
      // Padding interno pro texto não grudar na borda
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF262629), // Um cinza bem escuro pra destacar do fundo
        borderRadius: BorderRadius.circular(14),
        // Bordinha branca com 5% de opacidade pra dar uma estilizada
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // A Coluna principal usa Expanded para ocupar todo o espaço esquerdo
          // e empurrar o resto para a direita.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Alinha os textos à esquerda
              children: [
                // Nome da Startup. Destacamos ele com um branco mais forte.
                Text(
                  offer.startupNome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600, // Semi-negrito
                  ),
                ),
                const SizedBox(height: 4),
                // Exibe a quantidade disponível convertida pra Inteiro.
                Text(
                  'Qtd: ${offer.quantidade.toInt()} tokens',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),

          // Coluna central: O Preço da criança!
          Column(
            crossAxisAlignment: CrossAxisAlignment.end, // Alinhado à direita do seu bloquinho
            children: [
              // Preço formatado com nossa classe utilitária (R$ 10,00)
              Text(
                CurrencyInputFormatter.formatValue(offer.precoPorToken),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700, // Preço tem que pular no olho (bold)
                ),
              ),
              // Aquela legendinha marota embaixo do preço
              const Text(
                '/token',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          
          // Espaçinho pra não grudar no botão
          const SizedBox(width: 12),

          // E finalmente, o botão dinâmico!
          // Usamos GestureDetector pra criar um botão com tamanho sob medida
          GestureDetector(
            onTap: onAction, // Roda a lógica que o widget pai passou
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                // Usa a cor repassada (actionColor) pro fundo
                color: actionColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                actionLabel, // E escreve o que tiver que escrever
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
