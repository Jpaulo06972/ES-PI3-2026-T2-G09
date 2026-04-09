// Importa o pacote principal do Flutter (Material Design), que traz botões, cores, telas (Scaffold), etc.
import 'package:flutter/material.dart';

// Importa os nossos componentes visuais criados separadamente para manter este arquivo limpo
import '../components/emailField.dart'; // Campo de digitar o email
import '../components/passwordField.dart'; // Campo de digitar a senha
import '../components/navLink.dart'; // O link de texto clicável (ex: "Cadastre-se")
import '../components/primaryButton.dart'; // Nosso botão principal azulzinho

// Importa as outras telas para onde podemos viajar saindo do Login
import '../../dashboard/home.dart'; // A tela principal (quando acerta a senha)
import 'passRecovery.dart'; // A tela de esqueci a senha
import 'signup.dart'; // A tela de criar conta

// A SignInPage é a representação da "Tela de Login" inteira.
// Usamos "StatefulWidget" pois a tela tem coisas que mudam de estado em tempo real
// (como o olhinho de mostrar/esconder a senha, erros de digitação e o texto nos campos).
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

// O "_SignInPageState" é o cérebro da tela (o estado). É aqui que fica a lógica.
class _SignInPageState extends State<SignInPage> {
  // Fabricamos um "controle remoto" exclusivo para o nosso formulário
  // Ele nos permite validar todos os campos ao mesmo tempo depois
  final _formKey = GlobalKey<FormState>();

  // Os Controllers (Controladores) são "gravadores".
  // Eles capturam e guardam tudo o que o usuário digita nos sub-campos de texto.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // A função dispose() é chamada quando a tela é fechada e destruída (quando saímos do app)
  @override
  void dispose() {
    // É OBRIGATÓRIO limpar a memória jogando fora os gravadores quando não precisarmos mais!
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Função que roda assim que o usuário clica no botão azul "Entrar"
  void _onSigInPressed() {
    // 1. O código aperta o botão "validate" no nosso controle remoto.
    // O formulário pergunta aos campos: "Alguém aí tá vazio ou errado?"
    // Se todos responderem "Tá tudo certo (null)", ele retorna verdadeiro (true).
    if (_formKey.currentState!.validate()) {
      // 2. Extraímos o texto exato que ficou guardado nos controladores
      final email = _emailController.text;
      final password = _passwordController.text;

      // 3. Verificamos se as palavras batem com as credenciais cadastradas
      // Se bater (FOR VERDADEIRO):
      if (email == "jpaulo@gmail.com" && password == "Jp@01062000") {
        // Empurramos e Substituímos (pushReplacement) a tela atual pela "Home"
        // Como ele "substitui", a tela de login desaparece da memória,
        // impossibilitando que o usuário aperte "voltar" pro login sem deslogar.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        debugPrint('Email: $email | Senha: $password');
      } else {
        // Se a senha NÃO bater, avisamos apenas o programador no console (por enquanto)
        debugPrint('Email ou senha incorretos');
      }
    }
  }

  // Este é o método "build". É aqui que nós desenhamos a parte visual com as peças virtuais.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold é a estrutura básica de uma tela no celular (chão, parede e teto)
      body: Center(
        // Centraliza tudo na tela, verticalmente e horizontalmente
        child: SingleChildScrollView(
          // Permite que a tela deslize/role (scroll) para cima e para baixo.
          // Muito importante no login para que o teclado não engula os botões!
          padding: const EdgeInsets.symmetric(horizontal: 32),

          child: Form(
            // A caixa mestre "Televisão" que guarda nossos campos de texto importantes
            key:
                _formKey, // Sintonizamos o formulário com o controle remoto (key)

            child: Column(
              // Uma Coluna (Pilha de blocos empilhados de cima para baixo)
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment
                  .stretch, // Estica os botões até as paredes laterais

              children: [
                // 1. Desenhamos a imagem da logo puxada dos arquivos
                Image.asset('assets/images/Logo1.png', height: 80),
                const SizedBox(
                  height: 16,
                ), // Caixa invisível só para dar espaço (respiro)
                // 2. Título principal de boas-vindas
                const Text(
                  'Bem-vindo de volta',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                // 3. O nosso componente visual de Email!
                // Passamos o gravador (_emailController) como parâmetro para ele trabalhar lá dentro.
                EmailField(controller: _emailController),
                const SizedBox(height: 16),

                // 4. O nosso componente visual de Senha!
                // Passamos o gravador de Senha!
                PasswordField(controller: _passwordController),
                const SizedBox(height: 20),

                // 5. O link para "Esqueci minha senha"
                Align(
                  alignment: Alignment.center,
                  child: NavLink(
                    // O NavLink é um widget customizado nosso que já faz Navegação ao clicar
                    label: 'Esqueci minha senha',
                    destination: const PassRecoveryPage(),
                  ),
                ),

                const SizedBox(height: 8),

                // 6. Uma "Fileira" (Row) coloca os itens lado a lado horizontalmente
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Não tem conta?'), // Um texto normal estático
                    const SizedBox(width: 4), // Espacinho lateral de 4 pixels

                    NavLink(
                      // E o link clicável logo ao lado
                      label: 'Cadastre-se',
                      destination: const SignUpPage(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 7. E por fim, desenhamos o nosso botão primário azulão
                // E dizemos que a função a ser chamada quando ele for clicado (onPressed) é a _onLoginPressed
                PrimaryButton(label: 'Entrar', onPressed: _onSigInPressed),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
