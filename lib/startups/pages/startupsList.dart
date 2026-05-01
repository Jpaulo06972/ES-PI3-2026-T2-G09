// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:flutter/material.dart';

import 'package:mesclainvest_f/components/appBar.dart';
import 'package:mesclainvest_f/components/navBar.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/startups/components/cardStartups.dart';
import 'package:mesclainvest_f/startups/services/getStartup.dart';

/// Página que exibe a lista (catálogo) de startups disponíveis para investimento.
/// Permite buscar startups por nome ou setor e visualizar seus detalhes básicos.
class StartupsList extends StatefulWidget {
  // Modelo do usuário logado, necessário para a navegação e identificação
  final UserModel userModel;

  const StartupsList({super.key, required this.userModel});

  @override
  State<StartupsList> createState() => _StartupsListState();
}

/// Estado da página de lista de startups.
/// Gerencia a busca de dados no backend e a exibição dos cards dinâmicos.
class _StartupsListState extends State<StartupsList> {
  // Instância do serviço que busca dados no Firebase
  final StartupService _startupService = StartupService();
  
  // Future que armazenará a lista de startups carregada do banco
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

                  // Ignora o campo coverImageUrl do documento e busca a imagem no Storage
                  // baseando-se no nome da startup, pois a imagem é salva com o nome da startup.
                  final storageName = nome.toLowerCase().replaceAll(' ', '-');
                  final storagePath = 'startups_images/$storageName.png';

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
                      imageUrl: null,
                      storagePath: storagePath,
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
