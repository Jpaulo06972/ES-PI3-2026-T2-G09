// Feito por: Tomás Toniato RA: 25004211

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
// Barra de navegação inferior compartilhada entre as telas
import 'package:mesclainvest_f/components/navBar.dart';
import 'package:mesclainvest_f/enum/userRole.dart';
import 'package:mesclainvest_f/model/userModel.dart';
// Serviço que busca detalhes da startup e eventos no Firebase
import 'package:mesclainvest_f/startups/services/getStartup.dart';

// Tela de detalhes de uma startup, exibida ao clicar em um card na lista.
// Recebe o ID, nome, estágio e dados do usuário logado como parâmetros.
class StartupsDetails extends StatefulWidget {
  final String startupId;
  final String startupName;
  final String startupStage;
  final UserModel userModel;
  // Caminho da imagem no Firebase Storage (ex: startups_images/agrisense.png)
  final String? storagePath;

  const StartupsDetails({
    super.key,
    required this.startupId,
    required this.startupName,
    required this.startupStage,
    required this.userModel,
    this.storagePath,
  });

  @override
  State<StartupsDetails> createState() => _StartupsDetailsState();
}

// State com SingleTickerProviderStateMixin para controlar as animações do TabBar
class _StartupsDetailsState extends State<StartupsDetails>
    with SingleTickerProviderStateMixin {
  // Controla qual aba está ativa (Sobre / Sócios / Q&A / Eventos)
  late TabController _tabController;

  final StartupService _service = StartupService();

  // Future que carrega os detalhes completos da startup (Sobre e Sócios)
  late Future<Map<String, dynamic>> _detailsFuture;

  // Future separado para os eventos, que vêm da coleção event_startups no Firestore
  late Future<List<Map<String, dynamic>>> _eventosFuture;

  // Controla o texto digitado na caixa de perguntas (aba Q&A)
  final TextEditingController _questionController = TextEditingController();

  // Define se a pergunta a ser enviada é privada (true) ou pública (false)
  bool _isPrivate = false;

  // Lista de perguntas enviadas localmente na sessão atual (sem backend ainda)
  final List<Map<String, dynamic>> _localQuestions = [];

  // Paleta de cores fixas usada em toda a tela
  static const _green = Color(0xFF1A9B5F);
  static const _cardBg = Color(0xFF262629);
  static const _pageBg = Color(0xFF1A1A1E);

  // Cores usadas na barra e legenda de participação societária (aba Sócios)
  static const _chartColors = [
    Color(0xFF1A9B5F),
    Color(0xFF4A90E2),
    Color(0xFFF5A623),
    Color(0xFFE74C3C),
    Color(0xFF9B59B6),
    Color(0xFF1ABC9C),
    Color(0xFFE67E22),
  ];

  @override
  void initState() {
    super.initState();
    // 4 abas: Sobre, Sócios, Q&A, Eventos
    _tabController = TabController(length: 4, vsync: this);
    // Inicia o carregamento dos detalhes da startup assim que a tela abre
    _detailsFuture = _service.getStartupDetails(widget.startupId);
    // Busca os eventos filtrando pelo nome da startup na coleção event_startups
    _eventosFuture = _service.listEventos(widget.startupName);
    // Carrega a URL da imagem de capa do Firebase Storage
    _loadCoverImage();
  }

  // URL da imagem de capa carregada do Firebase Storage
  String? _coverImageUrl;

  // Busca a download URL da imagem de capa no Storage
  Future<void> _loadCoverImage() async {
    if (widget.storagePath == null || widget.storagePath!.isEmpty) return;
    try {
      final ref = FirebaseStorage.instance.ref(widget.storagePath!);
      final url = await ref.getDownloadURL();
      if (mounted) {
        setState(() => _coverImageUrl = url);
      }
    } catch (e) {
      debugPrint('Erro ao carregar imagem de capa: $e');
    }
  }

  @override
  void dispose() {
    // Libera os controllers para evitar vazamento de memória
    _tabController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      // Navbar inferior com a aba Startups marcada como ativa (índice 1)
      bottomNavigationBar: CustomNavBar(
        userModel: widget.userModel,
        currentIndex: 1,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho com nome da startup, estágio e botão de voltar
            _buildHeader(),
            // Barra de abas: Sobre | Sócios | Q&A | Eventos
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Aba Sobre: carrega detalhes via Firebase Functions
                  FutureBuilder<Map<String, dynamic>>(
                    future: _detailsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: _green),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'Erro ao carregar:\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }
                      return _buildSobreTab(snapshot.data ?? {});
                    },
                  ),

                  // Aba Sócios: reutiliza o mesmo future de detalhes
                  FutureBuilder<Map<String, dynamic>>(
                    future: _detailsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: _green),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'Erro ao carregar:\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }
                      return _buildSociosTab(snapshot.data ?? {});
                    },
                  ),

                  // Aba Q&A: reutiliza o mesmo future e adiciona o campo de envio
                  FutureBuilder<Map<String, dynamic>>(
                    future: _detailsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: _green),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'Erro ao carregar:\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }
                      return _buildQATab(snapshot.data ?? {});
                    },
                  ),

                  // Aba Eventos: usa future próprio que busca na coleção event_startups
                  _buildEventosTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cabeçalho com imagem de capa da startup + overlay escuro + nome e badges
  Widget _buildHeader() {
    return Container(
      height: 200,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camada 1: imagem de fundo ou gradiente fallback
          if (_coverImageUrl != null)
            Image.network(
              _coverImageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0D5C38), Color(0xFF1A1A1E)],
                  ),
                ),
              ),
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D5C38), Color(0xFF1A1A1E)],
                ),
              ),
            ),

          // Camada 2: overlay cinza claro para legibilidade sem esconder a imagem
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.5, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),

          // Camada 3: conteúdo (botão voltar, nome, badges)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botão voltar — pill branca translúcida
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _cardBg.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Catálogo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Nome e badges na parte inferior
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome da startup
                    Text(
                      widget.startupName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 12,
                          ),
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Badges com fundo sólido para contraste
                    Row(
                      children: [
                        // Badge do estágio — fundo verde sólido
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _green,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _green.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            _stageLabel(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Badge do papel — fundo escuro translúcido
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _cardBg.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            _roleLabel(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TabBar customizada com fundo arredondado e indicador de aba ativa
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        // Fundo escuro na aba selecionada
        indicator: BoxDecoration(
          color: _pageBg,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Sobre'),
          Tab(text: 'Sócios'),
          Tab(text: 'Q&A'),
          Tab(text: 'Eventos'),
        ],
      ),
    );
  }

  // Aba Sobre: estatísticas (tokens, capital, preço) + descrição + vídeos demo
  Widget _buildSobreTab(Map<String, dynamic> data) {
    final rawTokens = data['totalTokensIssued'] ?? data['tokens'] ?? 0;
    final rawCapital = data['capitalRaisedCents'] ?? data['capital'] ?? 0;
    final rawTokenPrice = data['currentTokenPriceCents'] ?? 0;
    final description =
        (data['description'] ?? data['descricao'] ?? '').toString().trim();

    // Extrai a lista de URLs de vídeos demo da startup
    final rawDemoVideos = data['demoVideos'] as List<dynamic>? ?? [];
    final demoVideos = rawDemoVideos
        .map((e) => e.toString().trim())
        .where((url) => url.isNotEmpty)
        .toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        // Linha de 3 cards com as métricas principais da startup
        Row(
          children: [
            // Preço do token calculado a partir de currentTokenPriceCents
            Expanded(
              child: _statCard(
                _formatTokenPrice(rawTokenPrice),
                'Preço\ntoken',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(_formatTokens(rawTokens), 'Tokens\nemitidos'),
            ),
            const SizedBox(width: 12),
            Expanded(child: _statCard(_formatCapital(rawCapital), 'Captado')),
          ],
        ),

        const SizedBox(height: 28),

        _sectionTitle('SUMÁRIO EXECUTIVO'),
        const SizedBox(height: 12),
        // Card com a descrição completa da startup
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Text(
            description.isNotEmpty ? description : '--',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),

        const SizedBox(height: 28),

        _sectionTitle('VÍDEO DEMO'),
        const SizedBox(height: 12),
        // Exibe os vídeos demo da startup ou estado vazio
        _buildDemoVideosSection(demoVideos),

        const SizedBox(height: 32),
      ],
    );
  }

  // Aba Sócios: Exibe um gráfico de barras proporcional e cards individuais de cada fundador
  Widget _buildSociosTab(Map<String, dynamic> data) {
    // Extrai a lista de sócios (founders) retornada pela Cloud Function
    final rawFounders = data['founders'] as List<dynamic>? ?? [];
    final founders = rawFounders
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    // Caso não haja sócios cadastrados, exibe uma mensagem centralizada
    if (founders.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum sócio cadastrado.',
          style: TextStyle(color: Colors.white38, fontSize: 15),
        ),
      );
    }

    // Lista com scroll para exibir toda a composição societária
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        _sectionTitle('COMPOSIÇÃO SOCIETÁRIA'),
        const SizedBox(height: 16),
        // Renderiza a barra horizontal colorida com as porcentagens
        _buildEquityBar(founders),
        const SizedBox(height: 8),
        // Legenda explicativa com nomes e porcentagens individuais
        _buildEquityLegend(founders),
        const SizedBox(height: 28),
        _sectionTitle('SÓCIOS E FUNDADORES'),
        const SizedBox(height: 16),
        // Gera dinamicamente os cards detalhados para cada sócio da lista
        ...List.generate(
          founders.length,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildFounderCard(founders[i], i),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // Barra de Equity: Cada segmento da barra tem um Flex proporcional à sua participação
  Widget _buildEquityBar(List<Map<String, dynamic>> founders) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 18,
        child: Row(
          children: List.generate(founders.length, (i) {
            // Converte a porcentagem para um valor numérico flexível
            final pct =
                (founders[i]['equityPercent'] as num?)?.toDouble() ?? 0;
            // Escolhe uma cor da paleta baseado na posição do sócio
            final color = _chartColors[i % _chartColors.length];
            return Flexible(
              // Define o tamanho relativo do segmento na barra
              flex: (pct * 100).round(),
              child: Container(color: color),
            );
          }),
        ),
      ),
    );
  }

  // Legenda de Equity: Pequenos indicadores circulares com o resumo de cada sócio
  Widget _buildEquityLegend(List<Map<String, dynamic>> founders) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: List.generate(founders.length, (i) {
        final name = (founders[i]['name'] as String?) ?? '';
        final pct = (founders[i]['equityPercent'] as num?)?.toDouble() ?? 0;
        final color = _chartColors[i % _chartColors.length];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Círculo colorido da legenda
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            // Nome do sócio e sua porcentagem de participação
            Text(
              '$name • ${pct.toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        );
      }),
    );
  }

  // Card do Fundador: Exibe foto (iniciais), cargo, bio e barra de progresso individual
  Widget _buildFounderCard(Map<String, dynamic> founder, int colorIndex) {
    final name = (founder['name'] as String?) ?? '';
    final role = (founder['role'] as String?) ?? '';
    final pct = (founder['equityPercent'] as num?)?.toDouble() ?? 0;
    final bio = (founder['bio'] as String?)?.trim() ?? '';
    final color = _chartColors[colorIndex % _chartColors.length];

    // Lógica para pegar as primeiras letras do nome e criar o avatar circular
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar com iniciais sobre um fundo colorido suave
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Nome e cargo hierárquico na empresa
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      role,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge de porcentagem com bordas arredondadas
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          // Exibe a bio resumida se estiver disponível no banco de dados
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),
            Text(
              bio,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Indicador visual de progresso refletindo a participação do sócio
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // Aba Q&A: Interface de chat para perguntas públicas e envio de novas questões
  Widget _buildQATab(Map<String, dynamic> data) {
    // Busca perguntas oficiais retornadas pelo servidor
    final rawQuestions = data['publicQuestions'] as List<dynamic>? ?? [];
    final serverQuestions =
        rawQuestions.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    // Combina as perguntas que o usuário acabou de enviar (locais) com as do servidor
    final allQuestions = [..._localQuestions, ...serverQuestions];

    return Column(
      children: [
        Expanded(
          child: allQuestions.isEmpty
              ? Center(
                  // Estado vazio quando ainda não há interação na startup
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.white12,
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Nenhuma pergunta ainda.\nSeja o primeiro a perguntar!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  itemCount: allQuestions.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildQuestionCard(allQuestions[i]),
                  ),
                ),
        ),
        // Campo de entrada fixo na base da aba Q&A
        _buildQuestionInput(),
      ],
    );
  }

  // Card de Pergunta: Mostra o autor (mascarado por segurança), o texto e a resposta dos fundadores
  Widget _buildQuestionCard(Map<String, dynamic> q) {
    final text = (q['text'] as String?) ?? '';
    final answer = (q['answer'] as String?)?.trim() ?? '';
    final isPrivate = (q['visibility'] as String?) == 'privada';
    final authorEmail = (q['authorEmail'] as String?) ?? '';

    // Mascara o e-mail para privacidade (ex: j***@gmail.com)
    String maskedEmail = 'Usuário';
    if (authorEmail.contains('@')) {
      final parts = authorEmail.split('@');
      maskedEmail = '${parts[0][0]}***@${parts[1]}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrivate ? _green.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Identificação do autor e data simulada
              Text(
                maskedEmail,
                style: const TextStyle(
                  color: _green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Etiqueta de visibilidade se a pergunta for privada
              if (isPrivate)
                const Text(
                  'PRIVADA',
                  style: TextStyle(color: Colors.white30, fontSize: 10),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Texto da pergunta feita pelo usuário
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          // Se houver uma resposta oficial, exibe um bloco com fundo diferente
          if (answer.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _pageBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resposta oficial:',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    answer,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Campo de Input: Permite digitar, alternar visibilidade e enviar a pergunta
  Widget _buildQuestionInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Botão para alternar entre pergunta pública e privada (restrito aos sócios)
              GestureDetector(
                onTap: () => setState(() => _isPrivate = !_isPrivate),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isPrivate ? _green.withValues(alpha: 0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isPrivate ? _green : Colors.white10,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isPrivate ? Icons.lock_rounded : Icons.public_rounded,
                        size: 14,
                        color: _isPrivate ? _green : Colors.white30,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isPrivate ? 'Privada' : 'Pública',
                        style: TextStyle(
                          color: _isPrivate ? _green : Colors.white30,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Campo de texto: placeholder muda conforme a visibilidade selecionada
              Expanded(
                child: TextField(
                  controller: _questionController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: _isPrivate
                        ? 'Envie uma pergunta privada para a startup...'
                        : 'Faça uma pergunta pública...',
                    hintStyle: const TextStyle(
                      color: Colors.white24,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: _pageBg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Botão enviar: adiciona a pergunta à lista local e limpa o campo
              GestureDetector(
                onTap: () {
                  final text = _questionController.text.trim();
                  if (text.isEmpty) return;
                  setState(() {
                    // Insere no topo para aparecer imediatamente sem recarregar
                    _localQuestions.insert(0, {
                      'text': text,
                      'visibility': _isPrivate ? 'privada' : 'publica',
                      'authorEmail': widget.userModel.email,
                      'answer': '',
                    });
                    _questionController.clear();
                  });
                },
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Aba Eventos: busca em tempo real da coleção event_startups no Firestore
  Widget _buildEventosTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _eventosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _green),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Erro ao carregar eventos:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
            ),
          );
        }

        final eventos = snapshot.data ?? [];

        // Estado vazio: nenhum evento cadastrado para esta startup
        if (eventos.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_busy_rounded, color: Colors.white12, size: 48),
                SizedBox(height: 12),
                Text(
                  'Nenhum evento agendado.',
                  style: TextStyle(color: Colors.white38, fontSize: 15),
                ),
              ],
            ),
          );
        }

        // Lista de eventos com título de seção no índice 0
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: eventos.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _sectionTitle('PRÓXIMOS EVENTOS'),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildEventoCard(eventos[index - 1]),
            );
          },
        );
      },
    );
  }

  // Card de evento: ícone + badge de tipo + título + descrição + data/hora/local
  Widget _buildEventoCard(Map<String, dynamic> e) {
    final tipo = e['tipo'] ?? '';
    final Color tipoColor;
    final IconData tipoIcon;

    // Define cor e ícone com base no tipo do evento
    switch (tipo) {
      case 'Pitch':
        tipoColor = const Color(0xFF1A9B5F); // verde
        tipoIcon = Icons.mic_rounded;
        break;
      case 'Workshop':
        tipoColor = const Color(0xFFF5A623); // laranja
        tipoIcon = Icons.school_rounded;
        break;
      default:
        tipoColor = const Color(0xFF4A90E2); // azul (Relatório e outros)
        tipoIcon = Icons.bar_chart_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha superior: ícone do tipo + badge textual
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tipoColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(tipoIcon, color: tipoColor, size: 16),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tipoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tipoColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  tipo,
                  style: TextStyle(
                    color: tipoColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Título e descrição do evento
          Text(
            e['titulo'] ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            e['descricao'] ?? '',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),
          // Data e horário do evento
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                color: Colors.white38,
                size: 13,
              ),
              const SizedBox(width: 5),
              Text(
                '${e['data']}  •  ${e['horario']}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Local do evento (online ou presencial)
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Colors.white38,
                size: 13,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  e['local'] ?? '',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Badge arredondado usado no cabeçalho para estágio e papel do usuário
  Widget _badge(String label, Color color, {required bool filled}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: filled ? 0.35 : 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Título de seção em verde com letras maiúsculas e espaçamento entre letras
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _green,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }

  // Card pequeno de métrica: valor em destaque + rótulo abaixo
  Widget _statCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // Seção de vídeos demo: lista os players inline ou estado vazio
  Widget _buildDemoVideosSection(List<String> demoVideos) {
    if (demoVideos.isEmpty) {
      // Estado vazio quando não há vídeos cadastrados
      return Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_off_rounded,
                color: Colors.white24,
                size: 36,
              ),
              SizedBox(height: 8),
              Text(
                'Nenhum vídeo disponível',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // Exibe um player inline para cada vídeo demo
    return Column(
      children: List.generate(demoVideos.length, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: i < demoVideos.length - 1 ? 16 : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (demoVideos.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Vídeo Demo ${i + 1}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              // Widget de player inline com controles
              _InlineVideoPlayer(videoUrl: demoVideos[i]),
            ],
          ),
        );
      }),
    );
  }

  // Converte o campo stage (snake_case do Firestore) para texto legível em português
  String _stageLabel() {
    switch (widget.startupStage.toLowerCase()) {
      case 'em_operacao':
        return 'Em operação';
      case 'em_expansao':
        return 'Em expansão';
      case 'nova':
        return 'Nova';
      default:
        return widget.startupStage.replaceAll('_', ' ');
    }
  }

  // Converte o enum UserRole para texto legível em português
  String _roleLabel() {
    switch (widget.userModel.role) {
      case UserRole.investidor:
        return 'Investidor';
      case UserRole.empreendedor:
        return 'Empreendedor';
      case UserRole.admin:
        return 'Admin';
    }
  }

  // Formata o total de tokens emitidos com separador de milhar (pt_BR)
  String _formatTokens(dynamic value) {
    final num v = num.tryParse(value.toString()) ?? 0;
    if (v == 0) return '--';
    return NumberFormat('#,##0', 'pt_BR').format(v);
  }

  // Formata o capital captado em centavos para reais com abreviações (k / M)
  String _formatCapital(dynamic value) {
    final num v = num.tryParse(value.toString()) ?? 0;
    if (v == 0) return '--';
    final double reais = v / 100;
    if (reais >= 1000000) {
      return 'R\$${(reais / 1000000).toStringAsFixed(1)}M';
    }
    if (reais >= 1000) {
      return 'R\$${(reais / 1000).toStringAsFixed(0)}k';
    }
    return 'R\$${reais.toStringAsFixed(0)}';
  }

  // Formata o preço do token de centavos para reais (ex: 125 cents → R$1,25)
  String _formatTokenPrice(dynamic value) {
    final num v = num.tryParse(value.toString()) ?? 0;
    if (v == 0) return '--';
    final double reais = v / 100;
    return 'R\$${reais.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget de player de vídeo inline que embute vídeos do YouTube diretamente
// na tela usando o pacote youtube_player_iframe. Extrai o videoId da URL
// e renderiza o player com controles nativos do YouTube.
// ─────────────────────────────────────────────────────────────────────────────

class _InlineVideoPlayer extends StatefulWidget {
  // URL completa do YouTube (ex: https://www.youtube.com/watch?v=XXXXX)
  final String videoUrl;

  const _InlineVideoPlayer({required this.videoUrl});

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  // Controller do YouTube Player
  late YoutubePlayerController _controller;

  // Indica se a URL do vídeo é válida (contém um videoId extraível)
  bool _isValidUrl = false;

  // Paleta de cores (mesma da tela pai)
  static const _cardBg = Color(0xFF262629);

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  // Extrai o videoId da URL do YouTube e inicializa o controller
  void _initializePlayer() {
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

    if (videoId == null || videoId.isEmpty) {
      _isValidUrl = false;
      return;
    }

    _isValidUrl = true;

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        loop: false,
        forceHD: false,
        enableCaption: true,
      ),
    );
  }

  @override
  void dispose() {
    if (_isValidUrl) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Se a URL não é válida, mostra estado de erro
    if (!_isValidUrl) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.white24,
                size: 36,
              ),
              SizedBox(height: 8),
              Text(
                'URL de vídeo inválida',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // Player do YouTube com cantos arredondados usando o plugin nativo (youtube_player_flutter)
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFF1A9B5F), // Nossa cor verde
        progressColors: const ProgressBarColors(
          playedColor: Color(0xFF1A9B5F),
          handleColor: Colors.white,
        ),
      ),
    );
  }
}
