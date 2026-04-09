import 'package:flutter/material.dart';
import '../../dashboard/home.dart';
import 'signin.dart'; // Importa a página de Login para conseguirmos voltar

// Importando os componentes visuais
import '../components/emailField.dart';
import '../components/passwordField.dart';
import '../components/primaryButton.dart';
import '../components/navLink.dart'; // Importa o nosso NavLink customizado!
import '../components/nameField.dart';
import '../components/cpfField.dart';

// Transformamos a SignUpPage em um StatefulWidget para que ela
// consiga conversar com a classe de estado logo abaixo!
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // O famoso "Controle Remoto" (Key) para autorizar e validar o formulário
  final _formKey = GlobalKey<FormState>();

  // Cadernos para anotar o Nome e Sobrenome
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  // Caderno para anotar a Data de Nascimento
  final _dataNascimentoController = TextEditingController();
  final _cpfController = TextEditingController();

  // Caderno para anotar o Email
  final _emailController = TextEditingController();

  // Cadernos para anotar e conferir se as duas senhas são idênticas
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _telefoneController = TextEditingController();

  @override
  void dispose() {
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

  void _onSignUpPressed() {
    // Quando apertar em Cadastrar, ele valida o Form primeiro
    if (_formKey.currentState!.validate()) {
      final firstName = _firstNameController.text;
      final lastName = _lastNameController.text;
      final dataNascimento = _dataNascimentoController.text;
      final cpf = _cpfController.text;
      final email = _emailController.text;
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;
      final telefone = _telefoneController.text;

      debugPrint('Nome: $firstName');
      debugPrint('Sobrenome: $lastName');
      debugPrint('Data de Nascimento: $dataNascimento');
      debugPrint('CPF: $cpf');
      debugPrint('Email: $email');
      debugPrint('Senha: $password');
      debugPrint('Confirmar Senha: $confirmPassword');
      debugPrint('Telefone: $telefone');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  // O método Build constrói a tela.
  // Semelhante ao Login, usamos Scaffold, SingleChildScrollView e Form.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey, // O controle remoto conectado à TV!
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('assets/images/Logo1.png', height: 80),
                const SizedBox(height: 16),

                const Text(
                  'Crie sua conta',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                // Usamos Row com Expanded para colocar Nome e Sobrenome lado a lado
                Row(
                  children: [
                    Expanded(
                      child: NameField(
                        controller: _firstNameController,
                        label: 'Nome',
                      ),
                    ),
                    const SizedBox(width: 16), // Espaço entre nome e sobrenome
                    Expanded(
                      child: NameField(
                        controller: _lastNameController,
                        label: 'Sobrenome',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Campo CPF
                CpfField(
                  controller: _cpfController,
                ),
                const SizedBox(height: 16),

                // Fileira com Data de Nascimento e Telefone
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dataNascimentoController,
                        keyboardType: TextInputType.datetime,
                        decoration: const InputDecoration(
                          labelText: 'Data de Nasc.',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'w' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _telefoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Divisor visual para separar dados pessoais dos dados de acesso
                const Divider(height: 32),
                const Text(
                  'Dados de Acesso',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),

                // Nossos componentes originais puxados de outros arquivos:
                EmailField(controller: _emailController),
                const SizedBox(height: 16),

                // Senha e Confirmar Senha (ativando o modo isCadastro do seu componente!)
                PasswordField(
                  controller: _passwordController,
                  isCadastro: true,
                ),
                const SizedBox(height: 16),

                PasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirmar Senha', // Substitui o nome do campo
                  isCadastro: true,
                ),
                const SizedBox(height: 32),

                // O botão de cadastro conectado na nossa função
                PrimaryButton(
                  label: 'Concluir Cadastro',
                  onPressed: _onSignUpPressed,
                ),

                const SizedBox(height: 16),

                // NavLink para o usuário que já tem conta (Substituindo o antigo TextButton)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Já possui conta?'),
                    const SizedBox(width: 4),
                    NavLink(
                      label: 'Acesse aqui',
                      destination:
                          const SignInPage(), // <-- Precisaremos importar lá no topo!
                    ),
                  ],
                ),

                // Espaço extra no final para o scroll não colar no pé da tela
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
