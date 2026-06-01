// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

// Bottom sheet de compra multi-vendedor no Balcão.
// Implementa o algoritmo de "casamento" (matching) greedy do lado do cliente:
// ao definir a quantidade desejada, o sistema busca as ofertas de venda
// abertas e as distribui em ordem crescente de preço (menor primeiro),
// simulando o custo real antes da confirmação.
// Isso garante ao investidor transparência total antes de executar a compra.

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/model/offerModel.dart';
import 'package:mesclainvest_f/counter/services/counterService.dart';

/// Uma "gaveta" que permite comprar de MÚLTIPLOS vendedores de uma vez.
/// O usuário diz quantos tokens quer, e o sistema varre as ofertas mais baratas
/// para montar a compra.
class MultiSellerPurchaseSheet extends StatefulWidget {
  final String startupId; // ID da startup que está sendo comprada.
  final String startupName; // Nome visível no título da gaveta.
  final UserModel userModel; // Precisamos do saldo e ID do usuário para bater a compra.
  final OfferModel initialTargetOffer; // Oferta que ele clicou para abrir a tela.

  const MultiSellerPurchaseSheet({
    super.key,
    required this.startupId,
    required this.startupName,
    required this.userModel,
    required this.initialTargetOffer,
  });

  @override
  State<MultiSellerPurchaseSheet> createState() =>
      _MultiSellerPurchaseSheetState();
}

class _MultiSellerPurchaseSheetState extends State<MultiSellerPurchaseSheet> {
  // Instância do serviço que conversa com o Firebase
  final CounterService _service = CounterService();

  // Quantidade que o usuário quer levar (começa com 1)
  double _qty = 1;
  // Todas as ofertas de venda dessa startup que estão abertas no mercado
  List<OfferModel> _activeSellOffers = [];
  // Controle do loading enquanto busca do banco
  bool _loadingOffers = true;

