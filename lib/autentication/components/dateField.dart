import 'package:flutter/material.dart';

// Componente reutilizável para selecionar a Data de Nascimento.
// Visualmente ele parece um campo de texto normal (igual ao EmailField, NameField, etc.),
// mas quando o usuário toca nele, abre um calendário para selecionar a data.
// Isso evita que alguém digite uma data errada (ex: 32/13/2020).
class DateField extends StatefulWidget {
  // "Props" — dados que a página de fora (signup.dart) envia para cá
  final TextEditingController controller; // O "caderno" que guarda a data selecionada como texto
  final String? label;                    // Texto que aparece em cima do campo (opcional)
  final void Function(DateTime)? onDateSelected; // Função chamada quando o usuário escolhe uma data

  const DateField({
    super.key,
    required this.controller, // Obrigatório: sem controller, não tem como ler a data depois
    this.label,
    this.onDateSelected,
  });

  // Como esse widget precisa guardar estado interno (a data selecionada),
  // ele é um StatefulWidget. A "parte visual" fica na classe abaixo.
  @override
  State<DateField> createState() => _DateFieldState();
}

// Essa é a classe de estado — aqui mora a lógica e o visual do componente.
class _DateFieldState extends State<DateField> {
  // Guarda a data que o usuário escolheu no calendário.
  // Começa como null porque nenhuma data foi selecionada ainda.
  DateTime? _selectedDate;

  // Pega um DateTime (ex: 2001-03-15) e transforma em texto bonito: "15/03/2001"
  // O padLeft(2, '0') garante que dia e mês sempre tenham 2 dígitos (ex: 5 vira 05)
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  // Essa função abre o calendário na tela quando o usuário toca no campo.
  // É async/await porque o calendário é uma "janela" que pausa o código
  // até o usuário escolher uma data ou cancelar.
  Future<void> _pickDate() async {
    // showDatePicker é uma função nativa do Flutter que exibe o calendário.
    // Ela retorna a data escolhida ou null se o usuário apertar "Cancelar".
    final picked = await showDatePicker(
      context: context,

      // A data que já vem selecionada quando o calendário abre.
      // Se o usuário já escolheu antes, mostra aquela. Senão, mostra 18 anos atrás.
      initialDate: _selectedDate ?? DateTime(DateTime.now().year - 18),

      // A data mais antiga que o usuário pode selecionar (120 anos no passado)
      firstDate: DateTime(DateTime.now().year - 120),

      // A data mais recente que o usuário pode selecionar (hoje — sem datas futuras)
      lastDate: DateTime.now(),

      // Textos que aparecem no calendário (já traduzidos pro português via localização)
      helpText: 'Selecione sua data de nascimento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    // Se o usuário realmente escolheu uma data (não apertou "Cancelar")...
    if (picked != null) {
      setState(() {
        // Salva a data escolhida na memória do componente
        _selectedDate = picked;

        // Coloca o texto formatado (ex: "15/03/2001") dentro do controller,
        // fazendo ele aparecer visualmente no campo de texto na tela
        widget.controller.text = _formatDate(picked);
      });

      // Se a página de fora passou uma função onDateSelected, chama ela
      // passando o DateTime completo (útil para enviar para API depois)
      widget.onDateSelected?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      // Conecta o controller ao campo (mesmo esquema do NameField, EmailField, etc.)
      controller: widget.controller,

      // readOnly: true = o teclado NUNCA abre. O campo só aceita toque.
      // Quando o usuário toca, o onTap dispara e abre o calendário.
      readOnly: true,
      onTap: _pickDate,

      // A parte visual do campo — idêntica aos outros componentes do projeto
      decoration: InputDecoration(
        labelText: widget.label ?? 'Data de Nasc.',
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        border: const OutlineInputBorder(),
        hintText: 'DD/MM/AAAA', // Texto fantasma que aparece quando o campo está vazio
      ),

      // Validação: o Flutter chama essa função quando _formKey.currentState!.validate() é acionado.
      // O "value" é o texto que está dentro do controller naquele momento (ex: "15/03/2001" ou "").
      validator: (value) {
        // Primeiro: verifica se o campo está vazio (o usuário não tocou no calendário)
        if (value == null || value.isEmpty) {
          return 'Selecione sua data de nascimento';
        }

        // Segundo: verifica se a pessoa tem pelo menos 18 anos
        if (_selectedDate != null) {
          final hoje = DateTime.now();

          // Calcula a idade de forma básica (ano atual - ano de nascimento)
          int idade = hoje.year - _selectedDate!.year;

          // Mas tem um detalhe: se a pessoa AINDA NÃO fez aniversário neste ano,
          // a idade real é 1 a menos. Exemplo:
          // Nasceu em 20/12/2008, hoje é 09/04/2026:
          // 2026 - 2008 = 18, MAS dezembro ainda não chegou → idade real = 17
          final aindaNaoFezAniversario =
              (hoje.month < _selectedDate!.month) ||
              (hoje.month == _selectedDate!.month &&
                  hoje.day < _selectedDate!.day);

          if (aindaNaoFezAniversario) idade--;

          if (idade < 18) {
            return 'Você precisa ter pelo menos 18 anos';
          }
        }

        // Se passou por todas as verificações, retorna null = campo válido!
        return null;
      },
    );
  }
}
