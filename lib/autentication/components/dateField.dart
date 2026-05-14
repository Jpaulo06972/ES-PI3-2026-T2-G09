// Importa o pacote do Flutter pra montar a interface
import 'package:flutter/material.dart';

// Campo de data de nascimento que abre um calendário quando o usuário toca
// Evita que alguém digite uma data errada (tipo dia 32 ou mês 13)
// Também verifica se o usuário tem pelo menos 18 anos
// É StatefulWidget porque precisa guardar a data selecionada internamente
class DateField extends StatefulWidget {
  // controller = guarda a data como texto no formato DD/MM/AAAA
  final TextEditingController controller;

  // label = texto do campo (padrão: "Data de Nasc.")
  final String? label;

  // onDateSelected = função que roda quando o usuário escolhe uma data no calendário
  final void Function(DateTime)? onDateSelected;

  // Construtor - controller é obrigatório
  const DateField({
    super.key,
    required this.controller,
    this.label,
    this.onDateSelected,
  });

  // Cria o estado interno do widget
  @override
  State<DateField> createState() => _DateFieldState();
}

// Classe de estado - aqui fica a lógica do calendário e a validação
class _DateFieldState extends State<DateField> {
  // Guarda a data que o usuário escolheu (começa null = nada selecionado ainda)
  DateTime? _selectedDate;

  // Pega um DateTime (ex: 2001-03-15) e transforma em texto bonito "15/03/2001"
  String _formatDate(DateTime date) {
    // padLeft(2, '0') garante que sempre tenha 2 dígitos (5 vira 05)
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  // Abre o calendário na tela do celular
  // É async porque precisa esperar o usuário escolher uma data
  Future<void> _pickDate() async {
    // showDatePicker é uma função do Flutter que mostra o calendário nativo
    // Retorna a data escolhida ou null se o usuário cancelou
    final picked = await showDatePicker(
      context: context,

      // Data que já vem marcada quando o calendário abre
      // Se já escolheu antes, mostra aquela. Se não, mostra 18 anos atrás
      initialDate: _selectedDate ?? DateTime(DateTime.now().year - 18),

      // A data mais antiga que pode selecionar (120 anos no passado)
      firstDate: DateTime(DateTime.now().year - 120),

      // A data mais recente (hoje - não pode escolher data no futuro)
      lastDate: DateTime.now(),

      // Textos em português no calendário
      helpText: 'Selecione sua data de nascimento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    // Se o usuário realmente escolheu uma data (não apertou cancelar)
    if (picked != null) {
      // setState avisa o Flutter que algo mudou e precisa redesenhar
      setState(() {
        // Salva a data escolhida na memória do componente
        _selectedDate = picked;

        // Coloca o texto formatado no controller pra aparecer no campo
        widget.controller.text = _formatDate(picked);
      });

      // Se a tela pai passou uma função onDateSelected, chama ela
      // Isso é útil pra quando quiser mandar o DateTime pra uma API depois
      widget.onDateSelected?.call(picked);
    }
  }

  // Monta o campo na tela
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      // Conecta o controller
      controller: widget.controller,

      // readOnly = o teclado NÃO abre quando toca no campo
      // A gente quer que abra o calendário, não o teclado
      readOnly: true,

      // Quando o usuário toca no campo, abre o calendário
      onTap: _pickDate,

      // Visual do campo
      decoration: InputDecoration(
        // Texto do campo
        label: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: widget.label ?? 'Data de Nasc.'),
              const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),

        // Ícone de calendário na esquerda
        prefixIcon: const Icon(Icons.calendar_today_outlined),

        // Reduz a área do ícone
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),

        // Borda retangular
        border: const OutlineInputBorder(),

        // Compacta o campo
        isDense: true,

        // Padding interno
        contentPadding: const EdgeInsets.fromLTRB(0, 14, 12, 14),

        // Texto de erro menor
        errorStyle: const TextStyle(fontSize: 11, height: 0.8),

        // Texto fantasma que aparece quando o campo tá vazio
        hintText: 'DD/MM/AAAA',
      ),

      // Validação
      validator: (value) {
        // Se não selecionou nenhuma data, mostra erro
        if (value == null || value.isEmpty) {
          return 'Selecione sua data de nascimento';
        }

        // Verifica se a pessoa tem pelo menos 18 anos
        if (_selectedDate != null) {
          final hoje = DateTime.now();

          // Calcula a idade: ano atual menos ano de nascimento
          int idade = hoje.year - _selectedDate!.year;

          // Mas tem um detalhe: se a pessoa AINDA NÃO fez aniversário esse ano,
          // a idade real é 1 a menos
          // Exemplo: nasceu em dezembro/2008, hoje é abril/2026
          // 2026 - 2008 = 18, mas dezembro ainda não chegou, então tem 17
          final aindaNaoFezAniversario =
              (hoje.month < _selectedDate!.month) ||
              (hoje.month == _selectedDate!.month &&
                  hoje.day < _selectedDate!.day);

          // Se ainda não fez aniversário, subtrai 1 da idade
          if (aindaNaoFezAniversario) idade--;

          // Se tem menos de 18, mostra erro
          if (idade < 18) {
            return 'Você precisa ter pelo menos 18 anos';
          }
        }

        // Passou por tudo = tá válido!
        return null;
      },
    );
  }
}
