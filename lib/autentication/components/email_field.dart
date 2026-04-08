import 'package:flutter/material.dart';

// Widget reutilizável de campo de e-mail
// Equivalente a um componente React com props
class EmailField extends StatelessWidget {
  // "Props" do componente — passadas pelo construtor
  final TextEditingController controller;
  final String? label;           // opcional, tem valor padrão
  final void Function(String)? onChanged; // callback opcional

  const EmailField({
    super.key,
    required this.controller,  // obrigatória (required = prop obrigatória)
    this.label,
    this.onChanged,
    
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label ?? 'E-mail', // se não passar label, usa 'E-mail'
        prefixIcon: const Icon(Icons.email_outlined),
        border: const OutlineInputBorder(),
        
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Informe seu e-mail';
        if (!value.contains('@')) return 'E-mail inválido';
        return null;
      },
    );
  }
}
