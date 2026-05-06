// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684
// Feito originalmente por: Tomás Toniato RA: 25004211

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

class _StartupsDetailsState extends State<StartupsDetails> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StartupService _service = StartupService();
  late Future<Map<String, dynamic>> _detailsFuture;
  String? _coverImageUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _detailsFuture = _service.getStartupDetails(widget.startupId);
    _loadCoverImage();
  }

  Future<void> _loadCoverImage() async {
    if (widget.storagePath == null || widget.storagePath!.isEmpty) return;
    try {
      final url = await FirebaseStorage.instance.ref(widget.storagePath!).getDownloadURL();
      if (mounted) setState(() => _coverImageUrl = url);
    } catch (e) {
      debugPrint('Erro ao carregar imagem de capa: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StartupColors.pageBg,
      bottomNavigationBar: CustomNavBar(userModel: widget.userModel, currentIndex: 1),
      body: SafeArea(
        child: Column(
          children: [
            // O Header da startup agora recebe o objeto UserRole corretamente do UserModel
            StartupHeader(
              startupName: widget.startupName,
              startupStage: widget.startupStage,
              userRole: widget.userModel.role, // Aqui estava o erro de tipo
              coverImageUrl: _coverImageUrl,
              onBack: () => Navigator.pop(context),
            ),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Aba Sobre: Passa os detalhes carregados
                  _detailsBuilder((data) => SobreTab(details: data)),
                  // Aba Sócios: Trata a lista de fundadores
                  _detailsBuilder((data) {
                    final founders = (data['founders'] as List<dynamic>? ?? [])
                        .map((e) => Map<String, dynamic>.from(e as Map))
                        .toList();
                    return SociosTab(founders: founders);
                  }),
                  // Aba Q&A: Interação direta
                  QATab(startupId: widget.startupId, service: _service),
                  // Aba Eventos: Cronograma
                  EventosTab(startupName: widget.startupName, service: _service),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builder auxiliar para lidar com o FutureBuilder de forma limpa nas abas
  Widget _detailsBuilder(Widget Function(Map<String, dynamic>) builder) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: StartupColors.green));
        }
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
        return builder(snapshot.data ?? {});
      },
    );
  }

  // Constrói a barra de abas customizada
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: StartupColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: StartupColors.pageBg,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
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
}
