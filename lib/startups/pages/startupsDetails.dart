// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mesclainvest_f/components/navBar.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/startups/services/getStartup.dart';
import 'package:mesclainvest_f/startups/components/startup_colors.dart';
import 'package:mesclainvest_f/startups/components/startup_header.dart';
import 'package:mesclainvest_f/startups/components/sobre_tab.dart';
import 'package:mesclainvest_f/startups/components/socios_tab.dart';
import 'package:mesclainvest_f/startups/components/qa_tab.dart';
import 'package:mesclainvest_f/startups/components/eventos_tab.dart';

/// [StartupsDetails] é a "Caixa Forte". É a tela principal que segura todas as abas (Sobre, Sócios, Q&A, Eventos).
/// 
/// Por que usar o "with SingleTickerProviderStateMixin"?
/// Porque abas deslizantes no Flutter precisam de um metrônomo (Ticker) para sincronizar
/// a animação do dedo do usuário arrastando a tela com o movimento da barrinha azul lá em cima.
/// O "vsync: this" é exatamente a gente dizendo pro TabController: "Usa o meu metrônomo".
class StartupsDetails extends StatefulWidget {
  final String startupId;
  final String startupName;
  final String startupStage;
  final UserModel userModel;
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

class _StartupsDetailsState extends State<StartupsDetails>
    with SingleTickerProviderStateMixin {
  // Controlador que manda e desmanda nas abas.
  late TabController _tabController;
  
  // Serviço do backend
  final StartupService _service = StartupService();
  
  // Guardamos o Future aqui pra não ficar chamando o banco de dados
  // toda vez que a tela piscar ou o teclado subir.
  late Future<Map<String, dynamic>> _detailsFuture;
  
  // URL da capa da startup que vai ser resolvida lá no Firebase Storage
  String? _coverImageUrl;

  @override
  void initState() {
    super.initState();
    // Instancia o controlador com 4 abas e liga no metrônomo da tela (vsync)
    _tabController = TabController(length: 4, vsync: this);
    
    // Dispara a busca pesada no banco logo de cara
    _detailsFuture = _service.getStartupDetails(widget.startupId);
    
    // Dispara o download da imagem de capa (se existir)
    _loadCoverImage();
  }

  /// Vai lá no Firebase Storage, entrega o "caminho relativo" (ex: images/capa.png)
  /// e volta com um link HTTPS que o Flutter consegue baixar a imagem.
  Future<void> _loadCoverImage() async {
    // Se a startup não cadastrou capa, a gente aborta a missão sem dar erro.
    if (widget.storagePath == null || widget.storagePath!.isEmpty) return;
    
    try {
      final url = await FirebaseStorage.instance
          .ref(widget.storagePath!)
          .getDownloadURL();
          
      // Se a tela não foi fechada enquanto a internet carregava, a gente avisa o Flutter:
      // "Opa, chegou a imagem, repinta a tela aí"
      if (mounted) setState(() => _coverImageUrl = url);
    } catch (e) {
      // Se der ruim (sem internet, arquivo deletado), a gente só avisa no console,
      // porque o Header já tem um fundo verde reserva pra cobrir o buraco.
      debugPrint('Erro ao carregar imagem de capa: $e');
    }
  }

  /// Recarrega a startup toda (Usado quando o cara acabou de comprar tokens e o saldo mudou)
  void _refreshDetails() {
    setState(() {
      _detailsFuture = _service.getStartupDetails(widget.startupId);
    });
  }

  @override
  void dispose() {
    // Nunca esqueça de matar o controller de animação, senão o app vai
    // engasgar depois de um tempo de uso. (Memory Leak)
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Nosso NavBar customizado lá em baixo, marcando a aba "1" (Catálogo)
      bottomNavigationBar: CustomNavBar(
        userModel: widget.userModel,
        currentIndex: 1,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // A Placa (Header)
            StartupHeader(
              startupName: widget.startupName,
              startupStage: widget.startupStage,
              userRole: widget.userModel.role,
              coverImageUrl: _coverImageUrl,
              // Navigator.pop destrói essa tela e volta pra lista de startups
              onBack: () => Navigator.pop(context),
            ),
            
            // O Menu (As 4 guias de navegação)
            _buildTabBar(),
            
            // O Conteúdo (As páginas que deslizam)
            // Expanded garante que as abas ocupem todo o resto da tela
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  
                  // Aba 1: Sobre (Passa a função de refresh caso haja trade)
                  _detailsBuilder((data) => SobreTab(
                        data: data,
                        userModel: widget.userModel,
                        onRefresh: _refreshDetails,
                      )),
                      
                  // Aba 2: Sócios (Extrai a lista de fundadores com um TypeCast defensivo pesadão)
                  _detailsBuilder((data) {
                    final founders = (data['founders'] as List<dynamic>? ?? [])
                        .map((e) => Map<String, dynamic>.from(e as Map))
                        .toList();
                    return SociosTab(founders: founders);
                  }),
                  
                  // Aba 3: O Fórum (Q&A)
                  QATab(
                    startupId: widget.startupId,
                    service: _service,
                    userModel: widget.userModel,
                  ),
                  
                  // Aba 4: Calendário de Eventos
                  EventosTab(
                    startupName: widget.startupName,
                    service: _service,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// [_detailsBuilder] é um truque de Mestre (Helper Method).
  /// Em vez de escrever o 'FutureBuilder' com o 'if waiting' e 'if error' duas vezes
  /// (uma pra Aba Sobre, outra pra Aba Sócios), a gente isola a lógica chata aqui
  /// e passa uma função "builder" que constrói a tela só quando os dados já chegaram.
  Widget _detailsBuilder(Widget Function(Map<String, dynamic>) builder) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        
        // Rodando o spinner de carregamento
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: StartupColors.green),
          );
        }
        
        // Se a internet cair, mostra um aviso em vez de tela branca.
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Erro ao carregar:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
            ),
          );
        }
        
        // Sucesso! Passa o mapa de dados pra aba que pediu
        return builder(snapshot.data ?? {});
      },
    );
  }

  /// O construtor das guias.
  /// Aqui a gente estilizou pesado pra não parecer aquele app de Android de 2012.
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: StartupColors.cardBg, // Fundo cinza chumbo
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        // O indicador agora é um retângulo arredondado quase preto, como se fosse um botão físico selecionado.
        indicator: BoxDecoration(
          color: StartupColors.pageBg,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab, // Estica até o limite da aba
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38, // Aba apagada fica cinza pra não competir por atenção
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        dividerColor: Colors.transparent, // Tira aquele risco azul ridículo do Material Design 3
        tabs: const [
          Tab(text: 'Sobre'),
          Tab(text: 'Sócios'),
          Tab(text: 'Q&A'),
          Tab(text: 'Eventos'),
        ],
      ),
    );
  }
}
