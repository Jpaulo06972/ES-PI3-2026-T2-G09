// Importa o pacote básico de UI do Flutter
import 'package:flutter/material.dart';

// Importa os componentes reutilizáveis do projeto
import '../components/emailField.dart';
import '../components/primaryButton.dart';
import '../components/navLink.dart';

// Importa o serviço que envia o código de recuperação por e-mail
import '../services/passwordResetService.dart';

// Importa a próxima tela do fluxo (onde o usuário digita o código recebido)
import 'passRecoveryCode.dart';

// Importa a tela de login para o link "Voltar para o login"
import 'signin.dart';

// Tela de recuperação de senha — primeiro passo do fluxo
// O usuário informa o e-mail e recebe um código de 6 dígitos
class PassRecoveryPage extends StatefulWidget {
  const PassRecoveryPage({super.key});

  // Cria o estado mutável desta tela
  @override
  State<PassRecoveryPage> createState() => _PassRecoveryPageState();
}

// Estado da tela de recuperação de senha
class _PassRecoveryPageState extends State<PassRecoveryPage> {
  // Chave do formulário — usada para validar o campo de e-mail
  final _formKey = GlobalKey<FormState>();

  // Controller que guarda o e-mail digitado pelo usuário
  final _emailController = TextEditingController();

  // Instância do serviço de reset de senha (comunica com o backend)
  final _service = PasswordResetService();

  // Controla se o botão está em estado de carregamento (bolinha girando)
  bool _isLoading = false;

  // Limpa o controller da memória quando sai da tela
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Função chamada ao pressionar "Enviar código"
  // Valida o e-mail, chama o serviço e navega para a tela de código
  Future<void> _onSendPressed() async {
    // Se o formulário não for válido (e-mail inválido), para aqui
    if (!_formKey.currentState!.validate()) return;

    // Liga o loading no botão
    setState(() => _isLoading = true);

    // Pega o e-mail digitado e remove espaços extras
    final email = _emailController.text.trim();

    try {
      // Chama o backend para enviar o código de recuperação por e-mail
      await _service.sendResetCode(email);

      // Verifica se a tela ainda existe (pode ter sido fechada durante a espera)
      if (!mounted) return;

      // Navega para a tela onde o usuário digita o código recebido
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PassRecoveryCodePage(email: email),
        ),
      );
    } on PasswordResetException catch (e) {
      // Se deu erro, mostra a mensagem amigável na parte inferior da tela
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      // Desliga o loading do botão, independente se deu certo ou erro
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Corpo da tela centralizado
      body: Center(
        child: SingleChildScrollView(
          // Padding lateral para o conteúdo não colar nas bordas
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            // Associa a chave do formulário para validação
            key: _formKey,
            child: Column(
              // Centraliza tudo verticalmente
              mainAxisAlignment: MainAxisAlignment.center,
              // Estica os filhos para ocupar toda a largura
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ícone de cadeado representando recuperação de senha
                Icon(
                  Icons.lock_reset_outlined,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),

                // Espaçamento entre o ícone e o título
                const SizedBox(height: 16),

                // Título da tela
                const Text(
                  'Recuperar senha',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                // Espaçamento entre o título e a instrução
                const SizedBox(height: 8),

                // Texto explicativo para o usuário
                Text(
                  'Informe seu e-mail e enviaremos um código de 6 dígitos para redefinir sua senha.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade300),
                ),

                // Espaçamento antes do campo de e-mail
                const SizedBox(height: 32),

                // Campo de e-mail com validação automática
                EmailField(controller: _emailController),

                // Espaçamento antes do botão
                const SizedBox(height: 32),

                // Botão "Enviar código" com estado de loading
                PrimaryButton(
                  label: 'Enviar código',
                  onPressed: _onSendPressed,
                  isLoading: _isLoading,
                ),

                // Espaçamento antes do link
                const SizedBox(height: 24),

                // Link para voltar à tela de login
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
