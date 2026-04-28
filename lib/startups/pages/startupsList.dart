import 'package:flutter/material.dart';

import 'package:mesclainvest_f/components/appBar.dart';
import 'package:mesclainvest_f/components/navBar.dart';
import 'package:mesclainvest_f/model/userModel.dart';

class StartupsList extends StatelessWidget {
  final UserModel userModel;

  const StartupsList({
    super.key,
    required this.userModel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomHeader(userModel: userModel),
      bottomNavigationBar: CustomNavBar(
        userModel: userModel,
        currentIndex: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Startups',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Encontre startups disponíveis para investimento.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 20),

            const TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar startups...',
                hintStyle: TextStyle(color: Colors.white38),
                prefixIcon: Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Color(0xFF111111),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              '2 STARTUPS ENCONTRADAS',
              style: TextStyle(
                color: Color(0xFFB7F52D),
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            startupCard(
              nome: 'EcoTech PUC',
              descricao: 'Soluções sustentáveis para gestão de resíduos urbanos.',
              status: 'Em operação',
              tokens: '1.200 tokens',
              valor: 'R\$ 42.000 captados',
            ),

            const SizedBox(height: 12),

            startupCard(
              nome: 'MedConnect',
              descricao: 'Plataforma que conecta pacientes a clínicas.',
              status: 'Nova',
              tokens: '850 tokens',
              valor: 'R\$ 18.000 captados',
            ),
          ],
        ),
      ),
    );
  }

  Widget startupCard({
    required String nome,
    required String descricao,
    required String status,
    required String tokens,
    required String valor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.business_center_outlined,
            color: Color(0xFFB7F52D),
            size: 40,
          ),

          const SizedBox(height: 10),

          Text(
            nome,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            descricao,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            status,
            style: const TextStyle(
              color: Color(0xFFB7F52D),
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            tokens,
            style: const TextStyle(color: Colors.white70),
          ),

          Text(
            valor,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}