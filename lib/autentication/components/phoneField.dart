import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// -----------------------------------------------------------------------------
// Formatador de Telefone Customizado
// Esta classe é responsável por formatar o texto ENQUANTO o usuário digita,
// colocando os parênteses () e o traço (-) automaticamente.
// Resultado final: (11) 91234-5678
// -----------------------------------------------------------------------------
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Pega o novo texto e remove tudo que não for número,
    // caso o usuário tente digitar uma letra ou colar texto
    String numbers = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // 2. Trava a quantidade de dígitos no máximo em 11
    if (numbers.length > 11) {
      numbers = numbers.substring(0, 11);
    }

    // 3. Constroi a string formatando com parênteses () e o traço (-) automaticamente
    String formatted = '';

    // Percorre cada dígito e vai montando a máscara
    for (int i = 0; i < numbers.length; i++) {
      // Adiciona o "(" antes do primeiro dígito
      if (i == 0) {
        formatted += '(';

        // Adiciona o ") " depois do segundo dígito (fecha o DDD)
      } else if (i == 2) {
        formatted += ') ';

        // Adiciona o "-" na posição correta dependendo se é celular (11 dígitos) ou fixo (10 dígitos)
        // Celular: (11) 91234-5678 → traço depois do 5º dígito do número (posição 7 geral)
      } else if (numbers.length == 11 && i == 7) {
        formatted += '-';

        // Fixo: (11) 1234-5678 → traço depois do 4º dígito do número (posição 6 geral)
      } else if (numbers.length <= 10 && i == 6) {
        formatted += '-';
      }

      // Adiciona o dígito atual na string formatada
      formatted += numbers[i];
    }

    // 4. Retorna o valor formatado com o cursor sempre no final
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// -----------------------------------------------------------------------------
// Componente PhoneField
// Campo de telefone reutilizável, mesmo estilo visual dos outros componentes.
// Formata automaticamente enquanto o usuário digita: (XX) XXXXX-XXXX
// Valida se o número tem pelo menos 10 dígitos (fixo) ou 11 (celular).
// -----------------------------------------------------------------------------
class PhoneField extends StatelessWidget {
  // "Props" do componente
  final TextEditingController
  controller; // O "caderno" que guarda o telefone digitado
  final String? label; // Texto do campo (opcional, padrão: 'Telefone')
  final void Function(String)? onChanged; // Callback disparado a cada tecla

  const PhoneField({
    super.key,
    required this.controller,
    this.label,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,

      // Abre o teclado numérico no celular (só números aparecem)
      keyboardType: TextInputType.phone,

      // Conecta o formatador: enquanto o usuário digita, a máscara é aplicada
      inputFormatters: [PhoneInputFormatter()],

      // Visual idêntico aos outros campos do projeto
      decoration: InputDecoration(
        labelText: label ?? 'Telefone',
        prefixIcon: const Icon(Icons.phone_outlined),
        border: const OutlineInputBorder(),
        hintText: '(11) 11111-1111',
      ),

      // Validação: verifica se o campo está preenchido e se tem dígitos suficientes
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Informe seu telefone';
        }

        // Remove a formatação para contar apenas os dígitos puros
        final digitos = value.replaceAll(RegExp(r'[^0-9]'), '');

        // Telefone brasileiro precisa ter no mínimo 10 dígitos (fixo) ou 11 (celular)
        if (digitos.length < 10) {
          return 'Telefone incompleto';
        }

        return null;
      },
    );
  }
}
