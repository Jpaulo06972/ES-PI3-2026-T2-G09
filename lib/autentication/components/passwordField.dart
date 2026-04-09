import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final bool isCadastro;
  final void Function(String)? onChanged;

  const PasswordField({
    super.key,
    required this.controller,
    this.label,
    this.onChanged,
    this.isCadastro = false,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  // StatefulWidget aqui porque o toggle de visibilidade é estado interno do componente
  bool _obscure = true;

  // Estrutura de função solicitada
  String? _validarSenha(String? value) {
    // TODO: Adicione sua lógica aqui
    if (value == null || value.isEmpty) return 'Informe sua senha';

    // Da um log de erro caso a senha seja errada
    if (widget.isCadastro) {
      if (value.length < 6) {
        return 'Senha muito curta';
      }
      if (!value.contains(RegExp(r'[A-Z]'))) {
        return 'A senha precisa ter uma letra maiúscula';
      }
      if (!value.contains(RegExp(r'[0-9]'))) {
        return 'A senha precisa ter um número';
      }
      if (!value.contains(RegExp(r'[!@#$%^&*]'))) {
        return 'A senha precisa ter um caractere especial';
      }
      if (value.contains(RegExp(r'\s'))) {
        return 'A senha não pode conter espaços';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label ?? 'Senha',
        prefixIcon: const Icon(Icons.lock_outline),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: (value) {
        return _validarSenha(value);
      },
    );
  }
}
