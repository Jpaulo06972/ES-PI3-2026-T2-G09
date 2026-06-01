// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote principal do Flutter para construção de interfaces (Material Design)
import 'package:flutter/material.dart';

// Componentes visuais reutilizáveis do nosso projeto
// Cada um encapsula um campo ou elemento de UI com validação e estilo padrão
import '../components/emailField.dart';
import '../components/passwordField.dart';
import '../components/navLink.dart';
import '../components/primaryButton.dart';

// Telas que a gente navega a partir daqui dependendo da ação do usuário
import '../../dashboard/pages/home.dart'; // Tela principal após login bem-sucedido
import 'passRecovery.dart'; // Fluxo de recuperação de senha
import 'signup.dart'; // Tela de cadastro para novos usuários
import 'twoFactsAuth.dart'; // Tela de autenticação em dois fatores (2FA)

// Serviço que cuida da lógica de autenticação (Firebase Auth + Firestore)
import '../services/SignInServices.dart';

/// Tela de Login do app MesclaInvest.
/// Aqui o usuário digita e-mail e senha pra entrar na conta dele.
/// Também tem opção de recuperar senha ou criar conta nova.
/// É StatefulWidget porque precisa gerenciar estados mutáveis como loading e controllers.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  // Cria o estado mutável associado a esta tela
  @override
  State<SignInPage> createState() => _SignInPageState();
}

// Estado da tela de login — contém toda a lógica interativa e os dados temporários
class _SignInPageState extends State<SignInPage> {
  // Chave do formulário — usamos pra validar todos os campos de uma vez
  // Quando chamamos _formKey.currentState!.validate(), ele percorre todos os TextFormFields
  final _formKey = GlobalKey<FormState>();

  // Controllers guardam o que o usuário tá digitando em cada campo
  // São como "cadernos" que anotam cada tecla pressionada
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Controla o estado de loading do botão
  // Quando tá true, o botão mostra uma bolinha girando e bloqueia novos cliques
  // Isso evita que o usuário envie o formulário duas vezes sem querer
  bool _isLoading = false;

  // Limpa os controllers da memória quando sai da tela
  // Se não fizer isso, eles ficam ocupando espaço à toa (memory leak)
  // O Flutter chama esse método automaticamente quando o widget é removido da árvore
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Roda quando o usuário aperta "Entrar"
  // É async porque faz chamada ao Firebase, que é uma operação de rede (assíncrona)
  Future<void> _onSigInPressed() async {
    // Valida todos os campos do formulário de uma vez
    // Se algum campo não passar na validação, para aqui e mostra os erros
    if (_formKey.currentState!.validate()) {
      // Liga o loading (bolinha girando no botão)
      setState(() => _isLoading = true);

      // Captura os valores dos campos antes de fazer a chamada assíncrona
      final email = _emailController.text;
      final password = _passwordController.text;

      try {
        // Chama o serviço de autenticação que faz login no Firebase Auth
        // e busca os dados completos do perfil no Firestore
        final user = await SignInService().signIn(
          email: email,
          password: password,
        );

        // Se o login deu certo e retornou um usuário válido
        if (user != null) {
          // mounted verifica se a tela ainda está na pilha de navegação
          // Isso é necessário porque a tela pode ter sido descartada
          // enquanto aguardava a resposta do Firebase
          if (mounted) {
            // Decide para onde navegar: se o usuário tem 2FA ativado,
            // vai para a tela de verificação; senão, vai direto pro dashboard
            final destination = user.twoFactorEnabled
                ? TwoFactsAuthPage(userModel: user)
                : HomePage(user: user);

            // pushReplacement substitui a tela atual pela nova
            // Assim o usuário não pode voltar para a tela de login apertando "voltar"
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => destination),
            );
          }
        }
      } on SignInException catch (e) {
        // Erro tratado pelo serviço (ex: senha errada, usuário não existe)
        // Mostra uma mensagem amigável em português no SnackBar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.message,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red.shade600, // Fundo vermelho = erro
              behavior: SnackBarBehavior.floating, // Flutua acima do conteúdo
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Cantos arredondados
              ),
            ),
          );
        }
      } catch (e) {
        // Erro inesperado (ex: sem internet, timeout, erro interno)
        // Mostra uma mensagem genérica com detalhes do erro para debug
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao enviar código 2FA: $e'),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } finally {
        // Desliga o loading independente do resultado (sucesso ou erro)
        // O finally garante que o botão nunca fique travado em loading infinito
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // Monta toda a interface visual da tela de login
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold é o esqueleto básico de uma tela no Material Design
      body: Center(
        // Center centraliza tudo vertical e horizontalmente
        child: SingleChildScrollView(
          // Scroll pra quando o teclado abrir não empurrar tudo pra fora da tela
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            // Form agrupa os campos e permite validá-los com uma única chamada
            key: _formKey,
            child: Column(
              // Column organiza os filhos na vertical, de cima pra baixo
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch, // Estica na largura
              children: [
                // Logo do app — carregada dos assets locais
                Image.asset('assets/images/Logo1.png', height: 80),
                const SizedBox(height: 8), // Espaçamento entre elementos

                // Título de boas-vindas — dá um tom pessoal e acolhedor
                const Text(
                  'Bem-vindo de volta',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Subtítulo — instrução direta sobre o que fazer nesta tela
                Text(
                  'Faça o login na sua conta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade300, // Tom mais claro para hierarquia visual
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),

                // Campo de e-mail reutilizável com validação embutida
                EmailField(controller: _emailController),
                const SizedBox(height: 16),

                // Campo de senha com olhinho para mostrar/esconder
                PasswordField(controller: _passwordController),
                const SizedBox(height: 32),

                // Botão principal de login (com loading enquanto processa)
                // Fica desabilitado durante o carregamento para evitar cliques duplos
                PrimaryButton(
                  label: 'Entrar',
                  onPressed: _onSigInPressed,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),

                // Link pra recuperar senha — leva para o fluxo de 3 etapas
                NavLink(
                  label: 'Esqueci minha senha',
                  destination: const PassRecoveryPage(),
                ),

                const SizedBox(height: 16),

                // Link pra criar conta nova — combinação de texto + link clicável
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
