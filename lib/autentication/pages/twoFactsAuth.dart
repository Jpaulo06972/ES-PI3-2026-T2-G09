import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/primaryButton.dart';

// Tela de autenticação de dois fatores (2FA)
// O usuário digita o código de 6 dígitos recebido por e-mail
class TwoFactsAuthPage extends StatefulWidget {
  const TwoFactsAuthPage({super.key});

  @override
  State<TwoFactsAuthPage> createState() => _TwoFactsAuthPageState();
}

class _TwoFactsAuthPageState extends State<TwoFactsAuthPage> {
  // Um controller por quadradinho — são 6 campos independentes
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  // FocusNodes controlam qual campo está "ativo" (com cursor) no momento
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    // Libera todos os controllers e focusNodes da memória de uma vez
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // Monta o código final juntando o dígito de cada campo
  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _onVerifyPressed() async {
    if (_code.length < 6) {
      // Avisa se o usuário não preencheu todos os 6 campos
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os 6 dígitos')),
      );
      return;
    }
    // TODO: integrar com backend para validar o código
    debugPrint('Código informado: $_code');
  }

  void _onResendPressed() {
    // TODO: integrar com backend para reenviar o código por e-mail
    debugPrint('Reenviar código');
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
        // Aceita no máximo 1 caractere por campo
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          // Remove o padding padrão para o dígito ficar centralizado na caixa
          contentPadding: EdgeInsets.zero,
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
            // Avança o foco automaticamente para o próximo campo ao digitar
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
              // Ícone representando verificação / segurança
              Icon(
                Icons.verified_user_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),

              // Título
              const Text(
                'Verificação em duas etapas',
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

              // Botão principal de verificação
              PrimaryButton(label: 'Verificar', onPressed: _onVerifyPressed),
              const SizedBox(height: 20),

              // Link "Não recebi o código" — aciona o reenvio
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

              // Navigator.pop() desempilha a tela e volta para o SignIn
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
