// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

// Linha de oferta de venda clicável na aba "Comprar" do Balcão.
// Exibe as informações do vendedor, quantidade disponível e preço por token.
// Todo o card é tocável (GestureDetector envolve tudo), facilitando o toque
// em qualquer parte da linha — UX mais amigável para mobile.
// Ao tocar, abre o bottom sheet de confirmação de compra.

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';
import 'package:mesclainvest_f/model/offerModel.dart';

/// Exibe uma oferta específica na lista do Livro de Ordens (OrderBook).
/// É aquele cardzão comprido onde a pessoa toca pra comprar.
class OfferRowCompra extends StatelessWidget {
  /// Dados da oferta vinda do Firebase.
  final OfferModel offer; 
  
  /// Função acionada ao tocar em *qualquer lugar* da linha.
  final VoidCallback onTap; 

  const OfferRowCompra({super.key, required this.offer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // GestureDetector é o pai de tudo aqui. 
    // Isso é ótimo pro usuário: ele não precisa "mirar" no botão verde.
    // Tocar na bordinha do card já aciona a ação de compra.
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF262629), // Cinza escuro de fundo
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)), // Contorno suave
        ),
        child: Row(
          children: [
            // Informações principais (quem vende e quanto tem) ficam na esquerda
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome do vendedor em branco puro para destacar
                  Text(
                    offer.vendedorNome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // A quantidade aparece embaixo, meio apagadinha
                  Text(
                    '${offer.quantidade.toInt()} tokens disponíveis',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Preço por token - usamos uma coluna para alinhar à direita
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Formatamos para Real (R$).
                // Destaque: o preço da COMPRA aparece em VERDE (Color 0xFF1A9B5F).
                Text(
                  CurrencyInputFormatter.formatValue(offer.precoPorToken),
                  style: const TextStyle(
                    color: Color(0xFF1A9B5F), 
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                // Subtítulo do preço
                const Text(
                  '/token',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
            
            // Espacinho antes do Badge
            const SizedBox(width: 12),

            // O Badge "Comprar"
            // Nota: Este não é um ElevatedButton interativo. Ele é só um desenho (Container).
            // Quem capta o clique é o GestureDetector que envolve a linha toda lá em cima!
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF107649), // Fundo verde escuro
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Comprar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
