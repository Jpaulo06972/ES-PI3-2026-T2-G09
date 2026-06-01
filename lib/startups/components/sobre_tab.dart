// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

import 'package:mesclainvest_f/components/currencyInputFormatter.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'startup_colors.dart';
import 'inline_video_player.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/counter/pages/balcao_orders_screen.dart';

/// [SobreTab] é o coração da tela de detalhes de uma startup.
/// É aqui que o investidor olha as métricas (preço, tokens, captado), lê o pitch,
/// assiste ao vídeo e decide se vai colocar dinheiro na mesa.
/// 
/// Por que ser reativo (Streams)?
/// O preço do token e a quantidade disponível mudam o tempo todo (lei da oferta e demanda).
/// Se a gente carregar só uma vez (Future), o cara pode tentar comprar achando que tem 
/// tokens a R$10 e tomar erro no servidor porque já subiu pra R$12.
/// Por isso, ouvimos o Firestore em tempo real (Streams) para a tela "piscar" com os dados novos.
class SobreTab extends StatefulWidget {
  final Map<String, dynamic> data; // Dados iniciais estáticos passados pela lista
  final UserModel userModel;
  final VoidCallback? onRefresh;

  const SobreTab({
    super.key,
    required this.data,
    required this.userModel,
    this.onRefresh,
  });

  @override
  State<SobreTab> createState() => _SobreTabState();
}

class _SobreTabState extends State<SobreTab> {
  // Quantos tokens o usuário logado tem dessa startup na carteira dele
  double _userHoldings = 0.0;
  
  // Flag do loading inicial da carteira do usuário
  bool _loadingHoldings = true;

  // Variáveis "Live" (ao vivo). Elas começam nulas e vão sendo preenchidas
  // conforme as atualizações do Firebase chegam. Quando têm valor, 
  // elas "matam" os dados estáticos do widget.data.
  int? _liveAvailableTokens;
  int? _liveTokensSold;
  int? _liveTokenPriceCents;
  
  // Inscrições (Subscriptions) da rádio Firebase.
  // Precisamos guardar essas variáveis para poder "desligar o rádio" 
  // quando o usuário sair da tela.
  StreamSubscription<DocumentSnapshot>? _startupSub;
  StreamSubscription<DocumentSnapshot>? _holdingsSub;

  @override
  void initState() {
    super.initState();
    // Liga o rádio na estação da Startup e na estação da Carteira
    _subscribeToStartup();
    _subscribeToHoldings();
  }

