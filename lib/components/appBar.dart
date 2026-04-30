// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote do Flutter com os widgets e ferramentas de interface
import 'package:flutter/material.dart';

// Importa o modelo de dados do usuário para acessar nome e informações
import 'package:mesclainvest_f/model/userModel.dart';

// Importa a página de notificações para navegação
import 'package:mesclainvest_f/dashboard/pages/notification.dart';

// Cabeçalho personalizado do app, exibido no topo de todas as telas do dashboard
// Mostra o avatar do usuário, seu nome e o ícone de notificações
class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  // Dados do usuário logado, usados para exibir nome e iniciais
  final UserModel userModel;

  // Construtor que recebe obrigatoriamente os dados do usuário
  const CustomHeader({super.key, required this.userModel});

  // Função chamada ao clicar no ícone de notificação
  // Navega para a tela de notificações usando push (empilha na navegação)
  Future<void> _onSendPressed(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationPage()),
    );
  }

  // Pega a primeira letra do nome do usuário para usar como avatar
  // Se o nome estiver vazio, usa "U" como padrão
  String _getInitials() {
    return userModel.firstName.isNotEmpty
        ? userModel.firstName[0].toUpperCase()
        : 'U';
  }

  @override
  Widget build(BuildContext context) {
    // Container principal do cabeçalho com padding que respeita a barra de status
    return Container(
      padding: EdgeInsets.only(
        // Soma a altura da barra de status do celular (notch, câmera, etc.) + espaçamento extra
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 16,
        // Padding esquerdo alinhado com o conteúdo da tela
        left: 14,
        // Padding direito que posiciona o ícone de notificação um pouco para dentro
        right: 16,
      ),
      // Fundo transparente para herdar a cor do tema
      decoration: const BoxDecoration(color: Colors.transparent),
      // Linha horizontal com avatar, nome e ícone de notificação
      child: Row(
        // Alinha todos os itens no centro vertical da linha
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar circular com a inicial do nome do usuário
          Container(
            width: 40,
            height: 40,
            // Círculo cinza escuro como fundo do avatar
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3A),
              borderRadius: BorderRadius.circular(20),
            ),
            // Centraliza a letra dentro do círculo
            child: Center(
              child: Text(
                _getInitials(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // Espaçamento entre o avatar e o nome
          const SizedBox(width: 10),

          // Nome do usuário — Expanded faz ele ocupar todo o espaço disponível
          // Se o nome for muito grande, corta com "..." (ellipsis)
          Expanded(
            child: Text(
              '${userModel.firstName.isNotEmpty ? userModel.firstName : 'Usuário'}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Espaçamento entre o nome e o ícone de notificação
          const SizedBox(width: 12),

          // Botão circular de notificações
          Container(
            width: 40,
            height: 40,
            // Círculo cinza escuro como fundo do botão
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3A),
              borderRadius: BorderRadius.circular(20),
            ),
            // Material + InkWell cria o efeito visual de "ripple" ao tocar
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.hardEdge,
              child: InkWell(
                // Ao tocar, abre a tela de notificações
                onTap: () => _onSendPressed(context),
                child: const Center(
                  // Ícone de sino (notificações) em branco
                  child: Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Define a altura fixa que o cabeçalho ocupa no topo da tela
  // Isso é necessário porque implementamos PreferredSizeWidget
  @override
  Size get preferredSize => const Size.fromHeight(100.0);
}
