// Importa o pacote básico de UI do Flutter
import 'package:flutter/material.dart';
// Importa componentes reutilizáveis
import '../components/passwordField.dart';
import '../components/primaryButton.dart';
// Importa o serviço de reset e a tela de login
import '../services/passwordResetService.dart';
import 'signin.dart';

// Tela onde o usuário cria a nova senha — último passo do fluxo de recuperação
// Recebe o e-mail e o código verificado das telas anteriores
class NewPasswordPage extends StatefulWidget {
  // E-mail do usuário que está redefinindo a senha
  final String email;
  // Código de 6 dígitos que foi verificado na tela anterior
  final String code;

  const NewPasswordPage({super.key, required this.email, required this.code});

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

// Estado da tela de nova senha
class _NewPasswordPageState extends State<NewPasswordPage> {
  // Chave do formulário para validar os campos de senha
  final _formKey = GlobalKey<FormState>();
  // Controller da nova senha
  final _passwordController = TextEditingController();
  // Controller da confirmação de senha
  final _confirmController = TextEditingController();
  // Serviço que comunica com o backend para redefinir a senha
  final _service = PasswordResetService();
  // Controla o loading do botão
  bool _isLoading = false;

  // Limpa os controllers ao sair da tela
  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Ao pressionar "Redefinir senha" — valida, chama o backend e redireciona ao login
  Future<void> _onConfirmPressed() async {
    // Se os campos não são válidos, para aqui
    if (!_formKey.currentState!.validate()) return;

    // Liga o loading
    setState(() => _isLoading = true);

    try {
      // Chama o backend passando e-mail, código e a nova senha
      await _service.resetPassword(
        email: widget.email,
        code: widget.code,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      // Mostra mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha redefinida com sucesso!')),
      );

      // Redireciona para o login removendo todas as telas anteriores da pilha
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignInPage()),
        (route) => false,
      );
    } on PasswordResetException catch (e) {
      // Se deu erro, mostra a mensagem amigável
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      // Desliga o loading
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
                // Ícone de cadeado
                Icon(Icons.lock_outline, size: 72, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                // Título
                const Text('Nova senha', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                // Instrução
                Text('Crie uma senha forte para sua conta.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade300)),
                const SizedBox(height: 32),
                // Campo de nova senha com validação de força
                PasswordField(controller: _passwordController, label: 'Nova senha', isCadastro: true),
                const SizedBox(height: 16),
                // Campo de confirmação — compara com o campo acima em tempo real
                PasswordField(controller: _confirmController, label: 'Confirmar nova senha', isCadastro: true, confirmController: _passwordController),
                const SizedBox(height: 32),
                // Botão "Redefinir senha" com loading
                PrimaryButton(label: 'Redefinir senha', onPressed: _onConfirmPressed, isLoading: _isLoading),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