  // O didUpdateWidget é chamado quando o Flutter recicla essa aba
  // mas muda os dados que estão chegando nela (ex: o usuário clicou em outra startup rápido demais).
  // Se não cancelarmos o rádio antigo, o app fica ouvindo a startup antiga e a nova 
  // ao mesmo tempo (consumindo banda e misturando os dados).
  @override
  void didUpdateWidget(covariant SobreTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data['id'] != widget.data['id']) {
      _subscribeToStartup();
      _subscribeToHoldings();
    }
  }

  // Sintoniza no documento da startup no Firestore e atualiza a tela a cada mudança
  void _subscribeToStartup() {
    _startupSub?.cancel(); // Manda calar a boca da inscrição velha, se houver
    final id = (widget.data['id'] ?? '').toString();
    if (id.isEmpty) return;
    
    // `.snapshots().listen` é a mágica em tempo real do Firebase.
    _startupSub = FirebaseFirestore.instance
        .collection('startups')
        .doc(id)
        .snapshots()
        .listen((snap) {
      if (!snap.exists || !mounted) return;
      
      final d = snap.data() as Map<String, dynamic>;
      setState(() {
        // Atualiza a vitrine da loja
        _liveAvailableTokens = (d['availableTokens'] as num?)?.toInt();
        _liveTokensSold      = (d['tokensSold'] as num?)?.toInt();
        _liveTokenPriceCents = (d['currentTokenPriceCents'] as num?)?.toInt();
      });
    });
  }

  // Sintoniza no "recibo" que diz quantos tokens esse usuário tem dessa startup
  void _subscribeToHoldings() {
    _holdingsSub?.cancel();
    final startupId = (widget.data['id'] ?? '').toString();
    if (startupId.isEmpty) return;
    
    // O ID composto no banco: "userId_startupId"
    _holdingsSub = FirebaseFirestore.instance
        .collection('holdings')
        .doc('${widget.userModel.uid}_$startupId')
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      
      final d = snap.exists ? snap.data() : null;
      final qty = (d?['quantity'] as num?)?.toDouble() ?? 0.0;
      
      setState(() {
        _userHoldings = qty;
        _loadingHoldings = false; // Tira o spinner de carregamento da carteira
      });
    });
  }

  @override
  void dispose() {
    // Desliga a rádio e para de pagar tráfego do Firebase
    _startupSub?.cancel();
    _holdingsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Montagem do Frankstein de dados:
    // Se a variável "ao vivo" existir, usa ela. Senão, faz fallback pro dado estático que veio da lista.
    final startupId = (widget.data['id'] ?? '').toString();
    final startupName = (widget.data['name'] ?? 'Startup').toString();
    final rawTokens = widget.data['totalTokensIssued'] ?? widget.data['tokens'] ?? 0;
    final rawCapital = widget.data['capitalRaisedCents'] ?? widget.data['capital'] ?? 0;
    
    final rawTokenPrice = _liveTokenPriceCents ?? widget.data['currentTokenPriceCents'] ?? 0;

    final int totalTokens = int.tryParse(rawTokens.toString()) ?? 0;
    final int tokensSold = _liveTokensSold
        ?? int.tryParse((widget.data['tokensSold'] ?? 0).toString())
        ?? 0;
        
    final availableTokens = _liveAvailableTokens
        ?? widget.data['availableTokens']
        ?? widget.data['available']
        ?? (totalTokens - tokensSold);
        
    final description = (widget.data['description'] ?? widget.data['descricao'] ?? '').toString().trim();
        
    // Limpeza ninja do array de vídeos: garante que é lista, converte tudo pra string e joga fora os vazios.
    final demoVideos = (widget.data['demoVideos'] as List<dynamic>? ?? [])
        .map((e) => e.toString().trim())
        .where((url) => url.isNotEmpty)
        .toList();

    return ListView(
      physics: const BouncingScrollPhysics(), // Scroll suave estilo iOS
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        // Cartões executivos de estatística lá no topo (Dashboard)
        Row(
          children: [
            Expanded(child: _StatCard(value: _formatTokenPrice(rawTokenPrice), label: 'Preço\ntoken')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(value: _formatTokens(rawTokens), label: 'Tokens\nemitidos')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(value: _formatCapital(rawCapital), label: 'Captado')),
          ],
        ),
        const SizedBox(height: 24),

        // Widget de trade que muda de cor dependendo se a startup já vendeu tudo ou não
        _buildTradingWidget(startupId, startupName, rawTokenPrice, availableTokens),

        const SizedBox(height: 24),
        
        // Seção do Pitch
        const _SectionTitle('SUMÁRIO EXECUTIVO'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: StartupColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Text(
            description.isNotEmpty ? description : '--',
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
          ),
        ),
        const SizedBox(height: 28),
        
        // Seção de vídeos no YouTube
        const _SectionTitle('VÍDEO DEMO'),
        const SizedBox(height: 12),
        _DemoVideosSection(demoVideos: demoVideos),
        const SizedBox(height: 32),
      ],
    );
  }

  /// Pedaço de UI condicional para o bloco de Compra/Venda.
  /// Se tiver token na oferta primária, fica verde. Se esgotou, fica vermelho e avisa
  /// que só dá pra negociar no balcão secundário.
  Widget _buildTradingWidget(
    String startupId,
    String startupName,
    dynamic rawTokenPrice,
    dynamic availableTokensVal,
  ) {
    final int available = int.tryParse(availableTokensVal.toString()) ?? 0;
    // O backend guarda dinheiro em centavos (integer) pra evitar aquele bug de precisão de ponto flutuante do Javascript/Dart
    // (aquele que 0.1 + 0.2 vira 0.300000004). Então a gente divide por 100 na hora de mostrar na tela.
    final double pricePerToken = (num.tryParse(rawTokenPrice.toString()) ?? 0) / 100;

    final bool hasTokensAvailable = available > 0;

    if (hasTokensAvailable) {
      // ESTADO A: A Startup ainda está captando grana.
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: StartupColors.cardBg,
          borderRadius: BorderRadius.circular(22),
          // Borda verdinha pra encorajar o clique
          border: Border.all(color: const Color(0xFF1A9B5F).withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tokens disponíveis',
              style: TextStyle(
                color: Color(0xFF1A9B5F),
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Preço atual:', style: TextStyle(color: Colors.white54, fontSize: 13)),
                Text(
                  CurrencyInputFormatter.formatValue(pricePerToken),
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tokens disponíveis:', style: TextStyle(color: Colors.white54, fontSize: 13)),
                Text(
                  NumberFormat('#,##0', 'pt_BR').format(available),
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Seus tokens:', style: TextStyle(color: Colors.white54, fontSize: 13)),
                // Se a stream ainda não pegou a quantidade na carteira, mostra um loader microscópico
                _loadingHoldings
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: StartupColors.green),
                      )
                    : Text(
                        NumberFormat('#,##0', 'pt_BR').format(_userHoldings.toInt()),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ],
            ),
            const SizedBox(height: 18),
            // Call to Action
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF107649),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () => _openTradeScreen(startupId, startupName, 'buy'),
                child: const Text('Negociar', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    } else {
      // ESTADO B: A Startup não está mais emitindo. Tudo esgotado.
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: StartupColors.cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tokens esgotados pela startup',
              style: TextStyle(
                color: Color(0xFFE74C3C), // O vermelho dá a dica de que acabou
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Preço atual:', style: TextStyle(color: Colors.white54, fontSize: 13)),
                Text(
                  CurrencyInputFormatter.formatValue(pricePerToken),
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Seus tokens:', style: TextStyle(color: Colors.white54, fontSize: 13)),
                _loadingHoldings
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: StartupColors.green),
                      )
                    : Text(
                        NumberFormat('#,##0', 'pt_BR').format(_userHoldings.toInt()),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Não há tokens disponíveis para compra direta nesta startup.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      );
    }
  }

  /// Empurra a tela do balcão de negociações (P2P).
  void _openTradeScreen(String startupId, String startupName, String mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BalcaoOrdersScreen(
          startupId: startupId,
          startupName: startupName,
          userModel: widget.userModel,
          initialMode: mode,
        ),
      ),
    ).then((_) {
      // Quando o cara volta do balcão (clicou no botão de voltar), recarregamos a tela inteira,
      // pra garantir que o saldo reflete o que acabou de ser feito lá.
      if (widget.onRefresh != null) widget.onRefresh!();
    });
  }

  /// Formatação padrão de inteiros (1234 -> 1.234)
  String _formatTokens(dynamic value) {
    final num v = num.tryParse(value.toString()) ?? 0;
    if (v == 0) return '--';
    return NumberFormat('#,##0', 'pt_BR').format(v);
  }

  /// Função genial pra economizar espaço de tela (Real Estate).
  /// Se a startup captou 1 milhão, o número cru seria "R$ 1.000.000,00".
  /// Isso quebra o layout todinho no celular de tela pequena.
  /// Então a gente transforma em "R$1.0M". Bem mais limpo.
  String _formatCapital(dynamic value) {
    final num v = num.tryParse(value.toString()) ?? 0;
    if (v == 0) return '--';
    final double reais = v / 100;
    if (reais >= 1000000) return 'R\$${(reais / 1000000).toStringAsFixed(1)}M';
    if (reais >= 1000) return 'R\$${(reais / 1000).toStringAsFixed(0)}k';
    return 'R\$${reais.toStringAsFixed(0)}';
  }

  /// Converte centavos do banco pra moeda na tela
  String _formatTokenPrice(dynamic value) {
    final num v = num.tryParse(value.toString()) ?? 0;
    if (v == 0) return '--';
    return 'R\$${(v / 100).toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

/// [_StatCard] é o widget burrinho (Stateless) que só recebe dado e pinta o card cinza.
class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: StartupColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.3),
          ),
        ],
      ),
    );
  }
}

