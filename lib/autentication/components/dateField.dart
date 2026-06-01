// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote do Flutter pra montar a interface
import 'package:flutter/material.dart';

// Campo de data de nascimento que abre um calendário quando o usuário toca
// Evita que alguém digite uma data errada (tipo dia 32 ou mês 13)
// Também verifica se o usuário tem pelo menos 18 anos
// É StatefulWidget porque precisa guardar a data selecionada internamente
// (precisamos da data como DateTime pra validar a idade, não só como texto)
class DateField extends StatefulWidget {
  // controller = guarda a data como texto no formato DD/MM/AAAA
  // É passado de fora pra que a tela pai consiga ler o valor depois
  final TextEditingController controller;

  // label = texto do campo (padrão: "Data de Nasc.")
  final String? label;

  // onDateSelected = função que roda quando o usuário escolhe uma data no calendário
  // Útil quando a tela pai precisa do DateTime completo (não só o texto)
  final void Function(DateTime)? onDateSelected;

  // Construtor - controller é obrigatório para que a tela pai leia o valor
  const DateField({
    super.key,
    required this.controller,
    this.label,
    this.onDateSelected,
  });

  // Cria o estado interno do widget — aqui ficam as variáveis que mudam
  @override
  State<DateField> createState() => _DateFieldState();
}

// Classe de estado - aqui fica a lógica do calendário e a validação
class _DateFieldState extends State<DateField> {
  // Guarda a data que o usuário escolheu como objeto DateTime
  // Começa null porque nenhuma data foi selecionada ainda
  // Precisamos guardar o DateTime (não só o texto) para calcular a idade corretamente
  DateTime? _selectedDate;

  // Pega um DateTime (ex: 2001-03-15) e transforma em texto bonito "15/03/2001"
  // padLeft(2, '0') garante que sempre tenha 2 dígitos (5 vira 05)
  String _formatDate(DateTime date) {
    // padLeft(2, '0') garante que sempre tenha 2 dígitos (5 vira 05)
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  // Abre o calendário na tela do celular
  // É async porque precisa esperar o usuário escolher uma data (operação assíncrona)
  Future<void> _pickDate() async {
    // showDatePicker é uma função do Flutter que mostra o calendário nativo
    // Retorna a data escolhida ou null se o usuário cancelou
    final picked = await showDatePicker(
      context: context,

      // Data que já vem marcada quando o calendário abre
      // Se já escolheu antes, mostra aquela. Se não, mostra 18 anos atrás
      // (porque o app exige 18+ anos, então essa é a data mais provável)
      initialDate: _selectedDate ?? DateTime(DateTime.now().year - 18),

      // A data mais antiga que pode selecionar (120 anos no passado)
      // Garante que ninguém coloque uma data absurda como 1800
      firstDate: DateTime(DateTime.now().year - 120),

      // A data mais recente (hoje) — não pode escolher data no futuro
      lastDate: DateTime.now(),

      // Textos em português no calendário para melhor UX
      helpText: 'Selecione sua data de nascimento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    // Se o usuário realmente escolheu uma data (não apertou cancelar)
    if (picked != null) {
      // setState avisa o Flutter que algo mudou e precisa redesenhar o widget
      setState(() {
        // Salva a data escolhida como DateTime para usar na validação de idade
        _selectedDate = picked;

        // Coloca o texto formatado no controller para aparecer no campo
        // e para que a tela pai possa ler via controller.text
        widget.controller.text = _formatDate(picked);
      });

      // Se a tela pai passou uma função onDateSelected, chama ela com o DateTime
      // O ?. (null safety) evita erro se não passou a função
      widget.onDateSelected?.call(picked);
    }
  }

  // Monta o campo na tela
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      // Conecta o controller para exibir e compartilhar o texto com a tela pai
      controller: widget.controller,

      // readOnly = o teclado NÃO abre quando toca no campo
      // Queremos que abra o calendário (via onTap), não o teclado
      // Sem isso, abriria o teclado E o calendário ao mesmo tempo
      readOnly: true,

      // Quando o usuário toca no campo, chama nossa função que abre o calendário
      onTap: _pickDate,

      // Visual do campo seguindo o padrão do app
      decoration: InputDecoration(
        // Texto do campo com asterisco vermelho indicando campo obrigatório
        label: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: widget.label ?? 'Data de Nasc.'),
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),

        // Ícone de calendário na esquerda — comunica visualmente que abre um calendário
        prefixIcon: const Icon(Icons.calendar_today_outlined),

        // Reduz a área do ícone para manter o alinhamento com os outros campos
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),

        // Borda retangular padrão do app
        border: const OutlineInputBorder(),

        // Compacta o campo para economizar espaço vertical na tela de cadastro
        isDense: true,

        // Padding interno
        contentPadding: const EdgeInsets.fromLTRB(0, 14, 12, 14),

        // Texto de erro menor para não empurrar os campos de baixo
        errorStyle: const TextStyle(fontSize: 11, height: 0.8),

        // Texto fantasma que aparece quando o campo tá vazio
        // Mostra o formato esperado para orientar o usuário
        hintText: 'DD/MM/AAAA',
      ),

      // Validação que roda quando o formulário chama validate()
      validator: (value) {
        // Se não selecionou nenhuma data, mostra erro
        if (value == null || value.isEmpty) {
          return 'Selecione sua data de nascimento';
        }

        // Verifica se a pessoa tem pelo menos 18 anos
        // Só faz essa verificação se _selectedDate não é null (ou seja, se uma data foi escolhida)
        if (_selectedDate != null) {
          final hoje = DateTime.now();

          // Cálculo inicial: ano atual menos ano de nascimento
          int idade = hoje.year - _selectedDate!.year;

          // Mas tem um detalhe importante: se a pessoa AINDA NÃO fez aniversário ESSE ANO,
          // a idade real é 1 a menos do que a subtração simples
          // Exemplo: nasceu em dezembro/2008, hoje é abril/2026
          // 2026 - 2008 = 18, mas dezembro ainda não chegou, então tem apenas 17
          final aindaNaoFezAniversario =
              (hoje.month < _selectedDate!.month) ||
              (hoje.month == _selectedDate!.month &&
                  hoje.day < _selectedDate!.day);

          // Se ainda não fez aniversário este ano, subtrai 1 da idade calculada
          if (aindaNaoFezAniversario) idade--;

          // Se tem menos de 18 anos, mostra o erro de restrição de idade
          if (idade < 18) {
            return 'Você precisa ter pelo menos 18 anos';
          }
        }

        // Passou por tudo sem erros = data válida!
        return null;
      },
    );
  }
}
