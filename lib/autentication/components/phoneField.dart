// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote do Flutter pra montar a interface
import 'package:flutter/material.dart';

// Importa o services pra usar o TextInputFormatter (formatação de texto)
import 'package:flutter/services.dart';

// Formatador customizado que coloca parênteses e traço no telefone automaticamente
// Enquanto o usuário digita "11912345678", aparece "(11) 91234-5678"
// Isso evita que o usuário precise digitar os símbolos manualmente
class PhoneInputFormatter extends TextInputFormatter {
  // Essa função roda toda vez que o texto do campo muda
  // oldValue = o que tinha antes, newValue = o que ficou depois de digitar
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, // o que tinha antes
    TextEditingValue newValue, // o que ficou depois de digitar
  ) {
    // Remove tudo que não é número (letras, espaços, parênteses, traço)
    // Deixamos só os dígitos para trabalhar com eles
    String numbers = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Telefone brasileiro tem no máximo 11 dígitos (2 DDD + 9 número)
    // Trava aqui para evitar que o usuário ultrapasse o limite
    if (numbers.length > 11) {
      numbers = numbers.substring(0, 11);
    }

    // Monta o texto formatado com a máscara (XX) XXXXX-XXXX
    // Percorre cada dígito e insere os símbolos nos lugares certos
    String formatted = '';
    for (int i = 0; i < numbers.length; i++) {
      // Antes do primeiro dígito (DDD), abre o parêntese
      if (i == 0) {
        formatted += '(';
      }
      // Depois do segundo dígito (fim do DDD), fecha parêntese e adiciona espaço
      else if (i == 2) {
        formatted += ') ';
      }
      // O traço divide o número em duas partes
      // A posição muda dependendo se é celular (9 dígitos) ou fixo (8 dígitos):
      // Celular (11 dígitos no total): o traço fica após o 7º dígito do número
      else if (numbers.length == 11 && i == 7) {
        formatted += '-';
      }
      // Fixo (10 dígitos no total): o traço fica após o 6º dígito do número
      else if (numbers.length <= 10 && i == 6) {
        formatted += '-';
      }

      // Adiciona o dígito atual na string formatada
      formatted += numbers[i];
    }

    // Devolve o texto formatado com o cursor posicionado no final
    // TextSelection.collapsed no final é o comportamento esperado pelo usuário
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Campo de telefone com formatação automática e validação
// Aplica a máscara (XX) XXXXX-XXXX enquanto digita
// Verifica se tem pelo menos 10 dígitos (fixo) ou 11 (celular)
// É StatelessWidget porque a formatação fica toda no formatter acima
class PhoneField extends StatelessWidget {
  // controller = guarda o texto digitado para leitura pela tela pai
  final TextEditingController controller;

  // label = texto do campo (padrão: "Telefone")
  final String? label;

  // onChanged = função que roda a cada tecla (opcional)
  final void Function(String)? onChanged;

  // Construtor — controller é obrigatório
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
      // Conecta o controller para que a tela pai possa ler o valor
      controller: controller,

      // Função opcional que roda a cada tecla
      onChanged: onChanged,

      // Abre o teclado de telefone no celular — mais conveniente para o usuário
      keyboardType: TextInputType.phone,

      // Conecta nosso formatador que insere parênteses, espaço e traço automaticamente
      inputFormatters: [PhoneInputFormatter()],

      // Visual do campo seguindo o padrão do app
      decoration: InputDecoration(
        // Texto do campo com asterisco vermelho indicando campo obrigatório
        label: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: label ?? 'Telefone'),
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),

        // Ícone de telefone na esquerda para identificação visual do campo
        prefixIcon: const Icon(Icons.phone_outlined),

        // Borda retangular padrão do app
        border: const OutlineInputBorder(),

        // Compacta o campo para economizar espaço vertical na tela de cadastro
        isDense: true,

        // Texto de erro menor para não empurrar os campos abaixo
        errorStyle: const TextStyle(fontSize: 11, height: 0.8),

        // Texto fantasma mostrando o formato esperado para orientar o usuário
        hintText: '(11) 11111-1111',
      ),

      // Validação que roda quando o formulário chama validate()
      validator: (value) {
        // Se tá vazio, mostra erro imediato
        if (value == null || value.isEmpty) {
          return 'Informe seu telefone';
        }

        // Remove a formatação (parênteses, espaços, traço) para contar só os números puros
        // Assim a validação não depende da máscara, só dos dígitos reais
        final digitos = value.replaceAll(RegExp(r'[^0-9]'), '');

        // Precisa ter pelo menos 10 dígitos para ser um telefone fixo válido
        // Celular tem 11 (com o 9 na frente) — ambos são aceitos
        if (digitos.length < 10) {
          return 'Telefone incompleto';
        }

        // Tudo certo! Retorna null indicando sem erros
        return null;
      },
    );
  }
}
