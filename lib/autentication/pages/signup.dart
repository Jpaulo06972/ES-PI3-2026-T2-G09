import 'package:flutter/material.dart';

// Componentes visuais do projeto
import 'package:mesclainvest_f/autentication/components/dateField.dart';
import '../components/emailField.dart';
import '../components/passwordField.dart';
import '../components/primaryButton.dart';
import '../components/navLink.dart';
import '../../components/textField.dart';
import '../components/cpfField.dart';
import '../components/phoneField.dart';
import '../components/socialButton.dart';
import '../components/successDialog.dart';

// Services
import '../services/signUpService.dart';

// Telas que a gente pode navegar a partir daqui
import 'signin.dart';

/// Tela de Cadastro do app.
/// O usuário preenche nome, CPF, data, telefone, e-mail e senha pra criar a conta.
/// Também dá pra se cadastrar direto pelo Google.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Chave do formulário pra validar tudo de uma vez
  final _formKey = GlobalKey<FormState>();

  // Cada campo tem seu controller pra guardar o que foi digitado
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _telefoneController = TextEditingController();

  // Controla o loading do botão (bolinha girando enquanto processa)
  bool _isLoading = false;

  @override
  void dispose() {
    // Sempre limpar os controllers quando a tela é destruída
    // pra não vazar memória
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cpfController.dispose();
    _dataNascimentoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  // Roda quando o usuário aperta "Concluir Cadastro"
  Future<void> _onSignUpPressed() async {
    if (_formKey.currentState!.validate()) {
      // Liga o loading
      setState(() => _isLoading = true);

      try {
        // Chama o service de cadastro
        final userModel = await SignUpService().signUp(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          dataNascimento: _dataNascimentoController.text.trim(),
          cpf: _cpfController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          telefone: _telefoneController.text.trim(),
        );

        // Cadastro deu certo — mostra o dialog de sucesso
        if (mounted && userModel != null) {
          await showSuccessDialog(
            context: context,
            title: 'Cadastro realizado!',
            message:
                'Sua conta foi criada com sucesso.\nBem-vindo(a) ao MesclaInvest!',
            buttonLabel: 'Começar',
            onPressed: () {
              Navigator.of(context).pop(); // Fecha o dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => SignInPage()),
                (route) => false, // Remove todas as telas anteriores
              );
            },
          );
        }
      } on SignUpException catch (e) {
        // Erro tratado — mostra mensagem amigável
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } finally {
        // Desliga o loading independente do resultado
        if (mounted) {
          setState(() => _isLoading = false);
        }
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
                // Logo e cabeçalho
                const SizedBox(height: 42),
                Image.asset('assets/images/Logo1.png', height: 45),
                const Text(
                  'Cadastre-se',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Preencha seus dados para começar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade300),
                ),
                const SizedBox(height: 16),

                // --- Dados pessoais ---

                // Nome e sobrenome lado a lado
                Row(
                  children: [
                    Expanded(
                      child: NameField(
                        controller: _firstNameController,
                        label: 'Nome',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NameField(
                        controller: _lastNameController,
                        label: 'Sobrenome',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                CpfField(controller: _cpfController),
                const SizedBox(height: 12),

                // Data e telefone cada um na sua linha pra caber o texto
                DateField(
                  controller: _dataNascimentoController,
                  label: 'Data de Nasc.',
                ),
                const SizedBox(height: 12),
                PhoneField(controller: _telefoneController, label: 'Telefone'),
                const SizedBox(height: 12),

                // --- Dados de acesso ---
                EmailField(controller: _emailController),
                const SizedBox(height: 12),
                PasswordField(
                  controller: _passwordController,
                  isCadastro: true,
                ),
                const SizedBox(height: 12),
                // Confirmar Senha - compara em tempo real com o campo de cima
                // O confirmController faz o erro "As senhas não são iguais"
                // aparecer/desaparecer enquanto o usuário digita
                PasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirmar Senha',
                  isCadastro: true,
                  confirmController: _passwordController,
                ),
                const SizedBox(height: 16),

                // --- Finalização ---

                // Botão com loading enquanto processa o cadastro
                PrimaryButton(
                  label: 'Concluir Cadastro',
                  onPressed: _onSignUpPressed,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 12),

                // Divisor com texto
                Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'cadastre com',
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 12),

                // Cadastro via Google
                SocialButton(
                  label: 'Cadastre-se com Google',
                  onPressed: () => debugPrint('Google login'),
                ),
                const SizedBox(height: 12),

                // Link pra quem já tem conta
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Já possui conta?'),
                    const SizedBox(width: 4),
                    NavLink(
                      label: 'Acesse aqui',
                      destination: const SignInPage(),
                    ),
                  ],
                ),

                // Espaço extra no final pra quando os erros de validação empurram
                // tudo pra baixo — garante que o link "Já possui conta?" fica acessível
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
