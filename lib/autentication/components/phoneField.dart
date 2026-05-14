// Importa o pacote do Flutter pra montar a interface
import 'package:flutter/material.dart';

// Importa o services pra usar o TextInputFormatter (formatação de texto)
import 'package:flutter/services.dart';

// Formatador customizado que coloca parênteses e traço no telefone automaticamente
// Enquanto o usuário digita "11912345678", aparece "(11) 91234-5678"
class PhoneInputFormatter extends TextInputFormatter {
  // Essa função roda toda vez que o texto do campo muda
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, // o que tinha antes
    TextEditingValue newValue, // o que ficou depois de digitar
  ) {
    // Remove tudo que não é número (letras, espaços, símbolos)
    String numbers = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Telefone brasileiro tem no máximo 11 dígitos, trava aqui
    if (numbers.length > 11) {
      numbers = numbers.substring(0, 11);
    }

    // Monta o texto formatado com a máscara (XX) XXXXX-XXXX
    String formatted = '';
    for (int i = 0; i < numbers.length; i++) {
      // Antes do primeiro dígito, abre parêntese
      if (i == 0) {
        formatted += '(';
      }
      // Depois do segundo dígito (DDD), fecha parêntese e espaço
      else if (i == 2) {
        formatted += ') ';
      }
      // Posição do traço muda dependendo se é celular ou fixo:
      // Celular (11 dígitos): traço depois do 7º dígito geral
      else if (numbers.length == 11 && i == 7) {
        formatted += '-';
      }
      // Fixo (10 dígitos): traço depois do 6º dígito geral
      else if (numbers.length <= 10 && i == 6) {
        formatted += '-';
      }

      // Adiciona o número atual na string
      formatted += numbers[i];
    }

    // Devolve o texto formatado com o cursor no final
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Campo de telefone com formatação automática e validação
// Aplica a máscara (XX) XXXXX-XXXX enquanto digita
// Verifica se tem pelo menos 10 dígitos (fixo) ou 11 (celular)
class PhoneField extends StatelessWidget {
  // controller = guarda o texto digitado
  final TextEditingController controller;

  // label = texto do campo (padrão: "Telefone")
  final String? label;

  // onChanged = função que roda a cada tecla (opcional)
  final void Function(String)? onChanged;

  // Construtor
  const PhoneField({
    super.key,
    required this.controller,
    this.label,
    this.onChanged,
  });

  // Monta o campo na tela
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      // Conecta o controller
      controller: controller,

      // Função opcional que roda a cada tecla
      onChanged: onChanged,

      // Abre o teclado de telefone no celular
      keyboardType: TextInputType.phone,

      // Conecta nosso formatador que coloca parênteses e traço
      inputFormatters: [PhoneInputFormatter()],

      // Visual do campo
      decoration: InputDecoration(
        // Texto do campo
        label: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: label ?? 'Telefone'),
              const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),

        // Ícone de telefone na esquerda
        prefixIcon: const Icon(Icons.phone_outlined),

        // Borda retangular
        border: const OutlineInputBorder(),

        // Compacta o campo
        isDense: true,

        // Texto de erro menor
        errorStyle: const TextStyle(fontSize: 11, height: 0.8),

        // Texto fantasma mostrando o formato esperado
        hintText: '(11) 11111-1111',
      ),

      // Validação
      validator: (value) {
        // Se tá vazio, mostra erro
        if (value == null || value.isEmpty) {
          return 'Informe seu telefone';
        }

        // Remove a formatação pra contar só os números puros
        final digitos = value.replaceAll(RegExp(r'[^0-9]'), '');

        // Precisa ter pelo menos 10 dígitos (telefone fixo)
        if (digitos.length < 10) {
          return 'Telefone incompleto';
        }

        // Tudo certo!
        return null;
      },
    );
  }
}
