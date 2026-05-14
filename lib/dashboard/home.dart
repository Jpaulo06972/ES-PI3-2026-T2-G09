import 'package:flutter/material.dart';
import 'package:mesclainvest_f/model/userModel.dart';

class HomePage extends StatelessWidget {
  final UserModel user;

  const HomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        automaticallyImplyLeading: false, // Remove o botão de voltar
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bem-vindo, ${user.fullName}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              user.email,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
