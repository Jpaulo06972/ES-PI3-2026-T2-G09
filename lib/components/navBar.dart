// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// O de sempre: pacote principal do Flutter pra construir as telinhas.
import 'package:flutter/material.dart';

// Importando todas as telas que a NavBar consegue acessar.
// Cada aba precisa do arquivo da tela de destino.
import 'package:mesclainvest_f/counter/pages/counterPage.dart';
import 'package:mesclainvest_f/dashboard/pages/home.dart';
import 'package:mesclainvest_f/startups/pages/startupsList.dart';
import 'package:mesclainvest_f/wallet/pages/rechargeMoney.dart';
import 'package:mesclainvest_f/profile/profile.dart';

import 'package:mesclainvest_f/model/userModel.dart';

/// Barra de navegação inferior customizada do app.
/// Por que não usamos a `BottomNavigationBar` padrão do Flutter?
/// Porque a gente queria esse visual de "pílula branca" no ícone ativo,
/// e a barra padrão é super chata pra customizar num nível tão específico.
/// Fazendo na mão (com Row e Containers), a gente tem controle total.
class CustomNavBar extends StatelessWidget {
  // O usuário logado, que vai ser passado de mão em mão pras próximas telas.
  final UserModel userModel;

  // Variável que diz qual aba tá selecionada agora:
  // 0 = Dashboard, 1 = Startups, 2 = Negociar, 3 = Carteira, 4 = Perfil.
  final int currentIndex;

  const CustomNavBar({
    super.key,
    required this.userModel,
    this.currentIndex = 0, // Se não passar nada, assume que tá no Dashboard.
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Esse padding é o segredo pro layout não quebrar.
      padding: EdgeInsets.only(
        top: 12,
        // Esse MediaQuery.of(context).padding.bottom é genial!
        // Ele pega o tamanho exato daquela "barrinha de home" do iPhone ou dos botões virtuais do Android,
        // garantindo que nossos ícones nunca fiquem escondidos lá embaixo.
        bottom: MediaQuery.of(context).padding.bottom + 8,
        left: 8,
        right: 8,
      ),
      // Fundo transparente pra pegar a cor da tela onde ela foi colocada.
      decoration: const BoxDecoration(color: Colors.transparent),

      // Coloca os botõezinhos todos um do lado do outro com espaço igual entre eles.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // --- ABA 0: DASHBOARD ---
          _buildNavItem(
            context,
            index: 0,
            icon: Icons
                .leaderboard_outlined, // Ícone vazado (quando não tá na aba).
            activeIcon:
                Icons.leaderboard, // Ícone preenchido (quando tá na aba).
            label: 'Dashboard',
            onTap: () {
              // Dica de navegação: usamos pushReplacement em vez de push!
              // Se usasse o push normal, clicar na barra ia empilhando telas infinitamente
              // até o celular travar sem memória. O pushReplacement mata a tela atual e bota a nova no lugar.
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(user: userModel),
                ),
              );
            },
          ),

          // --- ABA 1: STARTUPS ---
          _buildNavItem(
            context,
            index: 1,
            icon: Icons.rocket_launch_outlined,
            activeIcon: Icons.rocket_launch,
            label: 'Startups',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => StartupsList(userModel: userModel),
                ),
              );
            },
          ),

          // --- ABA 2: NEGOCIAR (BALCÃO) ---
          _buildNavItem(
            context,
            index: 2,
            icon: Icons.candlestick_chart_outlined,
            activeIcon: Icons.candlestick_chart,
            label: 'Negociar',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CounterPage(user: userModel),
                ),
              );
            },
          ),

          // --- ABA 3: CARTEIRA ---
          _buildNavItem(
            context,
            index: 3,
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet,
            label: 'Carteira',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => RechargeMoneyPage(user: userModel),
                ),
              );
            },
          ),

          // --- ABA 4: PERFIL ---
          _buildNavItem(
            context,
            index: 4,
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Perfil',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(userModel: userModel),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Constrói cada um dos 5 botõezinhos da barra.
  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required VoidCallback onTap,
  }) {
    // Checa se o botão que estamos desenhando agora é o da tela atual.
    final bool isActive = index == currentIndex;

    return GestureDetector(
      // Se já tá nessa tela, desabilita o clique passando null.
      // Isso evita recarregar a mesma tela à toa.
      onTap: isActive ? null : onTap,

      // Sem o HitTestBehavior.opaque, o Flutter só reconheceria o clique bem em cima
      // das linhas do ícone ou das letras. Com isso aqui, qualquer clique quadrado em volta dele funciona.
      behavior: HitTestBehavior.opaque,
      child: Column(
        // min: Faz a coluna apertar o conteúdo e não ocupar a tela toda pra cima.
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- DESENHO DO ÍCONE ---
          Container(
            width: 44,
            height: 36,
            decoration: BoxDecoration(
              // Se for a aba ativa, pinta o fundo de branco. Se não, fica invisível.
              color: isActive ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(
                10,
              ), // Canto arredondadinho da pílula.
            ),
            child: Center(
              child: Icon(
                isActive
                    ? activeIcon
                    : icon, // Troca pro ícone cheião se tiver ativo.
                // Troca a cor: preto no fundo branco, ou cinzinha no fundo transparente.
                color: isActive ? const Color(0xFF1A1A2E) : Colors.white38,
                size: 22,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // --- TEXTINHO EMBAIXO DO ÍCONE ---
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white38,
              fontSize: 10,
              // Se tiver ativo dá um leve boldzinho pra destacar mais.
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
