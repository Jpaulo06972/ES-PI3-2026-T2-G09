// Feito por: Tomás Toniato RA: 25004211

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  const StartupsDetails({
    super.key,
    required this.startupId,
    required this.startupName,
    required this.startupStage,
    required this.userModel,
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

  // Cabeçalho com gradiente verde → escuro, botão de voltar, nome e badges
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D5C38), Color(0xFF1A1A1E)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botão voltar — retorna para a lista de startups
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white70,
                  size: 14,
                ),
                SizedBox(width: 6),
                Text(
                  'Catálogo',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Nome da startup recebido como parâmetro da tela anterior
          Text(
            widget.startupName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Badge verde com o estágio da startup (ex: "Em operação")
              _badge(_stageLabel(), _green, filled: true),
              const SizedBox(width: 8),
              // Badge branco com o papel do usuário logado (ex: "Investidor")
              _badge(_roleLabel(), Colors.white, filled: false),
            ],
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

  // Aba Sobre: estatísticas (tokens, capital, preço) + descrição + vídeo
  Widget _buildSobreTab(Map<String, dynamic> data) {
    final rawTokens = data['totalTokensIssued'] ?? data['tokens'] ?? 0;
    final rawCapital = data['capitalRaisedCents'] ?? data['capital'] ?? 0;
    final description =
        (data['description'] ?? data['descricao'] ?? '').toString().trim();
    final videoUrl = (data['video'] ?? '').toString().trim();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        // Linha de 3 cards com as métricas principais da startup
        Row(
          children: [
            Expanded(child: _statCard('--', 'Preço\ntoken')),
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

        _sectionTitle('VÍDEOS'),
        const SizedBox(height: 12),
        _videoPlayer(videoUrl),

        const SizedBox(height: 32),
      ],
    );
  }

  // Aba Sócios: barra de participação + legenda + cards individuais de cada sócio
  Widget _buildSociosTab(Map<String, dynamic> data) {
    // Extrai a lista de founders do retorno da Firebase Function
    final rawFounders = data['founders'] as List<dynamic>? ?? [];
    final founders = rawFounders
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    if (founders.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum sócio cadastrado.',
          style: TextStyle(color: Colors.white38, fontSize: 15),
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        _sectionTitle('COMPOSIÇÃO SOCIETÁRIA'),
        const SizedBox(height: 16),
        // Barra horizontal colorida proporcional ao equityPercent de cada sócio
        _buildEquityBar(founders),
        const SizedBox(height: 8),
        // Legenda com nome e percentual de cada sócio
        _buildEquityLegend(founders),
        const SizedBox(height: 28),
        _sectionTitle('SÓCIOS E FUNDADORES'),
        const SizedBox(height: 16),
        // Gera um card para cada sócio usando índice para atribuir a cor correta
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

  // Barra empilhada: cada segmento tem largura proporcional ao equityPercent
  // Usa List.generate em vez de .asMap().entries.map() para compatibilidade com Flutter web
  Widget _buildEquityBar(List<Map<String, dynamic>> founders) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 18,
        child: Row(
          children: List.generate(founders.length, (i) {
            final pct =
                (founders[i]['equityPercent'] as num?)?.toDouble() ?? 0;
            final color = _chartColors[i % _chartColors.length];
            // flex proporcional ao percentual (multiplicado por 100 para int)
            return Flexible(
              flex: (pct * 100).round(),
              child: Container(color: color),
            );
          }),
        ),
      ),
    );
  }

  // Legenda colorida abaixo da barra: bolinha + "Nome • XX%"
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
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              '$name • ${pct.toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        );
      }),
    );
  }

  // Card individual de sócio: avatar com iniciais, nome, cargo, badge de % e bio
  Widget _buildFounderCard(Map<String, dynamic> founder, int colorIndex) {
    final name = (founder['name'] as String?) ?? '';
    final role = (founder['role'] as String?) ?? '';
    final pct = (founder['equityPercent'] as num?)?.toDouble() ?? 0;
    final bio = (founder['bio'] as String?)?.trim() ?? '';
    final color = _chartColors[colorIndex % _chartColors.length];

    // Gera as iniciais a partir das duas primeiras palavras do nome
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
              // Avatar circular com as iniciais do sócio
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
              // Nome e cargo do sócio
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
              // Badge com o percentual de participação
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
          // Bio só aparece se estiver preenchida no documento da startup
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
          // Barra de progresso visual do percentual de participação
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

  // Aba Q&A: lista perguntas públicas do servidor + perguntas enviadas localmente
  Widget _buildQATab(Map<String, dynamic> data) {
    // Perguntas públicas retornadas pela Firebase Function
    final rawQuestions = data['publicQuestions'] as List<dynamic>? ?? [];
    final serverQuestions =
        rawQuestions.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    // Mescla as perguntas locais (topo) com as do servidor
    final allQuestions = [..._localQuestions, ...serverQuestions];

    return Column(
      children: [
        Expanded(
          child: allQuestions.isEmpty
              ? Center(
                  // Estado vazio: encoraja o usuário a fazer a primeira pergunta
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
        // Campo fixo na parte inferior para digitar e enviar perguntas
        _buildQuestionInput(),
      ],
    );
  }

  // Card de pergunta: exibe visibilidade, autor mascarado, texto e resposta (se houver)
  Widget _buildQuestionCard(Map<String, dynamic> q) {
    final text = (q['text'] as String?) ?? '';
    final answer = (q['answer'] as String?)?.trim() ?? '';
    final isPrivate = (q['visibility'] as String?) == 'privada';
    final authorEmail = (q['authorEmail'] as String?) ?? '';

    // Mascara o email do autor por privacidade: "t***@email.com"
    final maskedAuthor = authorEmail.contains('@')
        ? '${authorEmail.split('@')[0][0]}***@${authorEmail.split('@')[1]}'
        : 'Anônimo';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        // Borda azul para perguntas privadas, sutil para públicas
        border: Border.all(
          color: isPrivate
              ? const Color(0xFF4A90E2).withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha superior: ícone de visibilidade e autor mascarado
          Row(
            children: [
              Icon(
                isPrivate ? Icons.lock_outline_rounded : Icons.public_rounded,
                color: isPrivate ? const Color(0xFF4A90E2) : Colors.white38,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                isPrivate ? 'Privada' : 'Pública',
                style: TextStyle(
                  color: isPrivate ? const Color(0xFF4A90E2) : Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                maskedAuthor,
                style: const TextStyle(color: Colors.white24, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Texto da pergunta
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          // Bloco de resposta: só aparece se a startup tiver respondido
          if (answer.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _green.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.verified_rounded, color: _green, size: 13),
                      SizedBox(width: 5),
                      Text(
                        'Resposta da startup',
                        style: TextStyle(
                          color: _green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    answer,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
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

  // Área fixa no rodapé da aba Q&A: toggle pública/privada + campo de texto + botão enviar
  Widget _buildQuestionInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        // Respeita a área segura do celular (notch inferior)
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toggle segmentado: Pública (verde) | Privada (azul)
          Row(
            children: [
              const Text(
                'Visibilidade:',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(width: 10),
              // Botão "Pública" — lado esquerdo do toggle
              GestureDetector(
                onTap: () => setState(() => _isPrivate = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: !_isPrivate
                        ? _green.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(20),
                    ),
                    border: Border.all(
                      color: !_isPrivate
                          ? _green.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.public_rounded,
                        size: 13,
                        color: !_isPrivate ? _green : Colors.white38,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Pública',
                        style: TextStyle(
                          color: !_isPrivate ? _green : Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Botão "Privada" — lado direito do toggle
              GestureDetector(
                onTap: () => setState(() => _isPrivate = true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _isPrivate
                        ? const Color(0xFF4A90E2).withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(20),
                    ),
                    border: Border.all(
                      color: _isPrivate
                          ? const Color(0xFF4A90E2).withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 13,
                        color:
                            _isPrivate ? const Color(0xFF4A90E2) : Colors.white38,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Privada',
                        style: TextStyle(
                          color: _isPrivate
                              ? const Color(0xFF4A90E2)
                              : Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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

  // Player de vídeo: exibe botão play se houver URL, ícone de indisponível caso contrário
  Widget _videoPlayer(String videoUrl) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Center(
        child: videoUrl.isNotEmpty
            ? Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _green.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              )
            : const Icon(
                Icons.videocam_off_rounded,
                color: Colors.white24,
                size: 40,
              ),
      ),
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
}
