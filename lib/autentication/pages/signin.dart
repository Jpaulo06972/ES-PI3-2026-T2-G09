import 'package:flutter/material.dart';
import '../components/email_field.dart';
import '../components/password_field.dart';
import '../components/nav_link.dart';
import '../components/primary_button.dart';
import 'passRecovery.dart';
import 'signup.dart';

// Tela de Login — StatefulWidget porque precisa controlar
// o estado dos campos (ex: mostrar/ocultar senha)
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  // Chave que identifica o formulário e permite validá-lo
  final _formKey = GlobalKey<FormState>();

  // Controllers capturam o texto digitado nos campos
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    // Sempre liberar controllers para evitar memory leak
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Função chamada ao pressionar "Entrar"
  void _onLoginPressed() {
    // Valida todos os campos do Form antes de prosseguir
    if (_formKey.currentState!.validate()) {
      // TODO: integrar com backend de autenticação
      final email = _emailController.text;
      final password = _passwordController.text;

      debugPrint('Email: $email | Senha: $password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Center(
        child: SingleChildScrollView(
          // Permite rolar quando o teclado sobe
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo / título do app
                Image.asset('assets/images/Logo1.png', height: 80),
                const SizedBox(height: 16),
                const Text(
                  'Bem-vindo de volta',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                // ANTES — campo escrito direto aqui (sem componente):
                // TextFormField(
                //   controller: _emailController,
                //   keyboardType: TextInputType.emailAddress,
                //   decoration: InputDecoration(labelText: 'E-mail', ...),
                //   validator: (value) { ... },
                // ),

                // DEPOIS — usando o componente importado lá do topo
                // é como um <EmailField controller={_emailController} /> no React
                EmailField(controller: _emailController),
                const SizedBox(height: 16),

                // Campo de senha — componente reutilizável
                PasswordField(controller: _passwordController),
                const SizedBox(height: 20),

                // NavLink: label e destino customizados via props
                Align(
                  alignment: Alignment.center,
                  child: NavLink(
                    label: 'Esqueci minha senha',
                    destination: const PassRecoveryPage(),
                  ),
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 24),

                PrimaryButton(
                  label: 'Entrar',
                  onPressed: _onLoginPressed,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
