// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote básico de UI do Flutter para usar widgets como Scaffold e Column
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Importa os componentes de cabeçalho e barra de navegação personalizados para manter a identidade visual
import 'package:mesclainvest_f/components/appBar.dart';
import 'package:mesclainvest_f/components/navBar.dart';
// Importa o painel do dashboard que contém o gráfico e outras métricas
import 'package:mesclainvest_f/dashboard/components/dashboardPainel.dart';
import 'package:mesclainvest_f/dashboard/components/my_invested_startups_card.dart';

// Importa o modelo de usuário para acessar os dados do usuário logado, como nome e saldo
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';

// Tela principal (Home) do aplicativo, exibida após o login com sucesso
class HomePage extends StatefulWidget {
  // Recebe os dados do usuário logado via construtor para popular a tela
  final UserModel user;

  // Construtor constante da tela principal, exigindo o objeto user
  const HomePage({super.key, required this.user});

  // Cria o estado para esta tela, passando os dados do usuário para o estado interno
  @override
  State<HomePage> createState() => _HomePageState(userModel: user);
}

// Classe que gerencia o estado da tela principal e sua lógica de renderização
class _HomePageState extends State<HomePage> {
  // Variável para armazenar os dados do usuário localmente no estado
  final UserModel userModel;

  // Controla se o valor do saldo está visível ou oculto (••••••)
  bool _isVisible = false;

  // Usamos um getter em vez de uma variável direta para evitar o erro de inicialização e manter o saldo atualizado
  double get saldo => userModel.saldo;

  // Inicializa o estado com o modelo do usuário recebido
  _HomePageState({required this.userModel});

  // Método principal que constrói a interface da tela
  @override
  Widget build(BuildContext context) {
    // Scaffold é a estrutura base da tela que organiza cabeçalho, corpo e rodapé
    return Scaffold(
      // Barra superior personalizada (CustomHeader) que exibe informações do usuário no topo
      appBar: CustomHeader(
        userModel: userModel,
        isVisible: _isVisible,
        onToggleVisibility: () {
          setState(() {
            _isVisible = !_isVisible;
          });
        },
      ),

      // Corpo da tela envolto em um scroll para permitir navegação se o conteúdo for longo
      body: SingleChildScrollView(
        // Coluna para empilhar os elementos de forma vertical (texto, gráfico, lista)
        child: Column(
          // Alinha todos os itens da coluna à esquerda da tela
          crossAxisAlignment: CrossAxisAlignment.start,
          // Lista de widgets que compõem o conteúdo do dashboard
          children: [
            // Seção do saldo com um respiro (padding) nas laterais para não encostar na borda
            Padding(
              // Define o distanciamento: esquerda, cima, direita e baixo
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              // Organiza o texto do saldo em uma coluna interna
              child: Column(
                // Alinha os textos à esquerda dentro deste bloco
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Texto informativo que descreve o que o valor abaixo representa
                  const Text(
                    "Total investido + Conta investimento",
                    // Define o tamanho da fonte e uma cor branca suavizada (cinza)
                    style: TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                  // Um pequeno espaço vertical de 4 pixels entre os textos
                  const SizedBox(height: 4),

                  TotalBalanceDisplay(
                    userModel: userModel,
                    isVisible: _isVisible,
                  ),
                ],
              ),
            ),

            // Widget que renderiza o gráfico de desempenho da carteira
            DashboardChart(userModel: userModel),

            // Espaçamento vertical generoso entre o gráfico e a próxima seção
            const SizedBox(height: 18),

            // Título da seção "Minhas Startups" com distanciamento das bordas
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: const Text(
                "Minhas Startups",
                // Estilo consistente com o restante do dashboard (negrito e grande)
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Card exibindo a lista de startups investidas
            MyInvestedStartupsCard(userModel: userModel, isVisible: _isVisible),

            const SizedBox(height: 32),
          ],
        ),
      ),

      // Barra de navegação inferior que permite mudar entre as telas principais

// currentIndex: 0 indica que o ícone de "Investimentos" ficará destacado
      bottomNavigationBar: CustomNavBar(userModel: userModel, currentIndex: 0),
    );
  }
}

class TotalBalanceDisplay extends StatelessWidget {
  final UserModel userModel;
  final bool isVisible;

  const TotalBalanceDisplay({
    super.key,
    required this.userModel,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? userModel.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, userSnap) {
        double liveSaldo = userModel.saldo;
        if (userSnap.hasData && userSnap.data!.exists) {
          liveSaldo = ((userSnap.data!.data() as Map<String, dynamic>)['saldo'] as num?)?.toDouble() ?? 0.0;
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('startups').snapshots(),
          builder: (context, startupsSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('holdings')
                  .where('userId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, holdingsSnap) {
                double portfolioValue = 0.0;

                if (startupsSnap.hasData && holdingsSnap.hasData) {
                  final holdingsDocs = holdingsSnap.data!.docs;
                  final startupsDocs = startupsSnap.data!.docs;

                  final Map<String, double> startupPrices = {};
                  for (var doc in startupsDocs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final currentPrice = (data['currentPrice'] as num?)?.toDouble() ?? 
                                         (((data['currentTokenPriceCents'] as num?)?.toInt() ?? 100) / 100.0);
                    startupPrices[doc.id] = currentPrice;
                  }

                  for (var doc in holdingsDocs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final qty = (data['quantity'] as num?)?.toDouble() ?? 0.0;
                    final startupId = data['startupId'] as String? ?? '';
                    if (qty > 0 && startupPrices.containsKey(startupId)) {
                      portfolioValue += (qty * startupPrices[startupId]!);
                    }
                  }
                }

                final totalBalance = liveSaldo + portfolioValue;

                return Text(
                  isVisible ? CurrencyInputFormatter.formatValue(totalBalance) : "R\$ ••••••",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
