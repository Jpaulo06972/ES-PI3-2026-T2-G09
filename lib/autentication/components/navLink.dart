import 'package:flutter/material.dart';

// Equivalente a <a href="..."><p>label</p></a>
// Navega para uma página ao ser clicado
class NavLink extends StatelessWidget {
  final String label;
  final Widget destination; // a página que vai abrir

  const NavLink({super.key, required this.label, required this.destination});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // onTap é usado para detectar cliques em elementos que normalmente não são botões
        // Empurra a nova página na pilha de navegação
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => destination),
        );
      },
      child: Text(
        label,
        style: TextStyle(
          // pega a cor primária do tema atual (funciona em dark e light)
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
