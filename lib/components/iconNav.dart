// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote básico de UI do Flutter
import 'package:flutter/material.dart';

// Importa o modelo de usuário para permitir a passagem de dados entre telas
import 'package:mesclainvest_f/model/userModel.dart';

// Um componente reutilizável que cria um botão de ícone com navegação acoplada
class IconNav extends StatelessWidget {
  // O ícone que será exibido no botão
  final IconData icon;

  // Função que constrói a tela de destino, exigindo que o UserModel seja passado para ela
  final Widget Function({required UserModel userModel}) destination;

  // Os dados do usuário logado que serão passados para a tela de destino
  final UserModel userModel;

  // Construtor do componente, exigindo todos os parâmetros para funcionar corretamente
  const IconNav({
    super.key,
    required this.icon,
    required this.destination,
    required this.userModel,
  });

  @override
  Widget build(BuildContext context) {
    // Retorna um botão de ícone clicável
    return IconButton(
      // Define o ícone a ser exibido
      icon: Icon(icon),
      // Define a cor do ícone como branca para contrastar com o fundo escuro
      color: Colors.white,
      // Define o tamanho padrão do ícone
      iconSize: 28,
      // Quando o botão for pressionado, navega para a tela de destino
      onPressed: () => Navigator.push(
        context,
        // Constrói a rota material para a tela de destino, passando o userModel para ela
        MaterialPageRoute(builder: (_) => destination(userModel: userModel)),
      ),
    );
  }
}
