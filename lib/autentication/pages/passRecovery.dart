import 'package:flutter/material.dart';
import '../components/emailField.dart';
import '../components/primaryButton.dart';

// StatefulWidget porque temos um formulário com validação (estado em tempo real)
class PassRecoveryPage extends StatefulWidget {
  const PassRecoveryPage({super.key});

  @override
  State<PassRecoveryPage> createState() => _PassRecoveryPageState();
}

class _PassRecoveryPageState extends State<PassRecoveryPage> {
  // Controle remoto do formulário — permite validar todos os campos de uma vez
  final _formKey = GlobalKey<FormState>();

  // Gravador do que o usuário digita no campo de e-mail
  final _emailController = TextEditingController();

  @override
  void dispose() {
    // Libera a memória do gravador quando a tela é destruída
    _emailController.dispose();
    super.dispose();
  }

  // Disparada ao clicar em "Enviar link"
  void _onSendPressed() {
    // Só prossegue se o e-mail passar na validação do EmailField
    if (_formKey.currentState!.validate()) {
      // TODO: integrar com backend para envio do e-mail de recuperação
      debugPrint('Recuperação enviada para: ${_emailController.text}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          // Evita que o teclado empurre e quebre o layout
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ícone de cadeado com seta — representa "redefinir senha"
                Icon(
                  Icons.lock_reset_outlined,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),

                // Título da tela
                const Text(
                  'Recuperar senha',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Instrução para o usuário entender o que vai acontecer
                const Text(
                  'Informe seu e-mail e enviaremos um link para redefinir sua senha.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 40),

                // Componente reutilizável de e-mail (validação já inclusa)
                EmailField(controller: _emailController),
                const SizedBox(height: 24),

                // Botão principal que dispara o envio do link
                PrimaryButton(label: 'Enviar link', onPressed: _onSendPressed),
                const SizedBox(height: 16),

                // Navigator.pop() remove a tela atual da pilha e volta para o SignIn
                // É diferente do push (que empilha) — aqui a gente só "desempilha"
                Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Voltar para o login',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
