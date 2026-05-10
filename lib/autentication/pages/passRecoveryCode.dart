// Importa o pacote básico de UI do Flutter
import 'package:flutter/material.dart';
// Importa utilitários para formatar entrada do teclado
import 'package:flutter/services.dart';
// Importa componentes reutilizáveis
import '../components/primaryButton.dart';
import '../components/navLink.dart';
// Importa o serviço de reset e a próxima tela
import '../services/passwordResetService.dart';
import 'newPasswordPage.dart';
import 'signin.dart';

// Tela onde o usuário digita o código de 6 dígitos recebido por e-mail
class PassRecoveryCodePage extends StatefulWidget {
  // E-mail do usuário (veio da tela anterior)
  final String email;
  const PassRecoveryCodePage({super.key, required this.email});
  @override
  State<PassRecoveryCodePage> createState() => _PassRecoveryCodePageState();
}

class _PassRecoveryCodePageState extends State<PassRecoveryCodePage> {
  // 6 controllers — um para cada quadradinho de dígito
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  // 6 FocusNodes para controlar qual campo está ativo
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  // Serviço de reset de senha
  final _service = PasswordResetService();
  // Loading do botão "Continuar"
  bool _isLoading = false;
  // Loading do botão "Reenviar"
  bool _isResending = false;

  // Limpa controllers e focusNodes ao sair da tela
  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  // Junta os 6 dígitos num código só (ex: "123456")
  String get _code => _controllers.map((c) => c.text).join();

  // Ao pressionar "Continuar" — valida o código no backend antes de navegar
  Future<void> _onVerifyPressed() async {
    if (_code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os 6 dígitos')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _service.verifyResetCode(email: widget.email, code: _code);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => NewPasswordPage(email: widget.email, code: _code),
      ));
    } on PasswordResetException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Ao pressionar "Reenviar" — envia novo código e limpa os campos
  Future<void> _onResendPressed() async {
    setState(() => _isResending = true);
    try {
      await _service.sendResetCode(widget.email);
      if (!mounted) return;
      for (final c in _controllers) { c.clear(); }
      _focusNodes[0].requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Novo código enviado!')),
      );
    } on PasswordResetException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  // Constrói cada quadradinho de dígito com foco automático
  Widget _buildDigitBox(int index) {
    return SizedBox(
      width: 44, height: 50,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        // Aceita só 1 número por campo
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
          ),
        ),
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        // Avança/volta o foco automaticamente ao digitar/apagar
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          } else if (value.isEmpty && index > 0) {
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
              Icon(Icons.mark_email_read_outlined, size: 72, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              // Título
              const Text('Verifique seu e-mail', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // Instrução com o e-mail do usuário
              Text('Insira o código de 6 dígitos enviado para ${widget.email}.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade300)),
              const SizedBox(height: 32),
              // Os 6 quadradinhos
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(6, _buildDigitBox)),
              const SizedBox(height: 32),
              // Botão "Continuar"
              PrimaryButton(label: 'Continuar', onPressed: _onVerifyPressed, isLoading: _isLoading),
              const SizedBox(height: 20),
              // Link "Não recebeu?" + botão "Reenviar"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Não recebeu o código?', style: TextStyle(color: Colors.grey.shade300)),
                  const SizedBox(width: 4),
                  _isResending
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : GestureDetector(
                          onTap: _onResendPressed,
                          child: Container(
                            padding: const EdgeInsets.only(bottom: 1),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1))),
                            child: Text('Reenviar', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 12),
              // Link para voltar ao login
              NavLink(destination: const SignInPage(), label: 'Voltar para o login'),
            ],
          ),
        ),
      ),
    );
  }
}
