import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/primaryButton.dart';
import '../../dashboard/home.dart';
import 'signin.dart';
import '../components/navLink.dart';

/// Tela onde o usuário digita o código de 6 dígitos que recebeu por e-mail.
/// Se o código tiver certo, ele entra no app. Se não recebeu, pode pedir pra reenviar.
class PassRecoveryCodePage extends StatefulWidget {
  const PassRecoveryCodePage({super.key});

  @override
  State<PassRecoveryCodePage> createState() => _PassRecoveryCodePageState();
}

class _PassRecoveryCodePageState extends State<PassRecoveryCodePage> {
  // Um controller pra cada quadradinho (são 6 no total)
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  // FocusNode controla qual campo tá "ativo" (com o cursor piscando)
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  // Controla o loading do botão Confirmar
  bool _isLoading = false;

  // Limpa todos os controllers e focusNodes da memória quando sai da tela
  // São 6 de cada, então usa um loop pra não repetir código
  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // Junta o texto de cada campo num código só (ex: "483920")
  String get _code => _controllers.map((c) => c.text).join();

  // Roda quando o usuário aperta "Confirmar"
  Future<void> _onVerifyPressed() async {
    if (_code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os 6 dígitos')),
      );
      return;
    }

    // Liga o loading
    setState(() => _isLoading = true);

    // Simula validação com o backend
    await Future.delayed(const Duration(milliseconds: 1500));

    // TODO: validar o código com o backend
    if (_code.length == 6 && mounted) {
      // Limpa toda a pilha de telas e vai direto pra Home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    }
  }

  // Reenviar o código por e-mail
  void _onResendPressed() {
    // TODO: chamar a API pra reenviar
    debugPrint('Reenviar código de recuperação');
  }

  // Monta cada quadradinho de dígito
  Widget _buildDigitBox(int index) {
    return SizedBox(
      width: 44,
      height: 50,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        // Só aceita 1 número por campo
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
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        onChanged: (value) {
          // Digitou? Pula pro próximo campo
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          }
          // Apagou? Volta pro campo anterior
          else if (value.isEmpty && index > 0) {
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
              // Ícone de e-mail verificado
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
              const SizedBox(height: 32),

              // Os 6 quadradinhos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, _buildDigitBox),
              ),
              const SizedBox(height: 32),

              // Botão de confirmar (com loading)
              PrimaryButton(
                label: 'Confirmar',
                onPressed: _onVerifyPressed,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 20),

              // "Não recebeu o código?" + link "Reenviar o código"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Não recebeu o código?'),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _onResendPressed,
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 1),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        'Reenviar o código',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Voltar pro login
              NavLink(
                destination: const SignInPage(),
                label: 'Voltar para o login',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
