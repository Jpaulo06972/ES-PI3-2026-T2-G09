// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

// Importa o pacote básico de UI do Flutter (Material Design)
import 'package:flutter/material.dart';

// Importa componentes reutilizáveis do projeto
import '../components/passwordField.dart'; // Campo de senha com olhinho e validação de força
import '../components/primaryButton.dart'; // Botão verde com suporte a loading

// Importa o serviço de reset de senha e a tela de login
import '../services/passwordResetService.dart';
import 'signin.dart';

/*
 * Tela onde o usuário cria a nova senha — é o último passo (etapa 3) do fluxo de recuperação.
 * Fluxo completo: passRecovery → passRecoveryCode → newPasswordPage (esta tela) → signin
 *
 * Recebe o e-mail e o código já verificado na tela anterior para autenticar a operação
 * no backend. O código funciona como um "token temporário" que prova que o usuário
 * tem acesso ao e-mail cadastrado e pode redefinir a senha.
 */
class NewPasswordPage extends StatefulWidget {
  // E-mail do usuário — necessário para identificar a conta no backend
  final String email;

  // Código de 6 dígitos que foi verificado na tela anterior
  // Serve como "token" que prova que o usuário tem acesso ao e-mail
  final String code;

  const NewPasswordPage({super.key, required this.email, required this.code});

  // Cria o estado mutável desta tela
  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

// Estado da tela de nova senha — gerencia controllers, validação e comunicação com backend
class _NewPasswordPageState extends State<NewPasswordPage> {
  // Chave do formulário — permite validar ambos os campos de senha de uma vez
  // Quando chamamos validate(), ele percorre o campo de senha e o de confirmação
  final _formKey = GlobalKey<FormState>();

  // Controller da nova senha que o usuário está criando
  final _passwordController = TextEditingController();

  // Controller do campo "Confirmar nova senha"
  // O PasswordField usa esses dois para comparar em tempo real e mostrar
  // o erro "As senhas não são iguais" automaticamente
  final _confirmController = TextEditingController();

  // Serviço responsável pela comunicação com o backend (Cloud Functions)
  // Abstrai a chamada HTTP que efetivamente atualiza a senha no Firebase Auth
  final _service = PasswordResetService();

  // Controla o estado de loading do botão
  // Quando true, o botão mostra o CircularProgressIndicator e fica bloqueado
  bool _isLoading = false;

  // Limpa os controllers da memória quando sai da tela (boa prática para evitar memory leak)
  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Executado ao pressionar "Redefinir senha"
  // Valida os campos, chama o backend e, se der certo, redireciona para o login
  Future<void> _onConfirmPressed() async {
    // Se os campos de senha não passaram na validação (ex: senhas diferentes,
    // senha fraca, campo vazio), para aqui sem chamar o backend
    if (!_formKey.currentState!.validate()) return;

    // Liga o estado de loading: botão vira bolinha girando
    setState(() => _isLoading = true);

    try {
      // Chama o backend passando e-mail, código (token de verificação) e a nova senha
      // O backend valida o código de novo por segurança e, se ok,
      // atualiza a senha no Firebase Auth
      await _service.resetPassword(
        email: widget.email,
        code: widget.code,
        newPassword: _passwordController.text,
      );

      // mounted verifica se a tela ainda está na pilha de navegação
      // Isso é necessário porque pode ter sido descartada enquanto aguardava o backend
      if (!mounted) return;

      // Senha redefinida com sucesso — informa o usuário via SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha redefinida com sucesso!')),
      );

      // Redireciona para o login removendo TODAS as telas anteriores da pilha
      // (route) => false remove absolutamente tudo — o usuário não pode voltar
      // para as telas de recuperação, o que faz sentido após concluir o fluxo
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignInPage()),
        (route) => false,
      );
    } on PasswordResetException catch (e) {
      // Erro tratado pelo serviço — mostra a mensagem amigável já formatada
      // Ex: "Código expirado", "Senha muito fraca", "Erro no servidor"
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      // Desliga o loading independente do resultado (sucesso ou erro)
      // O finally garante que o loading nunca fique preso em caso de exceção
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Constrói toda a interface visual da tela de nova senha
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          // Scroll para quando o teclado abrir não cobrir os campos
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            // Associa a chave para que possamos chamar validate() depois
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              // stretch = os campos e botão ocupam toda a largura disponível
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ícone de cadeado — reforça visualmente que esta tela é sobre segurança/senha
                Icon(
                  Icons.lock_outline,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),

                // Título da tela
                const Text(
                  'Nova senha',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Instrução para o usuário criar uma senha segura
                Text(
                  'Crie uma senha forte para sua conta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade300),
                ),
                const SizedBox(height: 32),

                // Campo de nova senha com validação de força (isCadastro: true)
                // Mostra as dicas de força em tempo real (maiúscula, número, símbolo)
                // no helperText abaixo do campo
                PasswordField(
                  controller: _passwordController,
                  label: 'Nova senha',
                  isCadastro: true,
                ),
                const SizedBox(height: 16),

                // Campo de confirmação — o confirmController compara com o campo acima em tempo real
                // O erro "As senhas não são iguais" aparece/desaparece enquanto o usuário digita
                // graças ao autovalidateMode do PasswordField
                PasswordField(
                  controller: _confirmController,
                  label: 'Confirmar nova senha',
                  isCadastro: true,
                  confirmController: _passwordController,
                ),
                const SizedBox(height: 32),

                // Botão de ação com estado de loading integrado
                // Desabilitado durante o processamento para evitar cliques duplos
                PrimaryButton(
                  label: 'Redefinir senha',
                  onPressed: _onConfirmPressed,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
