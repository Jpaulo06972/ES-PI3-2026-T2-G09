import 'package:flutter/material.dart';

// Componentes visuais do nosso projeto
import '../components/emailField.dart';
import '../components/passwordField.dart';
import '../components/navLink.dart';
import '../components/primaryButton.dart';
import '../components/socialButton.dart';

// Telas que a gente navega a partir daqui
import '../../dashboard/home.dart';
import 'passRecovery.dart';
import 'signup.dart';

/// Tela de Login do app.
/// Aqui o usuário digita e-mail e senha pra entrar na conta dele.
/// Também tem opção de entrar com Google, recuperar senha ou criar conta nova.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  // Chave do formulário — usamos pra validar todos os campos de uma vez
  final _formKey = GlobalKey<FormState>();

  // Controllers guardam o que o usuário tá digitando em cada campo
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Controla o estado de loading do botão
  // Quando tá true, o botão mostra uma bolinha girando e bloqueia novos cliques
  bool _isLoading = false;

  // Limpa os controllers da memória quando sai da tela
  // Se não fizer isso, eles ficam ocupando espaço à toa (memory leak)
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Roda quando o usuário aperta "Entrar"
  // É async porque simula uma espera (como se tivesse chamando a API)
  Future<void> _onSigInPressed() async {
    if (_formKey.currentState!.validate()) {
      // Liga o loading (bolinha girando no botão)
      setState(() => _isLoading = true);

      // Simula um tempo de espera como se fosse uma chamada de API
      // Quando integrar com o backend, troca esse delay pela chamada real
      await Future.delayed(const Duration(milliseconds: 1500));

      final email = _emailController.text;
      final password = _passwordController.text;

      // Por enquanto tá com credencial fixa pra teste
      if (email == "Teste@gmail.com" && password == "teste@123456") {
        // Desliga o loading antes de navegar
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else {
        // Desliga o loading e mostra erro
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('E-mail ou senha incorretos')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          // Scroll pra quando o teclado abrir não empurrar tudo
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo do app
                Image.asset('assets/images/Logo1.png', height: 80),
                const SizedBox(height: 8),

                // Título e subtítulo
                const Text(
                  'Bem-vindo de volta',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Faça o login na sua conta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),

                // Campos de e-mail e senha
                EmailField(controller: _emailController),
                const SizedBox(height: 16),

                PasswordField(controller: _passwordController),
                const SizedBox(height: 32),

                // Botão principal (com loading enquanto processa)
                PrimaryButton(
                  label: 'Entrar',
                  onPressed: _onSigInPressed,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),

                // Linha divisória com texto "entre com"
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'entre com',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // Botão de login com Google
                SocialButton(
                  label: 'Entrar com Google',
                  onPressed: () {
                    // TODO: integrar com Firebase/Google Sign-In
                    debugPrint('Google login acionado');
                  },
                ),

                const SizedBox(height: 24),

                // Link pra recuperar senha
                NavLink(
                  label: 'Esqueci minha senha',
                  destination: const PassRecoveryPage(),
                ),

                const SizedBox(height: 16),

                // Link pra criar conta nova
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Não tem conta?'),
                    const SizedBox(width: 4),
                    NavLink(
                      label: 'Cadastre-se',
                      destination: const SignUpPage(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
