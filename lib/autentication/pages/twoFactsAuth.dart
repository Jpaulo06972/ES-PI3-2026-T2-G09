import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../components/primaryButton.dart';
import '../services/two_factor_service.dart';
import '../../dashboard/home.dart';
import '../../model/userModel.dart';

class TwoFactsAuthPage extends StatefulWidget {
  final String email;
  final UserModel user;

  const TwoFactsAuthPage({
    super.key,
    required this.email,
    required this.user,
  });

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
  bool _isResending = false;

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
      await _service.verifyCode(email: widget.email, code: _code);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomePage(user: widget.user)),
        (_) => false,
      );
    } on TwoFactorException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onResendPressed() async {
    setState(() => _isResending = true);
    try {
      await _service.sendCode(widget.email);
      if (!mounted) return;
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Novo código enviado!')),
      );
    } on TwoFactorException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _onBackPressed() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pop(context);
  }

  Widget _buildDigitBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
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
    return PopScope(
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) await FirebaseAuth.instance.signOut();
      },
      child: Scaffold(
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
                Text(
                  'Insira o código de 6 dígitos enviado para ${widget.email}.',
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Não recebeu o código?',
                      style: TextStyle(color: Colors.grey.shade300),
                    ),
                    const SizedBox(width: 4),
                    _isResending
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : GestureDetector(
                            onTap: _onResendPressed,
                            child: Container(
                              padding: const EdgeInsets.only(bottom: 1),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Reenviar',
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
                Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: _onBackPressed,
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
