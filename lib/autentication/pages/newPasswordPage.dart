import 'package:flutter/material.dart';

import '../components/passwordField.dart';
import '../components/primaryButton.dart';
import '../services/passwordResetService.dart';
import 'signin.dart';

class NewPasswordPage extends StatefulWidget {
  final String email;
  final String code;

  const NewPasswordPage({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _service = PasswordResetService();

  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onConfirmPressed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _service.resetPassword(
        email: widget.email,
        code: widget.code,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha redefinida com sucesso!')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignInPage()),
        (route) => false,
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
                  Icons.lock_outline,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nova senha',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Crie uma senha forte para sua conta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade300),
                ),
                const SizedBox(height: 32),
                PasswordField(
                  controller: _passwordController,
                  label: 'Nova senha',
                  isCadastro: true,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _confirmController,
                  label: 'Confirmar nova senha',
                  isCadastro: true,
                  confirmController: _passwordController,
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Redefinir senha',
                  onPressed: _onConfirmPressed,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
