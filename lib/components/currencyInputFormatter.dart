// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa os serviços do Flutter. Aqui a gente pega o TextInputFormatter,
// que é a classe mãe que permite criar os formatadores de texto.
import 'package:flutter/services.dart';

// O intl (internationalization) é o cara que salva a gente na hora de
// converter números pro formato maluco de cada país.
import 'package:intl/intl.dart';

/// Um formatador de campo que digita de trás pra frente simulando dinheiro.
/// Se você já usou app de banco, sabe do que eu tô falando.
/// O usuário só bate nos números e a vírgula vai andando pra esquerda.
/// Ex: Digita "1" -> R$ 0,01. Digita "2" -> R$ 0,12. Digita "3" -> R$ 1,23.
class CurrencyInputFormatter extends TextInputFormatter {
  /// Essa função é chamada pelo Flutter a cada micro-momento que o usuário encosta no teclado.
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, // O que tava lá antes dele apertar a tecla.
    TextEditingValue newValue, // O que vai aparecer agora.
  ) {
    // Se o cara apagou tudo, a gente não formata, só devolve vazio.
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Passa um Regex (expressão regular) pra arrancar fora qualquer coisa que não seja número.
    // Assim, se ele tentar colar "R$ 10,00 reais", a gente extrai só "1000".
    String digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Se ele apagou os números e ficou só lixo, consideramos zero.
    if (digits.isEmpty) digits = '0';

    // A mágica dos centavos: como os 2 últimos dígitos são sempre os centavos,
    // a gente pega a string "1234", converte pro double 1234.0, e divide por 100 -> 12.34.
    double value = double.parse(digits) / 100;

    // Chama nosso método maroto ali debaixo pra botar no padrão "R$ 12,34".
    String newText = formatValue(value);

    // Devolve pro campo de texto já mastigado.
    return TextEditingValue(
      text: newText,
      // Detalhe sutil mas crucial: sempre jogamos o cursor de digitação pro final.
      // Se não fizer isso, o cursor volta pro começo da linha toda vez que ele digita, e o usuário fica doido.
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  /// Pega um double cru (tipo 1500.5) e devolve "R$ 1.500,50".
  /// Como é static, dá pra chamar de qualquer lugar do app sem ter que dar "new CurrencyInputFormatter()".
  static String formatValue(double value) {
    // NumberFormat do pt_BR já sabe que usamos ponto de milhar e vírgula de decimal.
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatter.format(value);
  }
}
