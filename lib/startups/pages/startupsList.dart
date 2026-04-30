import 'package:flutter/material.dart';

import 'package:mesclainvest_f/components/appBar.dart';
import 'package:mesclainvest_f/components/navBar.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/startups/components/cardStartups.dart';
import 'package:mesclainvest_f/startups/services/getStartup.dart';

class StartupsList extends StatefulWidget {
  final UserModel userModel;

  const StartupsList({super.key, required this.userModel});

  @override
  State<StartupsList> createState() => _StartupsListState();
}

class _StartupsListState extends State<StartupsList> {
  final StartupService _startupService = StartupService();
  late Future<List<Map<String, dynamic>>> _startupsFuture;

  @override
  void initState() {
    super.initState();
    // Inicia a requisição para buscar as startups quando a tela carrega
    _startupsFuture = _startupService.listStartups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomHeader(userModel: widget.userModel),
      bottomNavigationBar: CustomNavBar(
        userModel: widget.userModel,
        currentIndex: 1,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _startupsFuture,
        builder: (context, snapshot) {
          // Exibe loading enquanto carrega
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A9B5F)),
            );
          }

          // Exibe erro se der problema
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Erro ao carregar startups:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          final startups = snapshot.data ?? [];

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // Header Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Oportunidades Exclusivas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Invista no futuro com as startups mais promissoras do mercado.',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Buscar pelo nome ou setor...',
                    hintStyle: const TextStyle(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 12, right: 8),
                      child: Icon(
                        Icons.search,
                        color: Colors.white54,
                        size: 22,
                      ),
                    ),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A9B5F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF262629),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Em destaque',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A9B5F).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${startups.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Ver todas',
                      style: TextStyle(
                        color: Color(0xFF1A9B5F),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Renderiza a lista dinamicamente
              if (startups.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Nenhuma startup encontrada.',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ),
                )
              else
                ...startups.map((startup) {
                  // Mapeia os dados vindo do Firestore (ou HTTP) para a interface
                  final nome = startup['name'] ?? 'Sem Nome';
                  final desc = startup['shortDescription'] ?? '';
                  final status = startup['stage'] ?? 'Desconhecido';

                  // Formatação simples para tokens e valor
                  final tokensInt = startup['totalTokensIssued'] ?? 0;
                  final valorCents = startup['capitalRaisedCents'] ?? 0;
                  final valorReal = valorCents / 100;

                  final imgUrl = startup['coverImageUrl'];
                  // Se tiver imgUrl e começar com startups/, é um caminho do Storage
                  final bool isStorage = imgUrl != null && imgUrl.startsWith('startups/');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: startupCard(
                      nome: nome,
                      descricao: desc,
                      status: status.replaceAll('_', ' ').toUpperCase(),
                      tokens: tokensInt.toString(),
                      valor: 'R\$ ${valorReal.toStringAsFixed(0)}',
                      progress: 0.65,
                      icon: Icons.rocket_launch_rounded,
                      imageUrl: isStorage ? null : imgUrl,
                      storagePath: isStorage ? imgUrl : (imgUrl == null ? 'startups_images/${nome.toLowerCase().replaceAll(' ', '-')}.png' : null),
                    ),
                  );
                }),

              const SizedBox(height: 30), // Bottom padding
            ],
          );
        },
      ),
    );
  }
}
