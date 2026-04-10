// Importa o pacote principal do Flutter (Material Design)
import 'package:flutter/material.dart';

// Importa o componente de campo de data de nascimento
import 'package:mesclainvest_f/autentication/components/dateField.dart';

// Importa a tela do dashboard (para onde vamos após o cadastro)
import '../../dashboard/home.dart';

// Importa a página de Login para o link "Já possui conta?"
import 'signin.dart';

// Importando os componentes visuais reutilizáveis
import '../components/emailField.dart';
import '../components/passwordField.dart';
import '../components/primaryButton.dart';
import '../components/navLink.dart';
import '../components/nameField.dart';
import '../components/cpfField.dart';
import '../components/phoneField.dart';

// -----------------------------------------------------------------------------
// Página de Cadastro (Sign Up)
// É um StatefulWidget porque tem campos de texto com controladores,
// ou seja, tem "coisas que mudam" (estado) conforme o usuário preenche.
// -----------------------------------------------------------------------------
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  // Conecta a casca (StatefulWidget) com o cérebro (State) logo abaixo
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

// -----------------------------------------------------------------------------
// Estado da página — aqui fica toda a lógica e o visual do cadastro
// -----------------------------------------------------------------------------
class _SignUpPageState extends State<SignUpPage> {
  // O "controle remoto" do formulário.
  // Quando apertamos _formKey.currentState!.validate(), ele percorre
  // TODOS os campos que estão dentro do Form e chama o validator de cada um.
  final _formKey = GlobalKey<FormState>();

  // ---------------------------------------------------------------------------
  // Controllers (cadernos) — cada campo de texto tem o seu.
  // Eles guardam na memória o que o usuário digita, permitindo que a gente
  // leia o valor depois (ex: _firstNameController.text retorna "João").
  // ---------------------------------------------------------------------------
  final _firstNameController = TextEditingController();   // Nome
  final _lastNameController = TextEditingController();    // Sobrenome
  final _dataNascimentoController = TextEditingController(); // Data de nascimento
  final _cpfController = TextEditingController();         // CPF
  final _emailController = TextEditingController();       // E-mail
  final _passwordController = TextEditingController();    // Senha
  final _confirmPasswordController = TextEditingController(); // Confirmar senha
  final _telefoneController = TextEditingController();    // Telefone

  // ---------------------------------------------------------------------------
  // dispose() — Chamado quando a tela é destruída (saiu da página).
  // Obrigatório liberar os controllers da memória para evitar vazamento (memory leak).
  // Pense nisso como "desligar os gravadores" quando não precisa mais deles.
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Função chamada quando o usuário aperta o botão "Concluir Cadastro".
  // Primeiro valida todos os campos, depois verifica se as senhas batem,
  // e finalmente navega para a HomePage.
  // ---------------------------------------------------------------------------
  void _onSignUpPressed() {
    // Aperta o "validate" no controle remoto — cada campo verifica suas regras
    if (_formKey.currentState!.validate()) {
      // Lê o texto de todos os controllers (cadernos) e salva em variáveis locais
      final firstName = _firstNameController.text;
      final lastName = _lastNameController.text;
      final dataNascimento = _dataNascimentoController.text;
      final cpf = _cpfController.text;
      final email = _emailController.text;
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;
      final telefone = _telefoneController.text;

      // Verifica se a senha e a confirmação de senha são iguais
      if (password != confirmPassword) {
        // Se forem diferentes, mostra um SnackBar (barrinha de aviso no rodapé)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('As senhas não são iguais')),
        );
        // Retorna sem continuar — o cadastro NÃO é finalizado
        return;
      }

      // ---------------------------------------------------------------
      // RETIRAR DEPOIS AQUI: Exibição dos dados no console (apenas para debug)
      debugPrint('Nome: $firstName');
      debugPrint('Sobrenome: $lastName');
      debugPrint('Data de Nascimento: $dataNascimento');
      debugPrint('CPF: $cpf');
      debugPrint('Email: $email');
      debugPrint('Senha: $password');
      debugPrint('Confirmar Senha: $confirmPassword');
      debugPrint('Telefone: $telefone');
      // ---------------------------------------------------------------

      // Navega para a HomePage após o cadastro ser concluído com sucesso
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // build() — Constrói a parte visual da tela de cadastro.
  // Estrutura: Scaffold > Center > SingleChildScrollView > Form > Column
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold = estrutura base de uma tela (chão, parede e teto)
      body: Center(
        // Center = centraliza tudo na tela
        child: SingleChildScrollView(
          // SingleChildScrollView = permite rolar a tela quando o teclado abre
          // ou quando o conteúdo é maior que a tela
          padding: const EdgeInsets.symmetric(horizontal: 32),

          child: Form(
            // Form = "caixa mestre" que agrupa todos os campos e permite validar
            // todos de uma vez com o controle remoto (_formKey)
            key: _formKey,

            child: Column(
              // Column = empilha os widgets de cima para baixo
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch, // Estica até as bordas laterais
              children: [

                // Logo do app no topo
                Image.asset('assets/images/Logo1.png', height: 80),
                const SizedBox(height: 16), // Espaço entre a logo e o título

                // Título da página
                const Text(
                  'Crie sua conta',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 40), // Espaço maior antes dos campos

                // =========================================================
                // SEÇÃO 1: Dados Pessoais
                // =========================================================

                // Nome e Sobrenome lado a lado usando Row + Expanded
                // Row = coloca filhos lado a lado (horizontal)
                // Expanded = cada filho ocupa metade do espaço disponível
                Row(
                  children: [
                    Expanded(
                      child: NameField(
                        controller: _firstNameController,
                        label: 'Nome',
                      ),
                    ),
                    const SizedBox(width: 16), // Espaço entre os dois campos
                    Expanded(
                      child: NameField(
                        controller: _lastNameController,
                        label: 'Sobrenome',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Campo de CPF com formatação automática (XXX.XXX.XXX-XX)
                CpfField(controller: _cpfController),
                const SizedBox(height: 16),

                // Data de Nascimento e Telefone lado a lado (mesmo esquema do Nome/Sobrenome)
                Row(
                  children: [
                    Expanded(
                      child: DateField(
                        controller: _dataNascimentoController,
                        label: 'Data de Nasc.',
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: PhoneField(
                        controller: _telefoneController,
                        label: 'Telefone',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // =========================================================
                // SEÇÃO 2: Dados de Acesso
                // =========================================================

                // Linha horizontal para separar visualmente as duas seções
                const Divider(height: 32),

                // Subtítulo da seção
                const Text(
                  'Dados de Acesso',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 16),

                // Campo de e-mail com validação de @ e campo obrigatório
                EmailField(controller: _emailController),
                const SizedBox(height: 16),

                // Campo de senha com olhinho para mostrar/esconder
                // isCadastro: true ativa validações extras (mínimo de caracteres, etc.)
                PasswordField(
                  controller: _passwordController,
                  isCadastro: true,
                ),
                const SizedBox(height: 16),

                // Campo de confirmar senha (mesmo componente, label diferente)
                PasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirmar Senha',
                  isCadastro: true,
                ),
                const SizedBox(height: 32),

                // =========================================================
                // BOTÃO E LINK
                // =========================================================

                // Botão principal que dispara a função _onSignUpPressed
                PrimaryButton(
                  label: 'Concluir Cadastro',
                  onPressed: _onSignUpPressed,
                ),

                const SizedBox(height: 16),

                // Link "Já possui conta? Acesse aqui" para voltar ao login
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
