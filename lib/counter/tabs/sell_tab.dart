// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

// Aba de Venda (Sell Tab).
// Aqui o usuário publica pro mercado inteiro quantos tokens ele quer vender e por quanto.
// Ele só consegue escolher as startups que ele REALMENTE tem na carteira.

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';
import 'package:mesclainvest_f/counter/components/empty_prompt.dart';
import 'package:mesclainvest_f/counter/components/field_label.dart';
import 'package:mesclainvest_f/counter/components/section_label.dart';
import 'package:mesclainvest_f/counter/components/startup_dropdown.dart';
import 'package:mesclainvest_f/counter/components/stepper_button.dart';
import 'package:mesclainvest_f/counter/components/summary_row.dart';
import 'package:mesclainvest_f/counter/components/orderBookTable.dart';
import 'package:mesclainvest_f/model/offerModel.dart';

/// Componente completão que controla a aba Vender.
/// Diferente do BuyTab que é burro (Stateless), aqui a gente precisa guardar 
/// o input de quantidade, o input de preço e se o cara apertou o botão "Publicar" (Stateful).
class SellTab extends StatefulWidget {
  final List<Map<String, String>> startups;
  final double userTokensBalance; // O que ele de fato tem na carteira
  final String? selectedStartupId;
  final String? selectedStartupNome;
  final List<OfferModel> vendaOffers;
  final List<OfferModel> compraOffers;
  
  // Callbacks
  final void Function(String id, String nome) onStartupSelected;
  final Future<bool> Function(OfferModel) onPublish; // Bate no backend!

  const SellTab({
    super.key,
    required this.startups,
    required this.userTokensBalance,
    required this.selectedStartupId,
    required this.selectedStartupNome,
    required this.vendaOffers,
    required this.compraOffers,
    required this.onStartupSelected,
    required this.onPublish,
  });

  @override
  State<SellTab> createState() => _SellTabState();
}

class _SellTabState extends State<SellTab> {
  // A QTD inicial sempre será 1 (o mínimo pra vender).
  double _sellQtd = 1;
  // Spinner no botão pra evitar cliques desesperados duplos.
  bool _isPublishing = false;
  // O controlador do campo de input numérico de preço (começa em R$ 1,00).
  final TextEditingController _sellPrecoCtrl = TextEditingController(
    text: '1,00',
  );

  @override
  void dispose() {
    // Matamos o controller sempre que o widget morrer pra evitar memory leak (vazamento de memória).
    _sellPrecoCtrl.dispose();
    super.dispose();
  }

  /// Gancho foda: Quando a prop de fora (a startup selecionada) muda,
  /// o widget pai nos atualiza chamando isso.
  @override
  void didUpdateWidget(covariant SellTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se o usuário trocou a startup no Dropdown, zeramos o formulário
    // pra ele não vender a nova startup com os valores da startup antiga.
    if (oldWidget.selectedStartupId != widget.selectedStartupId) {
      _sellPrecoCtrl.text = '1,00';
      setState(() {
        _sellQtd = 1;
      });
    }
  }

