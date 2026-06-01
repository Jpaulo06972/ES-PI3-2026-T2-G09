// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

// Componente visual da Aba de Compras do Balcão.
// Mostra o formulário para escolher a startup e o book (livro de ofertas)
// para o investidor ver o que tá rolando e dar o bote.

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/counter/components/empty_prompt.dart';
import 'package:mesclainvest_f/counter/components/field_label.dart';
import 'package:mesclainvest_f/counter/components/offer_row_compra.dart';
import 'package:mesclainvest_f/counter/components/section_label.dart';
import 'package:mesclainvest_f/counter/components/startup_dropdown.dart';
import 'package:mesclainvest_f/counter/components/orderBookTable.dart';
import 'package:mesclainvest_f/model/offerModel.dart';

/// Aba Comprar - A vitrine do mercado secundário.
/// Pega os dados brutos e transforma na UI de negociação. Não tem estado (Stateless), 
/// então ela é burra: só obedece as props passadas pelo `CounterPage`.
class BuyTab extends StatelessWidget {
  // Lista de startups pro Dropdown
  final List<Map<String, String>> startups;
  
  // ID e Nome da startup que o cara escolheu
  final String? selectedStartupId;
  final String? selectedStartupNome;
  
  // As ofertas vindas do Firestore (Book)
  final List<OfferModel> vendaOffers;
  final List<OfferModel> compraOffers;
  
  // Callbacks de interação
  final void Function(String id, String nome) onStartupSelected;
  final void Function(OfferModel) onOfferTap;
  final void Function(String startupId, String startupNome)? onBuyFromStartup;

  const BuyTab({
    super.key,
    required this.startups,
    required this.selectedStartupId,
    required this.selectedStartupNome,
    required this.vendaOffers,
    required this.compraOffers,
    required this.onStartupSelected,
    required this.onOfferTap,
    this.onBuyFromStartup,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      // Padding maroto pra desgrudar das bordas da tela
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      // Física iOS-style (elástico)
      physics: const BouncingScrollPhysics(),
      children: [
        // Títulozinho do Dropdown
        const FieldLabel(text: 'Selecione a startup'),
        const SizedBox(height: 8),
        
        // Componente do Dropdown em si
        StartupDropdown(
          startups: startups,
          selectedId: selectedStartupId,
          onSelected: onStartupSelected,
        ),
        
        // Se o cara ainda não escolheu nada, mostra o prompt vazio bonitinho.
        if (selectedStartupId == null) ...[
          const SizedBox(height: 60),
          const EmptyPrompt(
            message: 'Selecione uma startup para ver as ordens disponíveis',
          ),
        ] else ...[
          // Se já escolheu, desce a lenha e mostra o Book!
          const SizedBox(height: 24),
          
          // Cabeçalho da seção com o nome da startup em caixa alta pra dar peso.
          SectionLabel(text: 'COMPRA — ${selectedStartupNome!.toUpperCase()}'),
          const SizedBox(height: 10),
          
          // A tabela de preços do Book de ofertas.
          // Aqui passamos side: vendaOnly pra mostrar só quem tá querendo vender
          // (já que o usuário está na aba de comprar, ele quer comprar as vendas dos outros).
          OrderBookTable(
            vendaOrders: vendaOffers,
            compraOrders: const [], // Vazio de propósito, limpamos a view.
            onVendaTap: onOfferTap,
            side: OrderBookSide.vendaOnly,
            showAsCompra: true,
          ),
          
          const SizedBox(height: 24),
          
          // O Call to Action pro cara.
          const SectionLabel(text: 'CLIQUE EM UMA OFERTA PARA COMPRAR'),
          const SizedBox(height: 10),
          
          // Se o Book secou (ninguém vendendo), oferece a saída de mestre:
          if (vendaOffers.isEmpty) ...[
            const EmptyPrompt(
              message: 'Nenhuma oferta de venda no balcão para esta startup',
            ),
            
            // Botão salvador "Comprar direto da startup" 
            // Só aparece se a prop onBuyFromStartup foi passada.
            if (onBuyFromStartup != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF107649),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => onBuyFromStartup!(
                    selectedStartupId!,
                    selectedStartupNome!,
                  ),
                  icon: const Icon(
                    Icons.store_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Comprar direto da startup',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ] else
            // Mapeia as ofertas reais num cardzão clicável
            // O ... (spread operator) espalha a lista dentro dos children do ListView.
            ...vendaOffers.map(
              (offer) =>
                  OfferRowCompra(offer: offer, onTap: () => onOfferTap(offer)),
            ),
        ],
      ],
    );
  }
}
