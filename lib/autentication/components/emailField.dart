// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote do Flutter que tem tudo que a gente precisa pra montar telas
import 'package:flutter/material.dart';

// Campo de e-mail reutilizável — pode ser usado em qualquer tela do app
// (login, cadastro, recuperação de senha, etc.)
// É um StatelessWidget porque não guarda nenhum estado interno que muda:
// quem precisa guardar o texto é o controller, que vem de fora
class EmailField extends StatelessWidget {
  // controller = o "caderno" que anota tudo que o usuário digita no campo
  // Mantemos ele fora do widget (na tela pai) para poder ler o valor ao submeter
  final TextEditingController controller;

  // label = o textinho que aparece em cima do campo
  // Se não passar nada, usa "E-mail" como padrão
  // Útil se quiser reaproveitar com "E-mail de recuperação" ou outro label
  final String? label;

  // onChanged = uma função opcional que roda toda vez que o usuário digita uma letra
  // Pode ser usada, por exemplo, para habilitar/desabilitar o botão de envio
  final void Function(String)? onChanged;

  // Construtor do componente
  // O "required" significa que esse parâmetro é obrigatório na hora de usar
  // A chave super.key é importante para o sistema de reconciliação de widgets do Flutter
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
    // A diferença do TextField comum é que ele participa do sistema de validação do Form
    return TextFormField(
      // Conecta o controller pra gente conseguir ler o texto depois
      controller: controller,

      // Abre o teclado de e-mail no celular (aquele que já tem o @ fácil de achar)
      // Melhora a experiência do usuário por não precisar navegar até o símbolo @
      keyboardType: TextInputType.emailAddress,

      // Se passaram uma função onChanged, ela roda a cada letra digitada
      onChanged: onChanged,

      // Decoration = a "roupa" do campo (ícone, borda, texto de ajuda, etc.)
      decoration: InputDecoration(
        // Texto que aparece em cima do campo (label flutuante do Material Design)
        // Usamos Text.rich para adicionar o asterisco vermelho indicando obrigatoriedade
        label: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: label ?? 'E-mail'),
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),

        // Ícone de envelope na esquerda do campo
        // Ajuda o usuário a identificar visualmente que é um campo de e-mail
        prefixIcon: const Icon(Icons.email_outlined),

        // Reduz a área do ícone pra alinhar o erro com a borda da caixa
        // Sem isso, o ícone ocupa mais espaço do que precisa
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),

        // Borda retangular ao redor do campo (padrão do app)
        border: const OutlineInputBorder(),

        // Compacta o campo pra ocupar menos espaço vertical na tela
        isDense: true,

        // Padding interno do campo — dá um pouco de espaço para o texto não colar na borda
        contentPadding: const EdgeInsets.fromLTRB(0, 14, 12, 14),

        // Texto de erro menor pra não empurrar os campos de baixo na tela
        errorStyle: const TextStyle(fontSize: 11, height: 0.8),
      ),

      // Validação que roda quando o formulário chama validate()
      // Retorna null se tudo estiver ok, retorna string com mensagem de erro caso contrário
      validator: (value) {
        // Se o campo tá vazio, mostra essa mensagem de erro
        if (value == null || value.isEmpty) return 'Informe seu e-mail';

        // Validação simples: verifica se tem o símbolo @
        // Uma validação mais robusta usaria regex, mas essa já filtra a maioria dos erros
        if (!value.contains('@')) return 'E-mail inválido';

        // Se passou por tudo, retorna null = sem erros
        return null;
      },
    );
  }
}