  /// Helper que mastiga o texto zoado com máscara (R$, .) do input de grana
  /// e gospe um double limpinho do Dart pra gente multiplicar as paradas.
  double get _sellPreco {
    final raw = _sellPrecoCtrl.text
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(raw) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      physics: const BouncingScrollPhysics(),
      children: [
        const FieldLabel(text: 'Startup onde você possui tokens'),
        const SizedBox(height: 8),
        
        // Componente do Dropdown
        StartupDropdown(
          startups: widget.startups,
          selectedId: widget.selectedStartupId,
          onSelected: widget.onStartupSelected,
          // Se o array de startups veio vazio, joga o hint dando a real.
          hint: widget.startups.isEmpty
              ? 'Você não possui tokens'
              : 'Selecione a startup',
        ),
        
        // Se ainda não escolheu, fica paradão aqui pedindo pra escolher.
        if (widget.selectedStartupId == null) ...[
          const SizedBox(height: 60),
          const EmptyPrompt(
            message: 'Selecione uma startup para publicar uma oferta de venda',
          ),
        ] else ...[
          const SizedBox(height: 12),

          // Esse Badge Verde maneiro em cima mostra o Saldo dele da startup escolhida.
          // Assim ele sabe até quanto pode dar de Step no Stepper.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF107649).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF107649).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.toll_rounded,
                  color: Color(0xFF1A9B5F),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Seus tokens: ${widget.userTokensBalance} ${widget.selectedStartupNome}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          
          // Pra dar o senso de "Onde eu estou": Título do Book.
          SectionLabel(
            text: 'VENDA — ${widget.selectedStartupNome!.toUpperCase()}',
          ),
          const SizedBox(height: 10),
          
          // O Book de ofertas embutido, mas travado só como Visualização
          // (ele não pode clicar numa VENDA pra vender, daria tilt na mente, kkk).
          OrderBookTable(
            vendaOrders: widget.vendaOffers,
            compraOrders: const [],
            side: OrderBookSide.vendaOnly,
            // não passamos a prop de onTap, tornando a tabela só leitura.
          ),

          const SizedBox(height: 24),
          const SectionLabel(text: 'PUBLICAR OFERTA DE VENDA'),
          const SizedBox(height: 12),
          
          // Chama o miolo do form isolado pra ficar limpo o Build.
          _buildSellForm(),
        ],
      ],
    );
  }

  /// Pedaço de UI onde a mágica acontece. Tem o stepper, input e botão final.
  Widget _buildSellForm() {
    final userTokens = widget.userTokensBalance;
    final total = _sellQtd * _sellPreco;
    
    // Validacao master: O cara tá tentando dar step de venda maior que o saldo dele?
    final enoughTokens = _sellQtd <= userTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------- 1. Quantidade ----------
        const FieldLabel(text: 'Quantidade de tokens'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF262629),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF107649).withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              // Botão MENOS
              StepperButton(
                icon: Icons.remove,
                onTap: () {
                  // Trava inferior: ngm vende 0 tokens.
                  if (_sellQtd > 1) setState(() => _sellQtd--);
                },
              ),
              Expanded(
                child: Text(
                  _sellQtd.toInt().toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Botão MAIS
              StepperButton(
                icon: Icons.add,
                onTap: () {
                  // Trava superior: ele só clica se tiver ficha na mão.
                  if (_sellQtd < userTokens) setState(() => _sellQtd++);
                },
              ),
            ],
          ),
        ),

        // Avisa de forma passivo-agressiva que ele passou do limite se der ruim na validação manual.
        if (!enoughTokens) ...[
          const SizedBox(height: 6),
          Text(
            'Você possui apenas ${userTokens.toInt()} tokens',
            style: const TextStyle(color: Color(0xFFE74C3C), fontSize: 12),
          ),
        ],

        const SizedBox(height: 16),

        // ---------- 2. Preço ----------
        const FieldLabel(text: 'Preço por token (R\$)'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF262629),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF107649).withValues(alpha: 0.4),
            ),
          ),
          child: TextField(
            controller: _sellPrecoCtrl,
            // Teclado numérico, por favor.
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              prefixText: 'R\$ ', // DinheiroBR na cara.
              prefixStyle: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            // Re-renderiza o componente pra atualizar o Painel de Resumo!
            onChanged: (_) => setState(() {}),
          ),
        ),

        const SizedBox(height: 16),

        // ---------- 3. Resumo Financeiro ----------
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF262629),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              SummaryRow(
                label: 'Tokens a vender',
                value: '${_sellQtd.toInt()}',
              ),
              const SizedBox(height: 8),
              SummaryRow(
                label: 'Preço/token',
                value: CurrencyInputFormatter.formatValue(_sellPreco),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Color(0xFF3A3A3A), height: 1),
              ),
              SummaryRow(
                label: 'Total estimado',
                value: CurrencyInputFormatter.formatValue(total),
                highlight: true, // Acende no verdão pra animar ele.
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ---------- 4. Botão de Disparo ----------
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              // Cor desabilitada se: saldo insuficiente, preco zerado, ou carregando transação.
              backgroundColor: enoughTokens && _sellPreco > 0 && !_isPublishing
                  ? const Color(0xFF107649)
                  : Colors.white12,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              elevation: 0,
            ),
            // Passa nulo no onPressed pra desativar o botão real-oficial.
            onPressed: enoughTokens && _sellPreco > 0 && !_isPublishing
                ? _publishSellOffer
                : null,
            child: _isPublishing
                // Se tá _isPublishing, enfia a rodinha do loading e oculta o texto.
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Publicar Oferta de Venda',
                    style: TextStyle(
                      color: enoughTokens && _sellPreco > 0
                          ? Colors.white
                          : Colors.white38,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  /// Sobe pro Backend o pedido do investidor e espera a confirmação da nuvem.
  Future<void> _publishSellOffer() async {
    // Liga a trava no front pra ele não clicar 2x e duplicar o chamado da api.
    setState(() => _isPublishing = true);
    try {
      // Monta o envelopão com a requisição bruta.
      // IDs e Nomes vazios aqui são preenchidos pelo Widget Pai (onde mora a regra de User).
      final offer = OfferModel(
        id: '',
        startupId: widget.selectedStartupId!,
        startupNome: widget.selectedStartupNome!,
        vendedorId: '',
        vendedorNome: '',
        quantidade: _sellQtd,
        precoPorToken: _sellPreco,
        tipo: OrderType.venda,
        criadoEm: DateTime.now(),
      );

      // Função passada por prop bate no CounterService no topo.
      final success = await widget.onPublish(offer);

      // Deu tudo certinho e a página não fechou no meio do caminho? Zera os campos.
      if (success && mounted) {
        _sellPrecoCtrl.text = '1,00';
        setState(() => _sellQtd = 1);
      }
    } finally {
      // O bom e velho finally. Deu erro ou deu sucesso, desliga a trava.
      if (mounted) setState(() => _isPublishing = false);
    }
  }
}
