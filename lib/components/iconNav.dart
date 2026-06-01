// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote básico de UI do Flutter
import 'package:flutter/material.dart';

// Importa o modelo de usuário para permitir a passagem de dados entre telas
import 'package:mesclainvest_f/model/userModel.dart';

/// Componente reutilizável que encapsula um botão de ícone com navegação embutida.
///
/// A ideia aqui é simples: ao invés de repetir o código de Navigator.push
/// em vários lugares do app, criamos um único widget que já cuida de tudo.
/// Você passa o ícone, a tela de destino e o usuário — ele resolve a navegação.
/// Isso segue o princípio DRY (Don't Repeat Yourself) e facilita a manutenção.
class IconNav extends StatelessWidget {
  // O ícone que será exibido como botão (ex: Icons.settings, Icons.person)
  final IconData icon;

  // Função que constrói a tela de destino.
  // Recebe o UserModel como parâmetro nomeado obrigatório para que a tela
  // de destino sempre tenha acesso aos dados do usuário logado.
  // Esse padrão de "builder function" é poderoso porque permite
  // navegar para qualquer tela sem que este widget precise conhecê-la previamente.
  final Widget Function({required UserModel userModel}) destination;

  // Dados do usuário logado que serão repassados para a tela de destino
  final UserModel userModel;

  // Construtor exige todos os campos para garantir que o componente
  // nunca seja usado sem as informações necessárias para funcionar
  const IconNav({
    super.key,
    required this.icon,
    required this.destination,
    required this.userModel,
  });

  @override
  Widget build(BuildContext context) {
    // IconButton é o widget padrão do Material Design para botões com ícone.
    // Ele já cuida do feedback visual (ripple) e do tamanho mínimo de toque.
    return IconButton(
      // Renderiza o ícone passado como parâmetro
      icon: Icon(icon),
      // Cor branca para garantir contraste visual em fundos escuros
      color: Colors.white,
      // Tamanho padrão que fica confortável na barra do app
      iconSize: 28,
      // Ao pressionar: empurra a tela de destino sobre a pilha de navegação.
      // MaterialPageRoute cria a animação de transição padrão (slide da direita)
      // e passa o userModel para que a tela destino tenha acesso aos dados do usuário
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destination(userModel: userModel)),
      ),
    );
  }
}