/// Títulozinho verde espaçado, padrão visual da nossa marca.
class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: StartupColors.green,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5, // Deixa as letras separadinhas, bem premium
      ),
    );
  }
}

/// O laço que renderiza a lista de vídeos de demonstração da Startup.
class _DemoVideosSection extends StatelessWidget {
  final List<String> demoVideos;

  const _DemoVideosSection({required this.demoVideos});

  @override
  Widget build(BuildContext context) {
    // Se a startup tá sendo preguiçosa e não colocou vídeo, a gente joga um placeholder
    // pra não ficar um buraco esquisito no meio da tela.
    if (demoVideos.isEmpty) {
      return Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: StartupColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off_rounded, color: Colors.white24, size: 36),
              SizedBox(height: 8),
              Text('Nenhum vídeo disponível', style: TextStyle(color: Colors.white38, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return Column(
      // List.generate é o map() da árvore de widgets
      children: List.generate(demoVideos.length, (i) {
        return Padding(
          // Só bota espaçamento se não for o último vídeo
          padding: EdgeInsets.only(bottom: i < demoVideos.length - 1 ? 16 : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Se tiver mais de um vídeo, numera pra organizar ("Vídeo Demo 1", etc)
              if (demoVideos.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Vídeo Demo ${i + 1}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              // Passa a URL pro nosso mega player importado
              InlineVideoPlayer(videoUrl: demoVideos[i]),
            ],
          ),
        );
      }),
    );
  }
}