  // Guarda o detalhamento de QUEM estamos comprando e QUANTO vai custar
  List<Map<String, dynamic>> _simulation = [];
  // Soma total de tudo que será gasto
  double _totalCost = 0.0;
  // Fica true se o usuário pedir mais tokens do que o mercado tem pra vender
  bool _insufficientOffers = false;
  // Controle para evitar duplo clique ao comprar
  bool _isSubmitting = false;
  // Se der erro na compra, a mensagem aparece aqui
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Inicia a quantidade com a mesma quantidade da oferta que ele clicou
    _qty = widget.initialTargetOffer.quantidade;
    // Puxa as ofertas do banco e já simula
    _fetchSellOffersAndSimulate();
  }

  /// Busca as ofertas de venda ativas e já roda a simulação inicial.
  Future<void> _fetchSellOffersAndSimulate() async {
    // Avisa a tela que começou a carregar
    setState(() => _loadingOffers = true);
    try {
      // Pede ao serviço a lista de quem tá vendendo os tokens dessa startup
      final list = await _service.getVendaForStartup(widget.startupId);
      
      // Ordena por preço crescente. Aqui é o coração do "greedy algorithm"!
      // Vamos tentar sempre comprar do cara que tá vendendo mais barato.
      list.sort((a, b) => a.precoPorToken.compareTo(b.precoPorToken));
      
      if (mounted) {
        setState(() {
          _activeSellOffers = list;
          _loadingOffers = false;
          // Com a lista pronta, rodamos a simulação para saber quanto vai dar
          _runSimulation(_qty); 
        });
      }
    } catch (_) {
      // Deu ruim na busca? Apenas esconde o loading e deixa a lista vazia.
      if (mounted) setState(() => _loadingOffers = false);
    }
  }

  /// Pega a quantidade desejada e vai casando com as ofertas ativas (do mais barato pro mais caro)
  void _runSimulation(double qty) {
    // Limpa a simulação anterior
    _simulation = [];
    _totalCost = 0.0;
    _insufficientOffers = false;

    if (qty <= 0) return; // Se pediu 0 ou menos, nem simula.

    double remaining = qty; // Contador de quantos tokens ainda faltam comprar

    // Passa oferta por oferta (elas já estão do mais barato pro mais caro)
    for (final offer in _activeSellOffers) {
      if (remaining <= 0) break; // Já achou tudo que precisava, para o loop.

      // Previne comprar tokens de si mesmo!
      if (offer.vendedorId == widget.userModel.uid) continue;

      // Se a oferta tem menos do que eu preciso, pego tudo que ela tem.
      // Se tem mais, pego só o que preciso (remaining).
      double fill = remaining < offer.quantidade ? remaining : offer.quantidade;
      double cost = fill * offer.precoPorToken; // Calcula quanto essa "fatia" vai custar

      // Salva essa fatia para mostrar na telinha de recibo
      _simulation.add({
        'sellerName':
            offer.vendedorNome.isNotEmpty &&
                offer.vendedorNome != 'Outro Usuário'
            ? offer.vendedorNome
            // Se não tiver nome, a gente faz um "Vendedor #1A2B" charmoso usando o UID
            : 'Vendedor #${offer.vendedorId.substring(0, 4).toUpperCase()}',
        'quantity': fill,
        'price': offer.precoPorToken,
        'total': cost,
      });

      // Soma o custo dessa fatia no total
      _totalCost += cost;
      // Abate os tokens encontrados da meta total
      remaining -= fill;
    }

    // Se o loop terminou e ainda falta token, o mercado não deu conta do pedido.
    if (remaining > 0) {
      _insufficientOffers = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Puxa o saldo do usuário para um nome mais amigável
    final double availableBalance = widget.userModel.saldo;
    // O botão de comprar só habilita se a carteira aguentar a paulada
    final bool hasBalance = availableBalance >= _totalCost;

    return Container(
      // Padding pro modal subir se o teclado aparecer (embora aqui só tenha botões +/-)
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E22), // Fundo escuro modal
        // Arredonda as quinas de cima da gaveta
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            // Usa apenas o espaço necessário, não a tela toda
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Aquela barrinha cinza no topo que mostra que é arrastável (drag handle)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Cabeçalho
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nome da Startup grande
                        Text(
                          widget.startupName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Subtítulo em verde indicando a ação
                        const Text(
                          'COMPRAR DO LIVRO DE ORDENS',
                          style: TextStyle(
                            color: Color(0xFF1A9B5F),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botão de fechar a gaveta "no pelo"
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Título do campo de Stepper
              const Text(
                'Quantidade que deseja comprar',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // O Componente do Stepper gigante com o número no meio
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141416),
                  borderRadius: BorderRadius.circular(14),
                  // Borda com uma sombrazinha verde
                  border: Border.all(
                    color: const Color(0xFF107649).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    // Botãozinho de Menos (-)
                    _buildStepBtn(
                      icon: Icons.remove,
                      onTap: () {
                        if (_qty > 1) { // Só diminui se for maior que 1
                          setState(() {
                            _qty--;
                            // Toda vez que muda, roda a simulação pra atualizar o recibo!
                            _runSimulation(_qty); 
                          });
                        }
                      },
                    ),
                    // Valor central da quantidade que vai comprar
                    Expanded(
                      child: Text(
                        _qty.toInt().toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    // Botãozinho de Mais (+)
                    _buildStepBtn(
                      icon: Icons.add,
                      onTap: () {
                        setState(() {
                          _qty++;
                          // Toda vez que soma, roda a simulação!
                          _runSimulation(_qty); 
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Título do Recibo / Simulação
              const Text(
                'Simulação de Casamento (Menor Preço Primeiro):',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // Se as ofertas ainda não chegaram do banco, mostra bolinha girando
              _loadingOffers
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          color: Color(0xFF1A9B5F),
                        ),
                      ),
                    )
                  // Se chegaram, mostra o recibo rolável (se passar de 120 de altura ele dá scroll)
                  : Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(), // Efeito iOS elástico
                        child: Column(
                          // Mapeia os dados da nossa _simulation e transforma em linhas visuais
                          children: _simulation.map((sim) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Quem está vendendo
                                  Text(
                                    sim['sellerName'],
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  // A conta: qtd x preco = total
                                  Text(
                                    '${sim['quantity'].toInt()} t × R\$ ${sim['price'].toStringAsFixed(2).replaceAll('.', ',')} = R\$ ${sim['total'].toStringAsFixed(2).replaceAll('.', ',')}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

              // Se ele pediu mais tokens do que tem no mercado, dá um aviso amarelo (Alerta).
              if (_insufficientOffers)
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFFF5A623),
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Atenção: Ofertas insuficientes no Balcão. Compra será preenchida parcialmente.',
                          style: TextStyle(
                            color: Color(0xFFF5A623), // Laranja/Amarelado
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),
              // Linha pra separar o recibo do resumo
              const Divider(color: Colors.white10),

              // Resumo final: Quanto vai custar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Estimado:',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    CurrencyInputFormatter.formatValue(_totalCost),
                    style: const TextStyle(
                      color: Color(0xFF1A9B5F), // Valor do boleto em verdinho
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Resumo final: Quanto de dinheiro tem no bolso
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Seu saldo disponível:',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                  Text(
                    CurrencyInputFormatter.formatValue(availableBalance),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Se o total for maior que o saldo, mostra aviso de erro e trava botão
              if (!hasBalance)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFE74C3C), // Vermelho erro
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Saldo disponível insuficiente.',
                        style: TextStyle(
                          color: Color(0xFFE74C3C),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

              // Se a api reclamar de algo durante a compra, o erro pipoca aqui embaixo
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFE74C3C),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFE74C3C),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // O Botão Mestre de Confirmar a Compra
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // Fica verde só se: tem saldo E não está carregando E a quantidade > 0
                    backgroundColor: hasBalance && !_isSubmitting && _qty > 0
                        ? const Color(0xFF107649)
                        : Colors.white12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  // onPressed desativa se passar null
                  onPressed: hasBalance && !_isSubmitting && _qty > 0
                      ? _confirmPurchase
                      : null,
                  // Se estiver carregando, troca o texto por um circulozinho girando
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Confirmar Compra',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construtor pros botões do Stepper (- e +). 
  /// Separei num método pra não repetir 20 linhas de código InkWell na tela principal.
  Widget _buildStepBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 54,
        height: 54,
        alignment: Alignment.center,
        child: Icon(icon, color: const Color(0xFF107649), size: 22),
      ),
    );
  }

  /// Dispara a ação de fato para o firebase processar o multi-match.
  void _confirmPurchase() async {
    // Muda pro estado de "Aguarde..."
    setState(() {
      _isSubmitting = true;
      _errorMessage = null; 
    });

    try {
      // Chama o serviço passando a startup e a quantidade total requerida
      final result = await _service.buyFromOrders(widget.startupId, _qty);
      
      if (result['success'] == true) {
        // Obba, deu certo! Atualiza o saldo local (tira o dinheiro)
        setState(() {
          widget.userModel.saldo =
              widget.userModel.saldo - (result['totalPaid'] as double);
        });
        
        if (mounted) {
          // Fecha o sheet e retorna true pro pai saber que precisa atualizar a tela
          Navigator.pop(context, true);
        }
      } else {
        // Algo deu ruim na logica do balcão, mostra a mensagem na tela
        setState(() {
          _errorMessage =
              result['error'] ?? 'Falha ao processar a compra de ofertas.';
          _isSubmitting = false; // Tira o loader pra ele tentar de novo
        });
      }
    } catch (e) {
      // Erro mais grave (ex: caiu internet)
      setState(() {
        _errorMessage = 'Ocorreu um erro ao processar: $e';
        _isSubmitting = false;
      });
    }
  }
}
