// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

// Tela de compra direta de tokens de uma startup no Balcão.
// Aqui o investidor pode comprar tokens diretamente da startup (mercado primário),
// acompanhar sua posição atual (tokens, preço médio, lucro/perda) e
// visualizar o histórico de ordens executadas para aquela startup.
// Os dados são atualizados em tempo real via StreamBuilder do Firestore.

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesclainvest_f/counter/components/balcao_info_row.dart';
import 'package:mesclainvest_f/counter/components/balcao_buy_form.dart';
import 'package:mesclainvest_f/counter/components/balcao_action_bar.dart';
import 'package:mesclainvest_f/counter/tabs/posicao_tab.dart';
import 'package:mesclainvest_f/counter/tabs/ordens_tab.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/startups/components/startup_colors.dart';
import 'package:mesclainvest_f/startups/services/trade_service.dart';

/// Tela completa de compra de tokens de uma startup específica.
/// Combina formulário de compra, informações financeiras em tempo real
/// e abas internas (Posição e Ordens) num layout integrado.
class BalcaoOrdersScreen extends StatefulWidget {
  // ID da startup cujos tokens serão comprados.
  final String startupId;

  // Nome da startup — exibido no cabeçalho da tela.
  final String startupName;

  // Dados do usuário logado (uid, saldo, nome).
  final UserModel userModel;

  // Modo inicial da tela: 'buy' para compra, poderia ser 'sell' para venda.
  final String initialMode;

  const BalcaoOrdersScreen({
    super.key,
    required this.startupId,
    required this.startupName,
    required this.userModel,
    this.initialMode = 'buy',
  });

  @override
  State<BalcaoOrdersScreen> createState() => _BalcaoOrdersScreenState();
}

