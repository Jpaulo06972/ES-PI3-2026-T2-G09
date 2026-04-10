import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/primaryButton.dart';
import '../../dashboard/home.dart';

// Tela onde o usuário digita o código de recuperação recebido por e-mail
// Após validação correta, redireciona para o Home substituindo toda a pilha de navegação
class PassRecoveryCodePage extends StatefulWidget {
  const PassRecoveryCodePage({super.key});

  @override
  State<PassRecoveryCodePage> createState() => _PassRecoveryCodePageState();
}

class _PassRecoveryCodePageState extends State<PassRecoveryCodePage> {
  // Um controller por quadradinho — são 6 campos independentes
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  // FocusNodes controlam qual campo está "ativo" (com cursor) no momento
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    // Libera todos os controllers e focusNodes da memória ao sair da tela
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  // Junta os dígitos de cada campo em uma string única ex: "483920"
  String get _code => _controllers.map((c) => c.text).join();

  void _onVerifyPressed() {
    // Garante que todos os 6 campos foram preenchidos antes de prosseguir
    if (_code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os 6 dígitos')),
      );
      return;
    }

    // TODO: integrar com backend para validar o código de recuperação
    // Simulação: qualquer código de 6 dígitos é aceito por enquanto
    if (_code.length == 6) {
      // pushAndRemoveUntil substitui TODA a pilha de navegação pelo Home
      // O usuário não consegue voltar para o fluxo de recuperação após entrar
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false, // remove todas as rotas anteriores
      );
    }
  }

  void _onResendPressed() {
    // TODO: integrar com backend para reenviar o código por e-mail
    debugPrint('Reenviar código de recuperação');
  }

  // Constrói cada um dos 6 quadradinhos de dígito
  Widget _buildDigitBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        // Limita a 1 dígito numérico por campo
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
        ),
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            // Avança o foco para o próximo campo automaticamente ao digitar
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          } else if (value.isEmpty && index > 0) {
            // Volta o foco ao campo anterior ao apagar
            FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ícone de e-mail com verificação
              Icon(
                Icons.mark_email_read_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),

              // Título
              const Text(
                'Verifique seu e-mail',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Instrução
              const Text(
                'Insira o código de 6 dígitos enviado para o seu e-mail.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 40),

              // Os 6 quadradinhos lado a lado com espaço uniforme entre eles
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, _buildDigitBox),
              ),
              const SizedBox(height: 32),

              // Botão que valida o código e redireciona para o Home
              PrimaryButton(label: 'Confirmar', onPressed: _onVerifyPressed),
              const SizedBox(height: 20),

              // Link para reenviar o código caso não tenha chegado
              Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: _onResendPressed,
                  child: Text(
                    'Não recebi o código',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Navigator.pop() desempilha essa tela e volta para o passRecovery
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
    );
  }
}
