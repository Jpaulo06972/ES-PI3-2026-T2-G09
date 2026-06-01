// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote principal do Flutter para construção de interfaces (Material Design)
import 'package:flutter/material.dart';

// Componentes visuais reutilizáveis do projeto — cada um encapsula
// um campo de formulário com validação e formatação específica
import 'package:mesclainvest_f/autentication/components/dateField.dart';
import '../components/emailField.dart';
import '../components/passwordField.dart';
import '../components/primaryButton.dart';
import '../components/navLink.dart';
import '../../components/textField.dart'; // Campo de texto genérico (usado para nome e sobrenome)
import '../components/cpfField.dart'; // Campo com máscara e validação matemática do CPF
import '../components/phoneField.dart'; // Campo com máscara de telefone brasileiro
import '../../components/successDialog.dart'; // Dialog customizado de sucesso com animação

// Serviço que encapsula toda a lógica de cadastro (Firebase Auth + Firestore)
import '../services/signUpService.dart';

// Tela de login — para onde o usuário vai após cadastro bem-sucedido
import 'signin.dart';

/// Tela de Cadastro do app MesclaInvest.
/// O usuário preenche nome, CPF, data de nascimento, telefone, e-mail e senha
/// para criar sua conta. Cada campo tem validação própria (CPF verificado
/// matematicamente, senha com requisitos de força, idade mínima 18 anos, etc.).
/// É StatefulWidget porque precisa gerenciar múltiplos controllers e estado de loading.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  // Cria o estado mutável associado a esta tela
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

// Estado da tela de cadastro — contém controllers, validação e lógica de envio
class _SignUpPageState extends State<SignUpPage> {
  // Chave do formulário pra validar todos os 8 campos de uma vez
  // Quando o usuário clica "Concluir Cadastro", percorremos todos eles
  final _formKey = GlobalKey<FormState>();

  // Cada campo tem seu controller pra guardar o que foi digitado
  // Usamos controllers separados para poder ler os valores individualmente no envio
  final _firstNameController = TextEditingController(); // Nome
  final _lastNameController = TextEditingController(); // Sobrenome
  final _dataNascimentoController = TextEditingController(); // Data de nascimento (DD/MM/AAAA)
  final _cpfController = TextEditingController(); // CPF (com máscara 000.000.000-00)
  final _emailController = TextEditingController(); // E-mail
  final _passwordController = TextEditingController(); // Senha principal
  final _confirmPasswordController = TextEditingController(); // Confirmação de senha
  final _telefoneController = TextEditingController(); // Telefone (com máscara (00) 00000-0000)

  // Controla o loading do botão (bolinha girando enquanto processa)
  // Impede cliques duplos durante o envio ao Firebase
  bool _isLoading = false;

