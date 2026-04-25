// Importa o pacote básico de UI do Flutter
import 'package:flutter/material.dart';

// Importa o componente de cabeçalho personalizado
import 'package:mesclainvest_f/components/appBar.dart';

// Importa o componente de barra de navegação inferior personalizada
import 'package:mesclainvest_f/components/navBar.dart';

// Importa o modelo de usuário para acessar os dados do usuário logado
import 'package:mesclainvest_f/model/userModel.dart';

// Tela que exibirá a lista de startups disponíveis para investimento
class StartupsList extends StatelessWidget {
  // Dados do usuário logado, passados via construtor
  final UserModel userModel;

  // Construtor constante da tela de lista de startups
  const StartupsList({super.key, required this.userModel});

  @override
  Widget build(BuildContext context) {
    // Scaffold fornece a estrutura base da tela (cabeçalho, corpo e rodapé)
    return Scaffold(
      // Barra superior personalizada, exibindo as iniciais e opções de notificação
      appBar: CustomHeader(userModel: userModel),
      
      // Corpo da tela (conteúdo principal), atualmente centralizado com um texto provisório
      body: const Center(
        child: Text(
          'Em breve...', // Mensagem temporária enquanto a tela não é implementada
          style: TextStyle(color: Colors.white70, fontSize: 18), // Estilo visual do texto
        ),
      ),
      
      // Barra de navegação inferior, configurada para destacar o item "Startups" (índice 1)
      bottomNavigationBar: CustomNavBar(userModel: userModel, currentIndex: 1),
    );
  }
}
