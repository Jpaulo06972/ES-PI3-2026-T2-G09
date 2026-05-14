// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote do Flutter com os widgets visuais
import 'package:flutter/material.dart';

// Campo de nome simples com ícone de pessoa
// Usado pra Nome e Sobrenome na tela de cadastro
// É StatelessWidget porque não tem nenhum estado que muda internamente
class NameField extends StatelessWidget {
  // controller = o caderno que anota o que foi digitado
  final TextEditingController controller;

  // label = texto do campo (pode ser "Nome", "Sobrenome", etc.)
  final String? label;

  // onChanged = função que roda a cada tecla (opcional)
  final void Function(String)? onChanged;

  // Construtor - controller é obrigatório
  const NameField({
    super.key,
    required this.controller,
    this.label,
    this.onChanged,
  });

  // Monta o campo na tela
  @override
  Widget build(BuildContext context) {
    // TextFormField = campo de texto com suporte a validação via Form
    return TextFormField(
      // Conecta o controller pra poder ler o texto depois
      controller: controller,

      // Se passaram onChanged, roda a cada letra digitada
      onChanged: onChanged,

      // Visual do campo
      decoration: InputDecoration(
        // Se não passaram label, usa "Nome" como padrão
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

        // Ícone de pessoa na esquerda do campo
        prefixIcon: const Icon(Icons.person_outline),

        // Reduz a área do ícone pra alinhar o erro com a borda da caixa
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),

        // Borda retangular ao redor
        border: const OutlineInputBorder(),

        // isDense reduz o padding interno do campo pra ficar mais compacto
        isDense: true,

        // Padding interno do campo
        contentPadding: const EdgeInsets.fromLTRB(0, 14, 12, 14),

        // Estilo do texto de erro: menor e mais junto da caixa
        errorStyle: const TextStyle(fontSize: 11, height: 0.8),
      ),

      // Validação: verifica se o campo não tá vazio
      validator: (value) {
        if (value == null || value.isEmpty) {
          // Mensagem curta pra caber quando o campo tá no Row (Nome | Sobrenome)
          return 'Obrigatório';
        }
        // Se preencheu, tá tudo certo
        return null;
      },
    );
  }
}