/// Estado da tela de compra de tokens.
/// Usa SingleTickerProviderStateMixin para animar o TabController das abas
/// internas (Posição / Ordens).
class _BalcaoOrdersScreenState extends State<BalcaoOrdersScreen>
    with SingleTickerProviderStateMixin {
  // Instância do Firestore para leitura de dados em tempo real. Pense nisso como uma linha direta com o banco.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Serviço que executa a compra de tokens da startup. É o nosso "corretor".
  final TradeService _tradeService = TradeService();

  // Controlador das abas internas (Posição / Ordens). Ele anota qual aba estamos olhando.
  late TabController _tabController;

  // Quantidade de tokens que o usuário quer comprar (começa sempre em 1 para facilitar).
  int _qty = 1;

  // Preço de mercado atual do token em R$. Se for zero, o sistema pode bugar a matemática.
  double _currentMarketPrice = 0.0;

  // Saldo em BRL do usuário. Carregado em tempo real do Firestore para evitar compras sem fundo.
  double _userBrlBalance = 0.0;

  // Quantos tokens o usuário já possui desta startup.
  int _userTokenHolding = 0;

  // Preço médio de aquisição em centavos (usado para não perder precisão no cálculo de lucro/perda).
  int _averagePriceCents = 0;

  // Flag para evitar duplo clique no botão de compra, o famoso "debounce".
  // Se não fizer isso, um usuário ansioso pode comprar 2x sem querer.
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Cria o controller com 2 abas: Posição e Ordens.
    _tabController = TabController(length: 2, vsync: this);
    // Carrega o preço de mercado da startup ao abrir a tela.
    _loadInitialMarketPrice();
  }

  @override
  void dispose() {
    // Libera o controller de abas para evitar memory leak (vazamento de memória).
    // Sempre limpe o que o initState() criar!
    _tabController.dispose();
    super.dispose();
  }

  /// Carrega o preço de mercado atual do token da startup a partir do Firestore.
  /// O preço é armazenado em centavos no campo 'currentTokenPriceCents'.
  Future<void> _loadInitialMarketPrice() async {
    try {
      // Fazemos a chamada assíncrona ao Firestore. É como pedir o preço para o banco e esperar a resposta.
      final doc = await _firestore
          .collection('startups')
          .doc(widget.startupId)
          .get();
      // Sempre cheque se o widget ainda está montado (mounted) antes de chamar setState!
      // Caso contrário, você pode tentar atualizar uma tela que já foi fechada.
      if (doc.exists && mounted) {
        final cents = (doc.data()!['currentTokenPriceCents'] ?? 0) as num;
        // Converte de centavos para reais. Se o preço for 0, usa R$ 1,00 como padrão de segurança.
        setState(() => _currentMarketPrice = cents > 0 ? cents / 100.0 : 1.0);
      }
    } catch (_) {
      // Em caso de erro de rede ou documento inexistente, não faz nada e mantém o preço padrão (0.0).
    }
  }

  /// Helper rápido para formatar os doubles em valores monetários brasileiros (R$ X,XX).
  String _fmtBRL(double v) => CurrencyInputFormatter.formatValue(v);

  /// Getter esperto para calcular o valor total estimado da compra: quantidade × preço de mercado.
  double get _totalEstimated => _qty * _currentMarketPrice;

  /// Calcula o lucro ou perda (P&L) do investidor em Reais.
  /// Só faz o cálculo se o cara já tiverTokens e um preço médio válido.
  double get _profitLoss => _averagePriceCents <= 0 || _userTokenHolding <= 0
      ? 0
      // Diferença entre o preço atual e o preço pago, multiplicada pela quantidade de tokens.
      : _userTokenHolding * (_currentMarketPrice - _averagePriceCents / 100.0);

  /// Calcula o lucro/perda em percentual. Ajuda o usuário a ver se a startup rendeu algo de fato.
  double get _profitPercent => _averagePriceCents <= 0
      ? 0
      // Matemática básica de variação percentual: (Atual - Antigo) / Antigo * 100.
      : ((_currentMarketPrice - (_averagePriceCents / 100.0)) /
                (_averagePriceCents / 100.0)) *
            100;

  @override
  Widget build(BuildContext context) {
    // 1º StreamBuilder: escuta mudanças no saldo BRL do usuário em tempo real.
    // Qualquer centavo que entrar/sair, a tela reage na hora.
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('users')
          .doc(widget.userModel.uid)
          .snapshots(),
      builder: (context, userSnap) {
        double currentBrlBalance = _userBrlBalance;
        if (userSnap.hasData && userSnap.data!.exists) {
          final d = userSnap.data!.data() as Map<String, dynamic>;
          currentBrlBalance = (d['saldo'] as num? ?? 0).toDouble();
        }
        // 2º StreamBuilder (Aninhado): escuta mudanças nos tokens (holdings) do usuário.
        // É como ter 2 ouvidos, um pra carteira de Reais e outro pra de Tokens.
        return StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('holdings')
              .doc('${widget.userModel.uid}_${widget.startupId}')
              .snapshots(),
          builder: (context, holdingSnap) {
            int currentTokenHolding = 0;
            int currentAveragePriceCents = 0;
            if (holdingSnap.hasData && holdingSnap.data!.exists) {
              final d = holdingSnap.data!.data() as Map<String, dynamic>;
              currentTokenHolding = (d['quantity'] as num? ?? 0).toInt();
              currentAveragePriceCents = (d['averagePriceCents'] as num? ?? 0)
                  .toInt();
            }
            // Chama o método principal pra construir a UI, passando as verdades em tempo real.
            return _buildScaffold(
              currentBrlBalance,
              currentTokenHolding,
              currentAveragePriceCents,
            );
          },
        );
      },
    );
  }

  /// Constrói a estrutura principal (Scaffold) da tela com AppBar, corpo da lista
  /// e a barra fixa embaixo pra confirmar a compra.
  Widget _buildScaffold(
    double brlBalance,
    int tokenHolding,
    int avgPriceCents,
  ) {
    // Atualiza as variáveis de estado interno com os dados quentinhos que vieram dos streams.
    _userBrlBalance = brlBalance;
    _userTokenHolding = tokenHolding;
    _averagePriceCents = avgPriceCents;
    final pl = _profitLoss;

    return Scaffold(
      appBar: AppBar(
        // Retira a sombra da AppBar para integrar melhor com o fundo escuro.
        elevation: 0,
        // Ícone de voltar, forçamos a cor branca por causa do tema escuro.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        // Coluna no título permite colocar Nome em cima e "Compra de Tokens" pequenininho embaixo.
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.startupName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Compra de Tokens',
              style: TextStyle(
                color: StartupColors.green,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        // O canto direito exibe o preço atual do token em destaque.
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _fmtBRL(_currentMarketPrice),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Preço atual',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
      // SafeArea protege contra os recortes (notch) de iPhones e telas novas.
      body: SafeArea(
        child: Column(
          children: [
            // Expanded garante que o ListView ocupe todo o espaço livre da tela.
            Expanded(
              child: ListView(
                // BouncingScrollPhysics dá o efeito de elástico bonitinho no final da rolagem (estilo iOS).
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                children: [
                  // Widget separado com os botões + e - para escolher quantos tokens comprar.
                  BalcaoBuyForm(
                    qty: _qty,
                    currentMarketPrice: _currentMarketPrice,
                    onDecrement: () {
                      // Impede a burrice de comprar zero ou tokens negativos.
                      if (_qty > 1) setState(() => _qty--);
                    },
                    onIncrement: () => setState(() => _qty++),
                  ),
                  const SizedBox(height: 24),

                  // Coluna de informações financeiras. Resumo mastigadinho pro usuário.
                  Column(
                    children: [
                      // Mostra quanto BRL ele tem solto na carteira.
                      BalcaoInfoRow(
                        label: 'Saldo disponível',
                        value: _fmtBRL(_userBrlBalance),
                      ),
                      const SizedBox(height: 8),
                      // Mostra o rombo que a compra vai fazer na carteira. Destacado em verde.
                      BalcaoInfoRow(
                        label: 'Valor estimado',
                        value: _fmtBRL(_totalEstimated),
                        highlight: true,
                      ),
                      const SizedBox(height: 8),
                      // Mostra se o cara já é sócio.
                      BalcaoInfoRow(
                        label: 'Seus tokens',
                        value: '$_userTokenHolding tokens',
                      ),
                      // Se o cara já tem posição (preço médio > 0), libera os stats avançados de P&L.
                      if (_averagePriceCents > 0) ...[
                        const SizedBox(height: 8),
                        BalcaoInfoRow(
                          label: 'Preço médio',
                          value: _fmtBRL(_averagePriceCents / 100.0),
                        ),
                        const SizedBox(height: 8),
                        // Monta a linha de Lucro/Perda com a lógica de cores (verde pra lucro, vermelho pra preju).
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Lucro / Perda',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              // Formata bonitinho com o + e - na frente do valor e da porcentagem.
                              '${pl >= 0 ? '+' : ''}${_fmtBRL(pl)} | ${_profitPercent >= 0 ? '+' : ''}${_profitPercent.toStringAsFixed(2)}%',
                              style: TextStyle(
                                // A clássica paleta de trading: verde tá voando, vermelho tá afundando.
                                color: pl >= 0
                                    ? StartupColors.green
                                    : const Color(0xFFE74C3C),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Área de abas embutidas: "Posição" pra ver carteira, "Ordens" pro histórico.
                  Column(
                    children: [
                      // Contêiner da barra das abas (TabBar).
                      Container(
                        height: 40,
                        // Bordinha translúcida pra separar visualmente.
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.06),
                              width: 1,
                            ),
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          // A barrinha que desliza embaixo da aba ativa.
                          indicatorColor: StartupColors.green,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicatorWeight: 2.5,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white,
                          labelStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          dividerColor: Colors.transparent, // Tira a linha padrão feia.
                          tabs: const [
                            Tab(text: 'Posição'),
                            Tab(text: 'Ordens'),
                          ],
                        ),
                      ),
                      // TabBarView cuida de trocar as telas quando a aba muda.
                      // O tamanho é fixo (280) pra não dar bug de altura infinita no ListView.
                      SizedBox(
                        height: 280,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Aba 1: Gráficos ou resumo da Posição atual.
                            PosicaoTab(
                              userTokenHolding: _userTokenHolding,
                              averagePriceCents: _averagePriceCents,
                              currentMarketPrice: _currentMarketPrice,
                              fmtBRL: _fmtBRL,
                            ),
                            // Aba 2: Lista com as últimas ordens do usuário.
                            OrdensTab(
                              startupId: widget.startupId,
                              userId: widget.userModel.uid,
                              fmtBRL: _fmtBRL,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Componente que fica pregado no fundo da tela com o botão "Confirmar Compra".
            BalcaoActionBar(
              isProcessing: _isProcessing,
              qty: _qty,
              totalEstimated: _totalEstimated,
              fmtBRL: _fmtBRL,
              onConfirm: _confirmBuy,
            ),
          ],
        ),
      ),
    );
  }

  /// Método pesado e assíncrono chamado quando o botão é clicado.
  /// Aqui rolam as validações e o envio real da ordem pro servidor/backend.
  Future<void> _confirmBuy() async {
    // 1º Bloqueio: Garante que os dados chegaram da internet.
    if (_qty <= 0 || _currentMarketPrice <= 0) {
      _showSnackBar('Preço de mercado ainda carregando.', isError: true);
      return;
    }

    // 2º Bloqueio: Ninguém compra o que não pode pagar. (Proteção local de saldo).
    final double total = _totalEstimated;
    if (_userBrlBalance < total) {
      _showSnackBar(
        'Saldo insuficiente. Você tem ${_fmtBRL(_userBrlBalance)} e a compra custa ${_fmtBRL(total)}.',
        isError: true,
      );
      return;
    }

    // Passou no bafômetro! Liga o spinner/bloqueia o botão para não dar duplicidade.
    setState(() => _isProcessing = true);
    try {
      // Chama o nosso TradeService, que vai fazer o trabalho sujo e falar com a API.
      // O 'await' segura a execução do código aqui até a API responder.
      await _tradeService.buyFromStartup(
        startupId: widget.startupId,
        quantity: _qty,
      );
      // Se deu bom, mostra a SnackBar de comemoração.
      _showSnackBar('$_qty token(s) comprado(s) com sucesso!');
      // Reseta a quantidade da UI pra 1. É boa prática zerar formulários após o sucesso.
      setState(() => _qty = 1);
    } catch (e) {
      // Deu ruim (Erro de API, etc). Limpa o lixo da Exception e mostra na tela.
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      // Finally sempre roda, dando erro ou não.
      // Desliga a trava do botão e o spinner. O check de `mounted` evita crash caso a tela tenha fechado nesse meio tempo.
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Método simples para popar aquelas caixinhas de aviso (SnackBar) que sobem no rodapé da tela.
  /// Facilita demais o feedback visual.
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Vermelhão se for isError, Senão, verdim da startup.
        backgroundColor: isError
            ? const Color(0xFFE74C3C)
            : StartupColors.green,
        // behavior: floating faz ele ficar desgrudado do fundo, parecendo um card de notificação.
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
