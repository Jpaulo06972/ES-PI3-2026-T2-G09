// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote do Flutter com tudo que precisamos pra montar a interface
import 'package:flutter/material.dart';

// Importa as páginas que serão navegadas pela barra inferior
import 'package:mesclainvest_f/dashboard/pages/home.dart';
import 'package:mesclainvest_f/dashboard/pages/notification.dart';
import 'package:mesclainvest_f/startups/pages/startupsList.dart';
import 'package:mesclainvest_f/profile/profile.dart';

// Importa o modelo de usuário para passar os dados entre as telas
import 'package:mesclainvest_f/model/userModel.dart';

// Widget da barra de navegação inferior personalizada (estilo Rico)
class CustomNavBar extends StatelessWidget {
  // Dados do usuário logado, necessário para navegação entre telas
  final UserModel userModel;

  // Índice da tela atual para destacar o ícone ativo
  // (0=Investimentos, 1=Startups, 2=Balcão, 3=Carteira, 4=Perfil)
  final int currentIndex;

  // Construtor que recebe o modelo do usuário e o índice da tela atual
  const CustomNavBar({
    super.key,
    required this.userModel,
    this.currentIndex = 0, // Por padrão, a tela de Investimentos é a ativa
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Espaçamento interno da barra de navegação
      padding: EdgeInsets.only(
        top: 12,
        bottom:
            MediaQuery.of(context).padding.bottom +
            8, // Respeita a área segura inferior do celular
        left: 8,
        right: 8,
      ),
      // Fundo transparente para herdar a cor do Scaffold
      decoration: const BoxDecoration(color: Colors.transparent),

      // Linha horizontal com os itens de navegação distribuídos igualmente
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Item 1: Investimentos (tela principal / Home)
          _buildNavItem(
            context,
            index: 0,
            icon: Icons.leaderboard_outlined, // Ícone apagado (outline)
            activeIcon: Icons.leaderboard, // Ícone preenchido quando ativo
            label: 'Investimentos',
            onTap: () {
              // Substitui a tela atual pela Home (sem empilhar no histórico)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(user: userModel),
                ),
              );
            },
          ),

          // Item 2: Startups (lista de startups disponíveis)
          _buildNavItem(
            context,
            index: 1,
            icon: Icons.rocket_launch_outlined,
            activeIcon: Icons.rocket_launch,
            label: 'Startups',
            onTap: () {
              // Navega para a lista de startups
              Navigator.push(
                context,
                MaterialPageRoute(
                  //builder: (context) => StartupsList(userModel: userModel),
                  builder: (context) => StartupsList(userModel: userModel),
                ),
              );
            },
          ),

          // Item 3: Balcão (tela de compra e venda)
          _buildNavItem(
            context,
            index: 2,
            icon: Icons.candlestick_chart_outlined,
            activeIcon: Icons.candlestick_chart,
            label: 'Balcão',
            onTap: () {
              // Navega para a tela de balcão (temporariamente usa NotificationPage)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
          ),

          // Item 4: Carteira (carteira do usuário)
          _buildNavItem(
            context,
            index: 3,
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet,
            label: 'Carteira',
            onTap: () {
              // TODO: Navegar para a tela de carteira
            },
          ),

          // Item 5: Perfil (dados do usuário)
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

  /// Constrói um item individual da barra de navegação
  /// [index] - Posição do item na barra (usado para verificar se é o ativo)
  /// [icon] - Ícone exibido quando o item NÃO está ativo (estilo outline)
  /// [activeIcon] - Ícone exibido quando o item ESTÁ ativo (estilo preenchido)
  /// [label] - Texto exibido abaixo do ícone
  /// [onTap] - Função chamada ao tocar no item (ignorada se já estiver na tela)
  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required VoidCallback onTap,
  }) {
    // Verifica se este item é o da tela atual
    final bool isActive = index == currentIndex;

    return GestureDetector(
      // Se já está na tela, não executa a navegação (onTap = null)
      onTap: isActive ? null : onTap,
      // Garante que a área de toque cobre toda a coluna, mesmo os espaços vazios
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Ocupa apenas o espaço necessário
        children: [
          // Container do ícone com fundo arredondado quando ativo (estilo Rico)
          Container(
            width: 44,
            height: 36,
            decoration: BoxDecoration(
              // Fundo branco quando ativo, transparente quando inativo
              color: isActive ? Colors.white : Colors.transparent,
              // Cantos arredondados para o efeito de "pílula" do estilo Rico
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                // Usa o ícone preenchido quando ativo, outline quando inativo
                isActive ? activeIcon : icon,
                // Ícone escuro quando ativo (contrasta com fundo branco), apagado quando inativo
                color: isActive ? const Color(0xFF1A1A2E) : Colors.white38,
                size: 22,
              ),
            ),
          ),
          // Espaçamento entre o ícone e o texto
          const SizedBox(height: 4),
          // Legenda do item de navegação
          Text(
            label,
            style: TextStyle(
              // Texto branco quando ativo, apagado quando inativo
              color: isActive ? Colors.white : Colors.white38,
              fontSize: 10,
              // Negrito quando ativo para dar mais destaque
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
