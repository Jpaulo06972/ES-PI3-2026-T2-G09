// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:flutter/material.dart';

/// Um campo de texto super compacto que criamos para pedir o Nome e o Sobrenome.
/// Por que criar um componente só pra isso?
/// Lá no formulário de cadastro, a gente coloca o Nome e o Sobrenome lado a lado (numa Row).
/// Se a gente repetisse todo esse código lá, ia ficar uma bagunça. Criando um componente,
/// a gente segue a regra de ouro: DRY (Don't Repeat Yourself - Não se repita).
class NameField extends StatelessWidget {
  // O Controller é o "caderninho" desse campo. Tudo que o usuário digitar aqui,
  // fica salvo lá pra gente poder ler depois quando ele apertar o botão de salvar.
  final TextEditingController controller;

  // O texto que vai ficar em cima do campo (ex: "Nome", "Sobrenome").
  final String? label;

  // Função disparada a cada teclada que o usuário dá.
  // Útil se a gente quisesse, por exemplo, ir mostrando o nome dele num cartão em tempo real.
  final void Function(String)? onChanged;

  const NameField({
    super.key,
    required this.controller,
    this.label,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Usamos TextFormField (e não só TextField) porque ele permite fazer a validação automática.
    return TextFormField(
      controller: controller,
      onChanged: onChanged,

      // InputDecoration é onde a gente enfeita o nosso campo.
      decoration: InputDecoration(
        // Esse Text.rich é um macete legal. Ele permite ter duas cores no mesmo texto.
        // A gente usa pra colocar o nome normal e o asterisco vermelho (*) de obrigatório do lado.
        label: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: label ?? 'Campo'),
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),

        // Ícone de um bonequinho do lado esquerdo pra dar aquele charme visual.
        prefixIcon: const Icon(Icons.person_outline),

        // Diminui o espaço do ícone. Se a gente não fizer isso, quando der erro,
        // o texto de erro fica "flutuando" longe da borda, fica feio.
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),

        // A borda clássica de caixa em volta do campo.
        border: const OutlineInputBorder(),

        // isDense = true: Dá uma "espremida" no campo pra ele não ficar gigante na tela,
        // o que é perfeito já que temos dois campos lado a lado na nossa tela de cadastro.
        isDense: true,

        // Ajusta os espaços de dentro pra o texto não colar nas paredes da caixa.
        contentPadding: const EdgeInsets.fromLTRB(0, 14, 12, 14),

        // Quando dá erro, a fonte fica pequenininha (11) pra caber direitinho embaixo da caixa
        // sem esticar muito a tela pra baixo (height: 0.8).
        errorStyle: const TextStyle(fontSize: 11, height: 0.8),
      ),

      // Aqui é onde o TextFormField brilha.
      // Quando a gente chama `Form.validate()` lá no botão de Cadastrar, ele roda isso aqui.
      validator: (value) {
        // Se o cara esqueceu de preencher ou só deu espaço, barra ele.
        if (value == null || value.trim().isEmpty) {
          // Mensagem bem curta ("Obrigatório") pra não quebrar o layout,
          // já que os campos tão espremidos numa Row lá na tela de cadastro.
          return 'Obrigatório';
        }
        // Se retornar null, o Flutter entende: "Beleza, tá tudo certo, pode seguir!".
        return null;
      },
    );
  }
}
