// Importa o pacote do Flutter que tem tudo que a gente precisa pra montar telas
import 'package:flutter/material.dart';

// Campo de e-mail que a gente pode reaproveitar em qualquer tela do app
// É um StatelessWidget porque não tem nenhum estado interno que muda
class EmailField extends StatelessWidget {
  // controller = o "caderno" que anota tudo que o usuário digita no campo
  final TextEditingController controller;

  // label = o textinho que aparece em cima do campo (se não passar nada, usa "E-mail")
  final String? label;

  // onChanged = uma função opcional que roda toda vez que o usuário digita uma letra
  final void Function(String)? onChanged;

  // Construtor do componente
  // O "required" significa que esse parâmetro é obrigatório na hora de usar
  const EmailField({
    super.key,
    required this.controller,
    this.label,
    this.onChanged,
  });

  // Aqui a gente monta o visual do campo na tela
  @override
  Widget build(BuildContext context) {
    // TextFormField é o campo de texto do Flutter que funciona dentro de um Form
    return TextFormField(
      // Conecta o controller pra gente conseguir ler o texto depois
      controller: controller,

      // Abre o teclado de e-mail no celular (aquele que já tem o @ fácil de achar)
      keyboardType: TextInputType.emailAddress,

      // Se passaram uma função onChanged, ela roda a cada letra digitada
      onChanged: onChanged,

      // Decoration = a "roupa" do campo (ícone, borda, texto de ajuda)
      decoration: InputDecoration(
        // Texto que aparece em cima do campo
        labelText: label ?? 'E-mail',

        // Ícone de envelope na esquerda do campo
        prefixIcon: const Icon(Icons.email_outlined),

        // Reduz a área do ícone pra alinhar o erro com a borda da caixa
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),

        // Borda retangular ao redor do campo
        border: const OutlineInputBorder(),

        // Compacta o campo pra ocupar menos espaço vertical
        isDense: true,

        // Padding interno do campo
        contentPadding: const EdgeInsets.fromLTRB(0, 14, 12, 14),

        // Texto de erro menor pra não empurrar os campos de baixo
        errorStyle: const TextStyle(fontSize: 11, height: 0.8),
      ),

      // Validação que roda quando o formulário chama validate()
      validator: (value) {
        // Se o campo tá vazio, mostra essa mensagem de erro
        if (value == null || value.isEmpty) return 'Informe seu e-mail';

        // Se não tem @, não é um e-mail válido
        if (!value.contains('@')) return 'E-mail inválido';

        // Se passou por tudo, retorna null = tá tudo certo
        return null;
      },
    );
  }
}
