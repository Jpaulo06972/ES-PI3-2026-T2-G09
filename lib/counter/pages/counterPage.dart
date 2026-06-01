// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

// Importações necessárias para a página principal do Balcão de Negociação.
// Timer é usado para dar um refresh periódico no livro de ofertas (o "book").
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesclainvest_f/components/navBar.dart';
import 'package:mesclainvest_f/counter/components/counterToggle.dart';
import 'package:mesclainvest_f/counter/components/buy_bottom_sheet.dart';
import 'package:mesclainvest_f/counter/services/counterService.dart';
import 'package:mesclainvest_f/counter/pages/balcao_orders_screen.dart';
import 'package:mesclainvest_f/counter/tabs/buy_tab.dart';
import 'package:mesclainvest_f/counter/tabs/sell_tab.dart';
import 'package:mesclainvest_f/counter/tabs/my_orders_tab.dart';
import 'package:mesclainvest_f/model/offerModel.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/startups/services/getStartup.dart';

/// Página principal do Balcão de Negociação.
/// É o coração do mercado secundário. Funciona como uma mesa de operações
/// onde o investidor vê ofertas, cria as suas e monitora o book.
/// Organizada por abas: Comprar, Vender e Minhas Ordens.
class CounterPage extends StatefulWidget {
  // Recebemos o usuário inteiro para não ter que fazer queries de Auth de novo.
  final UserModel user;
  const CounterPage({super.key, required this.user});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  // Controla qual aba tá ativa. 0 = Comprar, 1 = Vender, 2 = Minhas Ordens.
  int _tabIndex = 0; 

  // Instanciamos o serviço do Balcão que abstrai a comunicação pesada com API/Firestore.
  final CounterService _service = CounterService();

  // ── Estado Assíncrono do Balcão ─────────────────────────────────────────

  // As startups cadastradas para popular o dropdown "Comprar".
  List<Map<String, String>> _startupsList = [];

  // Startups nas quais o usuário TEM tokens (pois não dá pra vender vento, certo?).
  List<Map<String, String>> _sellStartups = [];

  // Saldo de tokens do cara na startup selecionada pra vender.
  double _userTokensBalance = 0.0;

  // Esse Timer é como um frentista que atualiza o preço da gasolina.
  // Fica rodando em loop pra baixar novas ofertas a cada 10s.
  Timer? _offerRefreshTimer;

  // ── Estado da Aba "Comprar" ─────────────────────────────────────────────
  
  // ID e Nome da startup escolhida no combobox de Comprar.
  String? _buyStartupId;
  String? _buyStartupNome;

  // Book de ofertas: quem tá vendendo (o que queremos comprar) e quem tá comprando.
  List<OfferModel> _buyVendaOffers = [];
  List<OfferModel> _buyCompraOffers = [];

  // ── Estado da Aba "Vender" ──────────────────────────────────────────────
  
  // ID e Nome da startup escolhida no combobox de Vender.
  String? _sellStartupId;
  String? _sellStartupNome;

  // Book de ofertas da aba Vender.
  List<OfferModel> _sellVendaOffers = [];
  List<OfferModel> _sellCompraOffers = [];

  @override
  void initState() {
    super.initState();
    // Ao abrir a página, buscamos as startups pra não deixar os dropdowns vazios.
    _loadStartups();
    // E já engatamos o timer de pooling de ofertas.
    _startRefreshTimer();
  }

  @override
  void dispose() {
    // MUITO IMPORTANTE: Cancelar o timer. Se o usuário sair dessa tela e o timer
    // continuar batendo no banco a cada 10s, o app gasta banda, bateria e Firestore atoa.
    _offerRefreshTimer?.cancel();
    super.dispose();
  }

