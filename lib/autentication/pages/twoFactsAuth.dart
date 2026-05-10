import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/primaryButton.dart';
import '../../model/userModel.dart';
import '../../dashboard/pages/home.dart';
import '../services/two_factor_service.dart';

// Tela de autenticação de dois fatores (2FA)
// O usuário digita o código de 6 dígitos recebido por e-mail
class TwoFactsAuthPage extends StatefulWidget {
  final UserModel userModel;

  const TwoFactsAuthPage({super.key, required this.userModel});

  @override
  State<TwoFactsAuthPage> createState() => _TwoFactsAuthPageState();
}

class _TwoFactsAuthPageState extends State<TwoFactsAuthPage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final _service = TwoFactorService();
  bool _isLoading = false;
  bool _isSending = true;
  String? _sendError;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _isSending = true;
      _sendError = null;
    });
    try {
      await _service.sendCode(widget.userModel.uid, widget.userModel.email);
    } on TwoFactorException catch (e) {
      if (mounted) setState(() => _sendError = e.message);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _onVerifyPressed() async {
    if (_code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os 6 dígitos')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final valid = await _service.verifyCode(widget.userModel.uid, _code);
      if (!mounted) return;

      if (valid) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(user: widget.userModel),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código inválido ou expirado.')),
        );
      }
    } on TwoFactorException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onResendPressed() async {
    for (final c in _controllers) { c.clear(); }
    _focusNodes[0].requestFocus();
    await _sendCode();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Novo código enviado!')),
      );
    }
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
              Icon(
                Icons.verified_user_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),

              const Text(
                'Verificação em duas etapas',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              if (_isSending)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_sendError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _sendError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                )
              else
                Text(
                  'Insira o código de 6 dígitos enviado para ${widget.userModel.email}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade300),
                ),

              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, _buildDigitBox),
              ),
              const SizedBox(height: 32),

              PrimaryButton(
                label: 'Verificar',
                onPressed: _onVerifyPressed,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 20),

              Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: _isSending ? null : _onResendPressed,
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
