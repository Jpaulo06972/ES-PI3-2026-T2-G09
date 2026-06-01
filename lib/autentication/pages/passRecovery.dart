// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

// Importa o pacote básico de UI do Flutter (Material Design)
import 'package:flutter/material.dart';

// Importa os componentes reutilizáveis do projeto
// Cada um encapsula um elemento de UI com validação e estilo padronizado
import '../components/emailField.dart';
import '../components/primaryButton.dart';
import '../components/navLink.dart';

// Importa o serviço que envia o código de recuperação por e-mail via Cloud Function
// Esse serviço abstrai toda a comunicação com o backend Firebase
import '../services/passwordResetService.dart';

// Importa a próxima tela do fluxo (onde o usuário digita o código recebido)
import 'passRecoveryCode.dart';

// Importa a tela de login para o link "Voltar para o login"
import 'signin.dart';

/*
 * Tela de recuperação de senha — primeiro passo do fluxo de 3 etapas:
 * 1. passRecovery (esta tela): usuário informa o e-mail cadastrado
 * 2. passRecoveryCode: usuário digita o código de 6 dígitos recebido por e-mail
 * 3. newPasswordPage: usuário cria a nova senha
 *
 * O fluxo foi dividido em 3 telas para dar um feedback claro ao usuário
 * sobre em qual etapa ele se encontra, seguindo boas práticas de UX.
 */
class PassRecoveryPage extends StatefulWidget {
  const PassRecoveryPage({super.key});

  // Cria o estado mutável desta tela
  @override
  State<PassRecoveryPage> createState() => _PassRecoveryPageState();
}

// Estado da tela de recuperação de senha — contém toda a lógica interativa
class _PassRecoveryPageState extends State<PassRecoveryPage> {
  // Chave do formulário — usada para chamar validate() no campo de e-mail
  // Permite validar se o e-mail foi preenchido e tem formato válido
  final _formKey = GlobalKey<FormState>();

  // Controller que guarda o e-mail digitado pelo usuário
  // Precisamos dele fora do widget para ler o valor ao submeter o formulário
  final _emailController = TextEditingController();

  // Instância do serviço de reset de senha
  // Ele abstrai as chamadas à Cloud Function do Firebase
  // (gerar código, enviar e-mail, verificar código, redefinir senha)
  final _service = PasswordResetService();

  // Controla se o botão está em estado de carregamento (bolinha girando)
  // Fica true enquanto aguarda a resposta do backend
  bool _isLoading = false;

  // Limpa o controller da memória quando sai da tela
  // Boa prática para evitar memory leak — o Flutter não faz isso automaticamente
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Função chamada ao pressionar "Enviar código"
  // Valida o e-mail, chama o serviço e navega para a tela de código
  Future<void> _onSendPressed() async {
    // Se o formulário não for válido (e-mail vazio ou sem @), para aqui
    // O campo de e-mail já exibe a mensagem de erro automaticamente via validator
    if (!_formKey.currentState!.validate()) return;

    // Liga o loading no botão para dar feedback visual ao usuário
    // O botão fica desabilitado e mostra a bolinha girando
    setState(() => _isLoading = true);

    // Pega o e-mail digitado e remove espaços extras no início/fim
    // trim() é importante para evitar erros por espaços acidentais
    final email = _emailController.text.trim();

    try {
      // Chama o backend (Cloud Function) para gerar e enviar o código de recuperação
      // O backend cria um código de 6 dígitos, salva no Firestore com timestamp
      // de expiração e envia por e-mail usando um serviço de e-mail (ex: SendGrid)
      await _service.sendResetCode(email);

      // Verifica se a tela ainda está na pilha antes de navegar
      // (pode ter sido descartada enquanto aguardava a resposta da rede)
      if (!mounted) return;

      // Sucesso! Navega para a tela onde o usuário digita o código recebido
      // Passa o e-mail adiante para que o backend saiba qual conta está sendo recuperada
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PassRecoveryCodePage(email: email)),
      );
    } on PasswordResetException catch (e) {
      // Erro tratado pelo serviço — exibe a mensagem amigável no SnackBar
      // Exemplos: "E-mail não encontrado", "Erro ao enviar o código"
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      // Desliga o loading do botão independente do resultado (sucesso ou erro)
      // O finally garante que o loading não fique preso caso haja exceção
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Constrói a interface visual da tela de recuperação de senha
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Corpo da tela centralizado vertical e horizontalmente
      body: Center(
        child: SingleChildScrollView(
          // Scroll para quando o teclado abrir não empurrar o conteúdo para fora
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            // Associa a chave do formulário para validação via validate()
            key: _formKey,
            child: Column(
              // Centraliza tudo verticalmente dentro do espaço disponível
              mainAxisAlignment: MainAxisAlignment.center,
              // Estica os filhos para ocupar toda a largura da tela
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ícone de cadeado com seta de reset — representa visualmente
                // a recuperação de senha, ajudando o usuário a identificar o propósito da tela
                Icon(
                  Icons.lock_reset_outlined,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),

                // Espaçamento entre o ícone e o título
                const SizedBox(height: 16),

                // Título da tela — grande e em negrito para hierarquia visual
                const Text(
                  'Recuperar senha',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                // Espaçamento entre o título e a instrução
                const SizedBox(height: 8),

                // Texto explicativo — informa ao usuário o que vai acontecer
                // ao preencher o e-mail (receberá um código de 6 dígitos)
                Text(
                  'Informe seu e-mail e enviaremos um código de 6 dígitos para redefinir sua senha.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade300),
                ),

                // Espaçamento antes do campo de e-mail
                const SizedBox(height: 32),

                // Campo de e-mail reutilizável com validação embutida (verifica @)
                EmailField(controller: _emailController),

                // Espaçamento antes do botão de ação
                const SizedBox(height: 32),

                // Botão principal com suporte a loading
                // Fica bloqueado enquanto aguarda resposta do backend
                PrimaryButton(
                  label: 'Enviar código',
                  onPressed: _onSendPressed,
                  isLoading: _isLoading,
                ),

                // Espaçamento antes do link de voltar
                const SizedBox(height: 24),

                // Link para voltar à tela de login caso o usuário lembre a senha
                // ou desista da recuperação
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