  /// Configura o timer que atualiza o book de ofertas a cada 10 segundos.
  /// Um Web Socket seria o ideal, mas um polling de 10s resolve bem pra MVPs.
  void _startRefreshTimer() {
    _offerRefreshTimer?.cancel();
    _offerRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      // Faz o refresh inteligente: só atualiza a lista da aba que o usuário tá olhando.
      if (_tabIndex == 0) _refreshBuyBook();
      if (_tabIndex == 1) _refreshSellBook();
    });
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Carrega todas as startups do sistema para encher o dropdown de Compras.
  Future<void> _loadStartups() async {
    try {
      final list = await StartupService().listStartups();
      if (mounted) {
        setState(() {
          // Extraímos só id e nome, formatando num mapa bonitinho pro Dropdown usar.
          _startupsList = list
              .map(
                (s) => {
                  'id': (s['id'] ?? '').toString(),
                  'nome': (s['name'] ?? '').toString(),
                },
              )
              .toList();
        });
      }
    } catch (e) {
      // Fallback pra hardcode. Em dev/test, se a rede cai, a tela pelo menos carrega algo.
      if (mounted) {
        setState(() {
          _startupsList = CounterService.allStartups;
        });
      }
    }
  }

  /// Carrega as startups onde o usuário tem saldo de tokens.
  /// Usado na aba Vender, pra não frustrar o usuário tentando vender o que não tem.
  void _loadSellStartups() async {
    final list = await _service.getStartupsWithUserTokens();
    if (mounted) {
      setState(() {
        _sellStartups = list;
      });
    }
  }

  /// Disparado quando o usuário escolhe uma startup no dropdown da aba Comprar.
  void _onBuyStartupSelected(String id, String nome) {
    setState(() {
      _buyStartupId = id;
      _buyStartupNome = nome;
    });
    // Atualiza o book imediatamente, sem esperar o timer de 10s.
    _refreshBuyBook();
  }

  /// Disparado quando o usuário escolhe uma startup no dropdown da aba Vender.
  void _onSellStartupSelected(String id, String nome) async {
    setState(() {
      _sellStartupId = id;
      _sellStartupNome = nome;
    });

    // Como é venda, precisamos buscar quantos tokens o cara tem na carteira.
    final tokens = await _service.getUserTokens(id);
    if (mounted) {
      setState(() {
        _userTokensBalance = tokens;
      });
    }
    // Atualiza o book imediatamente.
    _refreshSellBook();
  }

  /// Acessa o Firestore pra puxar todas as ofertas abertas de uma startup.
  /// Esse é o núcleo do nosso "Order Book" manual.
  Future<List<OfferModel>> _fetchOffersFromFirestore(String startupId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('balcaoOffers')
          .where('startupId', isEqualTo: startupId)
          .get();
      return snap.docs
          .map((doc) {
            final data = doc.data();
            // Ignora silenciosamente o que não tá 'open' (já foi vendido ou cancelado).
            if (data['status'] != 'open') return null;

            // Tratamento defensivo: prioriza remainingQuantity (caso rolou compra parcial).
            final qty =
                ((data['remainingQuantity'] ?? data['quantity']) as num?)
                    ?.toDouble() ??
                0;
            // Se zerou, já não faz sentido listar no book.
            if (qty <= 0) return null;

            // Retorna a nossa OfferModel já traduzida.
            return OfferModel(
              id: doc.id,
              startupId: data['startupId'] ?? '',
              startupNome: data['startupNome'] ?? '',
              vendedorId: data['userId'] ?? '',
              // Placeholder caso o nome do vendedor esteja vazio.
              vendedorNome:
                  (data['userName'] as String?)?.trim().isNotEmpty == true
                  ? data['userName'] as String
                  : 'Investidor',
              quantidade: qty,
              precoPorToken: (data['pricePerToken'] as num?)?.toDouble() ?? 0,
              tipo: data['type'] == 'buy' ? OrderType.compra : OrderType.venda,
              status: OrderStatus.aberta,
              criadoEm: data['createdAt'] is Timestamp
                  ? (data['createdAt'] as Timestamp).toDate()
                  : DateTime.now(),
            );
          })
          // O whereType<OfferModel>() remove os nulos da lista. Bem prático!
          .whereType<OfferModel>()
          .toList();
    } catch (_) {
      // Tratamento genérico em caso de falha de conexão.
      return [];
    }
  }

  /// Limpa e reconstrói o Book da aba Comprar.
  void _refreshBuyBook() async {
    if (_buyStartupId == null) return;
    // Puxa tudo.
    final all = await _fetchOffersFromFirestore(_buyStartupId!);
    if (mounted) {
      setState(() {
        // Ofertas de venda = o que queremos comprar.
        // A regra de mercado é clara: mais barato no topo. Então ordenamos A pro B.
        _buyVendaOffers = all.where((o) => o.tipo == OrderType.venda).toList()
          ..sort((a, b) => a.precoPorToken.compareTo(b.precoPorToken));
        // Ofertas de compra (referência visual pra ver quem quer comprar mais caro).
        _buyCompraOffers = all.where((o) => o.tipo == OrderType.compra).toList()
          ..sort((a, b) => b.precoPorToken.compareTo(a.precoPorToken));
      });
    }
  }

  /// Limpa e reconstrói o Book da aba Vender.
  void _refreshSellBook() async {
    if (_sellStartupId == null) return;
    final all = await _fetchOffersFromFirestore(_sellStartupId!);
    if (mounted) {
      setState(() {
        // Aqui a regra vira: ordenamos Vendas de cima pra baixo (mais caro pro mais barato).
        _sellVendaOffers = all.where((o) => o.tipo == OrderType.venda).toList()
          ..sort((a, b) => b.precoPorToken.compareTo(a.precoPorToken));
        _sellCompraOffers =
            all.where((o) => o.tipo == OrderType.compra).toList()
              ..sort((a, b) => b.precoPorToken.compareTo(a.precoPorToken));
      });
    }
  }

  /// Publica a oferta recém-criada pelo usuário no Firestore.
  Future<bool> _publishSellOffer(OfferModel offer) async {
    // Preenche com os dados faltantes do usuário que tá mexendo no app.
    final completeOffer = OfferModel(
      id: offer.id,
      startupId: offer.startupId,
      startupNome: offer.startupNome,
      vendedorId: widget.user.uid,
      vendedorNome: widget.user.firstName,
      quantidade: offer.quantidade,
      precoPorToken: offer.precoPorToken,
      tipo: offer.tipo,
      criadoEm: offer.criadoEm,
    );

    // Manda bala pro service salvar.
    final success = await _service.addOffer(completeOffer);

    if (success) {
      // Se sucesso, puxa o book atualizado pra oferta dele já brilhar na tela.
      _refreshSellBook();
      _showSnackBar(
        'Oferta de ${offer.quantidade.toInt()} tokens publicada na tabela!',
      );
    } else {
      _showSnackBar('Erro ao publicar oferta de venda.', isError: true);
    }
    return success;
  }

  // ── Build Principal ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // O letreiro lá de cima com o texto "Balcão".
            _buildHeader(),
            // O Toggle bonitão de Comprar/Vender/Minhas Ordens.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: CounterToggle(
                selectedIndex: _tabIndex,
                onChanged: (i) {
                  setState(() => _tabIndex = i);
                  // Lógica de "Lazy Loading": se foi pra aba vender (1), busca o saldo e as startups disponíveis pra venda.
                  if (i == 1) {
                    _loadSellStartups();
                  }
                },
                tabs: const ['Comprar', 'Vender', 'Minhas Ordens'],
              ),
            ),
            // O conteúdo ocupa todo o resto da tela (Expanded).
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
      // Nosso rodapé clássico de navegação. "Balcão" é o índice 2.
      bottomNavigationBar: CustomNavBar(
        userModel: widget.user,
        currentIndex: 2, 
      ),
    );
  }

  /// Simples e direto, só o título mesmo.
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Balcão',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "Roteador interno" da página. Decide qual widget injetar dependendo do _tabIndex.
  Widget _buildTabContent() {
    switch (_tabIndex) {
      case 0:
        // Tab de COMPRA
        return BuyTab(
          // Se falhou o firebase, manda a lista marretada.
          startups: _startupsList.isEmpty
              ? CounterService.allStartups
              : _startupsList,
          selectedStartupId: _buyStartupId,
          selectedStartupNome: _buyStartupNome,
          vendaOffers: _buyVendaOffers,
          compraOffers: _buyCompraOffers,
          onStartupSelected: _onBuyStartupSelected,
          // Função disparada ao clicar numa linha da tabela: Sobe a folha de pagamento (BottomSheet).
          onOfferTap: (offer) => showBuySheet(
            context,
            offer,
            widget.user,
            _service,
            _refreshBuyBook, // Passa a função de recarregar como callback.
          ),
          // Botão coringa "Comprar direto da startup" (quando o mercado tá vazio).
          onBuyFromStartup: (startupId, startupNome) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BalcaoOrdersScreen(
                  startupId: startupId,
                  startupName: startupNome,
                  userModel: widget.user,
                  initialMode: 'buy',
                ),
              ),
            ).then((_) => _refreshBuyBook()); // E recarrega o book quando volta da tela.
          },
        );
      case 1:
        // Tab de VENDA
        return SellTab(
          startups: _sellStartups,
          userTokensBalance: _userTokensBalance,
          selectedStartupId: _sellStartupId,
          selectedStartupNome: _sellStartupNome,
          vendaOffers: _sellVendaOffers,
          compraOffers: _sellCompraOffers,
          onStartupSelected: _onSellStartupSelected,
          onPublish: _publishSellOffer,
        );
      case 2:
        // Tab de HISTÓRICO DAS ORDENS PESSOAIS
        return MyOrdersTab(userId: widget.user.uid);
      default:
        // Fallback defensivo que nunca deve ser atingido.
        return const SizedBox();
    }
  }

  /// Caixa de notificação pro usuário no padrão verde(sucesso)/vermelho(erro).
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Cor do painel varia baseado se o parâmetro error veio true
        backgroundColor: isError
            ? const Color(0xFFE74C3C) // Tomatão vermelho.
            : const Color(0xFF107649), // Verde grana.
        behavior: SnackBarBehavior.floating, // Descola do rodapé (iOS style).
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3), // Apaga sozinho.
      ),
    );
  }
}
