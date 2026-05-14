// Importa o pacote do Flutter pra montar a interface
import 'package:flutter/material.dart';

// Importa o services pra usar o TextInputFormatter (formatação de texto)
import 'package:flutter/services.dart';

// Formatador customizado que coloca os pontos e traço do CPF automaticamente
// Enquanto o usuário vai digitando "12345678901", aparece "123.456.789-01"
class CpfInputFormatter extends TextInputFormatter {
  // Essa função roda toda vez que o usuário digita ou apaga uma letra
  // oldValue = o que tinha antes, newValue = o que ficou agora
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Pega só os números do texto (remove qualquer letra, ponto ou traço)
    String numbers = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // CPF tem no máximo 11 dígitos, então trava aqui
    if (numbers.length > 11) {
      numbers = numbers.substring(0, 11);
    }

    // Agora monta o texto formatado colocando ponto e traço nos lugares certos
    String formatted = '';
    for (int i = 0; i < numbers.length; i++) {
      // Depois do 3º e do 6º dígito, coloca um ponto
      if (i == 3 || i == 6) formatted += '.';

      // Depois do 9º dígito, coloca um traço
      else if (i == 9) formatted += '-';

      // Adiciona o número atual
      formatted += numbers[i];
    }

    // Devolve o texto formatado pro campo, com o cursor no final
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Campo de CPF com máscara automática e validação matemática
// Além de formatar, verifica se o CPF é real usando o algoritmo da Receita Federal
class CpfField extends StatelessWidget {
  // controller = guarda o texto digitado
  final TextEditingController controller;

  // label = texto do campo (padrão: "CPF")
  final String? label;

  // onChanged = função que roda a cada tecla (opcional)
  final void Function(String)? onChanged;

  // Construtor
  const CpfField({
    super.key,
    required this.controller,
    this.label,
    this.onChanged,
  });

  // Função que verifica se o CPF é matematicamente válido
  // Usa o cálculo dos dois dígitos verificadores (os 2 últimos números)
  bool isCpfValido(String? cpf) {
    // Se veio vazio, já retorna falso
    if (cpf == null || cpf.isEmpty) return false;

    // Remove pontos e traços pra ficar só com os 11 números
    String numeros = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    // Se não tem exatamente 11 dígitos, é inválido
    if (numeros.length != 11) return false;

    // CPFs com todos os dígitos iguais são inválidos
    // (111.111.111-11, 222.222.222-22, etc.)
    if (RegExp(r'^(\d)\1*$').hasMatch(numeros)) return false;

    // Transforma a string em uma lista de números inteiros
    // "12345678901" vira [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1]
    List<int> digitos = numeros.split('').map(int.parse).toList();

    // --- Cálculo do PRIMEIRO dígito verificador (penúltimo número) ---
    // Multiplica cada um dos 9 primeiros dígitos por um peso decrescente (10, 9, 8...)
    int calc1 = 0;
    for (int i = 0; i < 9; i++) {
      calc1 += digitos[i] * (10 - i);
    }
    // Faz a conta do resto da divisão pra descobrir qual deveria ser o dígito
    int resto1 = (calc1 * 10) % 11;
    int digito1 = resto1 == 10 ? 0 : resto1;

    // Se o dígito calculado não bate com o que tá no CPF, é falso
    if (digitos[9] != digito1) return false;

    // --- Cálculo do SEGUNDO dígito verificador (último número) ---
    // Mesma lógica, mas agora usa os 10 primeiros dígitos com peso 11, 10, 9...
    int calc2 = 0;
    for (int i = 0; i < 10; i++) {
      calc2 += digitos[i] * (11 - i);
    }
    int resto2 = (calc2 * 10) % 11;
    int digito2 = resto2 == 10 ? 0 : resto2;

    // Se o segundo dígito também não bate, é falso
    if (digitos[10] != digito2) return false;

    // Passou por tudo = CPF é real!
    return true;
  }

  // Monta o campo na tela
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      // Conecta o controller
      controller: controller,

      // Função opcional que roda a cada tecla
      onChanged: onChanged,

      // Valida em tempo real enquanto o usuário digita (não espera apertar o botão)
      autovalidateMode: AutovalidateMode.onUserInteraction,

      // Abre o teclado numérico (só números)
      keyboardType: TextInputType.number,

      // Conecta nosso formatador que coloca os pontos e traço automaticamente
      inputFormatters: [CpfInputFormatter()],

      // Visual do campo
      decoration: InputDecoration(
        label: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: label ?? 'CPF'),
              const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        prefixIcon: const Icon(Icons.badge_outlined),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        border: const OutlineInputBorder(),

        // Compacta o campo
        isDense: true,

        // Padding interno
        contentPadding: const EdgeInsets.fromLTRB(0, 14, 12, 14),

        // Texto de erro menor
        errorStyle: const TextStyle(fontSize: 11, height: 0.8),
      ),

      // Validação que roda quando o formulário pede
      validator: (value) {
        // Campo vazio = erro
        if (value == null || value.isEmpty) {
          return 'Informe o seu CPF';
        }

        // Quando terminou de digitar (14 chars = 11 números + 2 pontos + 1 traço),
        // aí sim a gente valida se é um CPF real
        if (value.length == 14 && !isCpfValido(value)) {
          return 'CPF inválido. Verifique os números.';
        }

        // Se ainda tá digitando, mostra quantos caracteres faltam
        if (value.isNotEmpty && value.length < 14) {
          return 'Complete os 11 dígitos (Faltam ${14 - value.length} caracteres)';
        }

        // Tudo certo!
        return null;
      },
    );
  }
}
