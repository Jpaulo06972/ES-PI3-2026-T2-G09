import 'package:flutter/material.dart';

// Componentes e telas usadas aqui
import '../components/emailField.dart';
import '../components/primaryButton.dart';
import '../components/navLink.dart';
import 'passRecoveryCode.dart';
import 'signin.dart';

/// Tela de recuperação de senha.
/// O usuário digita o e-mail e a gente manda um código pra ele redefinir a senha.
class PassRecoveryPage extends StatefulWidget {
  const PassRecoveryPage({super.key});

  @override
  State<PassRecoveryPage> createState() => _PassRecoveryPageState();
}

class _PassRecoveryPageState extends State<PassRecoveryPage> {
  // Chave pra validar o formulário
  final _formKey = GlobalKey<FormState>();

  // Controller do campo de e-mail
  final _emailController = TextEditingController();

  // Controla o loading do botão
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Roda quando o usuário clica em "Enviar link"
  Future<void> _onSendPressed() async {
    if (_formKey.currentState!.validate()) {
      // Liga o loading
      setState(() => _isLoading = true);

      // Simula espera da API
      await Future.delayed(const Duration(milliseconds: 1500));

      final email = _emailController.text;
      debugPrint('Solicitação de recuperação para: $email');

      // Avisa o usuário e navega pra tela de código
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Link de recuperação enviado para: $email')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PassRecoveryCodePage()),
        );
      }
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
                // Ícone de cadeado
                Icon(
                  Icons.lock_reset_outlined,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),

                // Título
                const Text(
                  'Recuperar senha',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Instrução pro usuário
                const Text(
                  'Informe seu e-mail e enviaremos um link para redefinir sua senha.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Campo de e-mail
                EmailField(controller: _emailController),
                const SizedBox(height: 32),

                // Botão com loading enquanto envia
                PrimaryButton(
                  label: 'Enviar link',
                  onPressed: _onSendPressed,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),

                // Voltar pro login
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