  @override
  void dispose() {
    // Sempre limpar os controllers quando a tela é destruída
    // pra não vazar memória — cada controller aloca recursos internos
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
  // É async porque faz chamadas ao Firebase (Auth + Firestore)
  Future<void> _onSignUpPressed() async {
    // Valida todos os campos do formulário simultaneamente
    // Se qualquer campo falhar, os erros são exibidos automaticamente
    if (_formKey.currentState!.validate()) {
      // Liga o loading — o botão vira bolinha girando
      setState(() => _isLoading = true);

      try {
        // Chama o service de cadastro que:
        // 1. Cria a conta no Firebase Auth (email + senha)
        // 2. Monta o UserModel com todos os dados pessoais
        // 3. Salva o perfil no Firestore (users/{uid})
        // O .trim() remove espaços acidentais no início e fim dos textos
        final userModel = await SignUpService().signUp(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          dataNascimento: _dataNascimentoController.text.trim(),
          cpf: _cpfController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text, // Senha não leva trim (espaços podem ser intencionais)
          telefone: _telefoneController.text.trim(),
        );

        // Cadastro deu certo — mostra o dialog de sucesso com animação
        if (mounted && userModel != null) {
          await showSuccessDialog(
            context: context,
            title: 'Cadastro realizado!',
            message:
                'Sua conta foi criada com sucesso.\nBem-vindo(a) ao MesclaInvest!',
            buttonLabel: 'Começar',
            onPressed: () {
              Navigator.of(context).pop(); // Fecha o dialog de sucesso
              // Navega para o login removendo TODAS as telas anteriores
              // Assim o usuário não pode voltar para o cadastro apertando "voltar"
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => SignInPage()),
                (route) => false, // Remove absolutamente todas as rotas
              );
            },
          );
        }
      } on SignUpException catch (e) {
        // Erro tratado pelo serviço (ex: e-mail já cadastrado, senha fraca)
        // Mostra mensagem amigável em português no SnackBar vermelho
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.message,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red.shade600, // Vermelho = erro
              behavior: SnackBarBehavior.floating, // Flutua acima do conteúdo
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } finally {
        // Desliga o loading independente do resultado (sucesso ou erro)
        // O finally garante que o botão nunca fique travado em loading eterno
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // Constrói toda a interface visual da tela de cadastro
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          // Scroll é essencial aqui porque temos muitos campos
          // e o teclado virtual ocupa metade da tela
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            // Form agrupa os campos e permite validar tudo com uma chamada
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo e cabeçalho — menor que na tela de login porque temos mais campos
                const SizedBox(height: 42), // Espaço no topo para respirar
                Image.asset('assets/images/Logo1.png', height: 45),

                // Título da tela
                const Text(
                  'Cadastre-se',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),

                // Subtítulo com instrução para o usuário
                Text(
                  'Preencha seus dados para começar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade300),
                ),
                const SizedBox(height: 16),

                // --- Seção: Dados pessoais ---

                // Nome e sobrenome lado a lado usando Row + Expanded
                // Expanded garante que cada campo ocupe exatamente metade da largura
                Row(
                  children: [
                    Expanded(
                      child: NameField(
                        controller: _firstNameController,
                        label: 'Nome',
                      ),
                    ),
                    const SizedBox(width: 12), // Espaço entre os campos
                    Expanded(
                      child: NameField(
                        controller: _lastNameController,
                        label: 'Sobrenome',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Campo de CPF com máscara automática (000.000.000-00)
                // e validação matemática usando algoritmo da Receita Federal
                CpfField(controller: _cpfController),
                const SizedBox(height: 12),

                // Campo de data que abre o calendário nativo ao tocar
                // Valida automaticamente se o usuário tem pelo menos 18 anos
                DateField(
                  controller: _dataNascimentoController,
                  label: 'Data de Nasc.',
                ),
                const SizedBox(height: 12),

                // Campo de telefone com máscara automática (00) 00000-0000
                // Aceita tanto fixo (10 dígitos) quanto celular (11 dígitos)
                PhoneField(controller: _telefoneController, label: 'Telefone'),
                const SizedBox(height: 12),

                // --- Seção: Dados de acesso ---

                // Campo de e-mail com validação básica (presença do @)
                EmailField(controller: _emailController),
                const SizedBox(height: 12),

                // Campo de senha com validação de força ativada (isCadastro: true)
                // Exige maiúscula, número, caractere especial e 6+ caracteres
                PasswordField(
                  controller: _passwordController,
                  isCadastro: true,
                ),
                const SizedBox(height: 12),

                // Campo de confirmação de senha — compara em tempo real com o campo acima
                // O confirmController faz o erro "As senhas não são iguais"
                // aparecer/desaparecer enquanto o usuário digita
                PasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirmar Senha',
                  isCadastro: true,
                  confirmController: _passwordController,
                ),
                const SizedBox(height: 16),

                // --- Seção: Finalização ---

                // Botão com loading enquanto processa o cadastro no Firebase
                PrimaryButton(
                  label: 'Concluir Cadastro',
                  onPressed: _onSignUpPressed,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 12),

                // Link pra quem já tem conta — leva de volta para o login
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
