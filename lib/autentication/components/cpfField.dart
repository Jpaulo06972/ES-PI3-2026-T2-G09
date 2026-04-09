import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import necessário para usarmos o TextInputFormatter

// -----------------------------------------------------------------------------
// Formatador de CPF Customizado
// Esta classe é responsável por formatar o texto ENQUANTO o usuário digita,
// colocando os pontos (.) e o traço (-) automaticamente.
// -----------------------------------------------------------------------------
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    
    // 1. Pega o novo texto e remove tudo que não for número (ex: se o usuário tentar colar letras)
    String numbers = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // 2. Trava a quantidade de dígitos no máximo em 11 (Tamanho de um CPF real)
    if (numbers.length > 11) {
      numbers = numbers.substring(0, 11);
    }
    
    // 3. Constrói a string formatada adicionando o '.' e o '-' nas posições corretas
    String formatted = '';
    for (int i = 0; i < numbers.length; i++) {
      // Após o 3º e 6º número, colocamos um ponto
      if (i == 3 || i == 6) {
        formatted += '.';
      } 
      // Após o 9º número, colocamos um traço
      else if (i == 9) {
        formatted += '-';
      }
      // Adicionamos o número atual à string formatada
      formatted += numbers[i];
    }
    
    // 4. Retorna para o TextFormField o valor modificado, colocando o cursor piscando no final
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// -----------------------------------------------------------------------------
// Componente de Campo de CPF
// -----------------------------------------------------------------------------
class CpfField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final void Function(String)? onChanged;

  const CpfField({
    super.key,
    required this.controller,
    this.label,
    this.onChanged,
  });

  // Função interna para validar matematicamente se o CPF é real
  bool isCpfValido(String? cpf) {
    // Se estiver vazio, não é válido
    if (cpf == null || cpf.isEmpty) return false;

    // Remove pontos e traços para fazer a conta apenas com os números
    String numeros = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    // Para ser CPF válido, PRECISA ter exatamente 11 dígitos
    if (numeros.length != 11) return false;

    // Rejeita CPFs óbvios formados por repetidos (ex: 111.111.111-11 é inválido pela Receita Federal)
    if (RegExp(r'^(\d)\1*$').hasMatch(numeros)) return false;

    // Converte a string (ex: "123") para uma lista de números inteiros [1, 2, 3]
    List<int> digitos = numeros.split('').map(int.parse).toList();

    // ------------------------------------------------
    // Cálculo do PRIMEIRO dígito verificador (penúltimo número)
    int calc1 = 0;
    for (int i = 0; i < 9; i++) {
      calc1 += digitos[i] * (10 - i); // Multiplica cada número por um peso decrescente
    }
    int resto1 = (calc1 * 10) % 11;
    int digito1 = resto1 == 10 ? 0 : resto1;

    // Se o dígito calculado não bater com o 10º número do CPF, ele é falso
    if (digitos[9] != digito1) return false;

    // ------------------------------------------------
    // Cálculo do SEGUNDO dígito verificador (último número)
    int calc2 = 0;
    for (int i = 0; i < 10; i++) {
      calc2 += digitos[i] * (11 - i);
    }
    int resto2 = (calc2 * 10) % 11;
    int digito2 = resto2 == 10 ? 0 : resto2;

    // Se o dígito calculado não bater com o 11º número do CPF, ele é falso
    if (digitos[10] != digito2) return false;

    // Passou por todas as validações, então o CPF é real!
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller, // Controlador que vai armazenar o valor pro 'Form' acessar
      onChanged: onChanged,   // Função opcional pra caso você queira monitorar digitação externa
      
      // onUserInteraction: FAZ A MÁGICA DE VALIDAR "AO VIVO" ENQUANTO DIGITA
      // Isso fará a mensagem de erro ficar aparecendo e sumindo na mesma hora.
      autovalidateMode: AutovalidateMode.onUserInteraction,
      
      keyboardType: TextInputType.number, // Abre o teclado de números do celular do usuário
      
      // inputFormatters: Lista de formatadores. Nós adicionamos o nosso CpfInputFormatter
      // criado lá em cima, para ir empurrando "." e "-" na tela!
      inputFormatters: [
        CpfInputFormatter(),
      ],
      
      // Decoração da caixa de texto
      decoration: InputDecoration(
        labelText: label ?? 'CPF',
        prefixIcon: const Icon(Icons.badge_outlined),
        border: const OutlineInputBorder(),
      ),
      
      // Onde de fato testamos e retornamos as mensagens de erro
      validator: (value) {
        // Se estiver em branco
        if (value == null || value.isEmpty) {
          return 'Informe o seu CPF';
        }
        
        // Chamando a nossa validação aqui apenas quando ele terminar de digitar os 14 caracteres
        // Explicando os 14 caracteres: 11 números + 2 pontos + 1 traço = 14
        if (value.length == 14 && !isCpfValido(value)) {
          return 'CPF inválido. Verifique os números.';
        }
        
        // Se o cara mal começou a digitar (menos de 14 chars), a gente não dá o aviso vermelho
        // super chato logo de cara. Mas se você quiser validar a cada tecla antes dos 14, basta remover o "value.length == 14".
        if (value.isNotEmpty && value.length < 14) {
          return 'Complete os 11 dígitos (Faltam ${14 - value.length} caracteres)';
        }

        // Se retornar null, o InputDecoration vai ficar "azul"/sem erro
        return null;
      },
    );
  }
}
