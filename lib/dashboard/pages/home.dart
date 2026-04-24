import 'package:flutter/material.dart';
import 'package:mesclainvest_f/dashboard/components/appBar.dart';
import 'package:mesclainvest_f/model/userModel.dart';

class HomePage extends StatefulWidget {
  final UserModel user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState(userModel: user);
}

class _HomePageState extends State<HomePage> {
  final UserModel userModel;

  _HomePageState({required this.userModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomHeader(userModel: userModel),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bem-vindo, ${userModel.fullName}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              userModel.email,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
