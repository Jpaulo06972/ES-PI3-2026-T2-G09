// Importa o pacote básico de UI do Flutter
import 'package:flutter/material.dart';

// Importa os componentes de cabeçalho e barra de navegação personalizados
import 'package:mesclainvest_f/components/appBar.dart';
import 'package:mesclainvest_f/components/navBar.dart';
import 'package:mesclainvest_f/dashboard/components/dashboardPainel.dart';

// Importa o modelo de usuário para acessar os dados do usuário logado
import 'package:mesclainvest_f/model/userModel.dart';

// Tela principal (Home) do aplicativo, exibida após o login
class HomePage extends StatefulWidget {
  // Recebe os dados do usuário logado via construtor
  final UserModel user;

  // Construtor constante da tela principal
  const HomePage({super.key, required this.user});

  // Cria o estado para esta tela, passando os dados do usuário
  @override
  State<HomePage> createState() => _HomePageState(userModel: user);
}

// Classe que gerencia o estado da tela principal
class _HomePageState extends State<HomePage> {
  // Variável para armazenar os dados do usuário
  final UserModel userModel;

  // Inicializa o estado com o modelo do usuário
  _HomePageState({required this.userModel});

  @override
  Widget build(BuildContext context) {
    // Scaffold é a estrutura base da tela (barra superior, corpo, barra inferior)
    return Scaffold(
      // Barra superior personalizada (CustomHeader) passando os dados do usuário
      appBar: CustomHeader(userModel: userModel),

      // Corpo da tela, alinhado no topo à esquerda com padding
      body: SingleChildScrollView(
        // Coluna para empilhar os elementos verticalmente
        child: Column(
          // Alinha o conteúdo à esquerda
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seção do saldo com padding lateral
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label "Total investido + Conta investimento"
                  Text(
                    "Total investido + Conta investimento",
                    style: const TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                  const SizedBox(height: 4),
                  // Valor total do investimento
                  Text(
                    "R\$ 15.000,00",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Gráfico de desempenho da carteira
            const DashboardChart(),
          ],
        ),
      ),

      // Barra de navegação inferior, configurada para exibir a tela 0 (Investimentos) como ativa
      bottomNavigationBar: CustomNavBar(userModel: userModel, currentIndex: 0),
    );
  }
}
