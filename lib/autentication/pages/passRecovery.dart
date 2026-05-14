import 'package:flutter/material.dart';

import '../components/emailField.dart';
import '../components/primaryButton.dart';
import '../components/navLink.dart';
import '../services/passwordResetService.dart';
import 'passRecoveryCode.dart';
import 'signin.dart';

class PassRecoveryPage extends StatefulWidget {
  const PassRecoveryPage({super.key});

  @override
  State<PassRecoveryPage> createState() => _PassRecoveryPageState();
}

class _PassRecoveryPageState extends State<PassRecoveryPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _service = PasswordResetService();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSendPressed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();

    try {
      await _service.sendResetCode(email);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PassRecoveryCodePage(email: email),
        ),
      );
    } on PasswordResetException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.lock_reset_outlined,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Recuperar senha',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Informe seu e-mail e enviaremos um código de 6 dígitos para redefinir sua senha.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade300),
                ),
                const SizedBox(height: 32),
                EmailField(controller: _emailController),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Enviar código',
                  onPressed: _onSendPressed,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),
                NavLink(
                  destination: const SignInPage(),
                  label: 'Voltar para o login',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
