// Importa o pacote do Flutter com tudo que precisamos pra montar a interface
import 'package:flutter/material.dart';

// Campo de senha que pode ser reutilizado em qualquer tela
// É StatefulWidget porque tem o estado do olhinho (mostrando/escondendo a senha)
class PasswordField extends StatefulWidget {
  // controller = guarda o texto que o usuário tá digitando
  final TextEditingController controller;

  // label = texto que aparece no campo (se não passar, usa "Senha")
  final String? label;

  // isCadastro = quando é true, ativa validações mais rigorosas
  // (letra maiúscula, número, caractere especial, etc.)
  final bool isCadastro;

  // confirmController = se passar esse parâmetro, o campo valida em tempo real
  // se a senha digitada aqui é igual à senha do outro campo
  // Usado no campo "Confirmar Senha" pra comparar com o campo "Senha"
  final TextEditingController? confirmController;

  // onChanged = função opcional que roda a cada tecla pressionada
  final void Function(String)? onChanged;

  // Construtor - o controller é obrigatório, o resto é opcional
  const PasswordField({
    super.key,
    required this.controller,
    this.label,
    this.onChanged,
    this.isCadastro = false,
    this.confirmController,
  });

  // Cria o estado do widget (é aqui que mora a variável _obscure)
  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

// Classe de estado - aqui ficam as variáveis que mudam e a parte visual
class _PasswordFieldState extends State<PasswordField> {
  // _obscure controla se a senha tá escondida (true) ou visível (false)
  // Começa escondida por segurança
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    // Atualiza a tela a cada tecla se for o campo de senha de cadastro
    if (widget.isCadastro && widget.confirmController == null) {
      widget.controller.addListener(_onTextChanged);
    }
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (widget.isCadastro && widget.confirmController == null) {
      widget.controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  // Gera o texto dinâmico mostrando apenas o que falta
  String? _getMissingRequirements() {
    if (!widget.isCadastro || widget.confirmController != null) return null;
    
    final value = widget.controller.text;
    if (value.isEmpty) {
      return 'A senha precisa de 6+ caracteres, contendo letra maiúscula, número e símbolo especial.';
    }

    List<String> faltam = [];
    if (value.length < 6) faltam.add('6+ caracteres');
    if (!value.contains(RegExp(r'[A-Z]'))) faltam.add('letra maiúscula');
    if (!value.contains(RegExp(r'[0-9]'))) faltam.add('número');
    if (!value.contains(RegExp(r'[!@#$%^&*]'))) faltam.add('símbolo especial');
    if (value.contains(RegExp(r'\s'))) faltam.add('remover espaços');

    if (faltam.isEmpty) return 'Senha forte e válida!';
    return 'Faltam: ${faltam.join(', ')}';
  }

  // Função que valida a senha e retorna a mensagem de erro (ou null se tá ok)
  String? _validarSenha(String? value) {
    // Se o campo tá vazio, já retorna erro direto
    if (value == null || value.isEmpty) return 'Informe sua senha';

    // Se tem um confirmController, significa que esse campo é o "Confirmar Senha"
    // Então a gente compara em tempo real com o campo de senha principal
    if (widget.confirmController != null) {
      if (value != widget.confirmController!.text) {
        return 'As senhas não são iguais';
      }
    }

    // Essas regras só valem na tela de cadastro (não no login)
    if (widget.isCadastro) {
      // Senha precisa ter pelo menos 6 caracteres
      if (value.length < 6) return 'Senha muito curta';

      // Precisa ter pelo menos uma letra maiúscula (A-Z)
      if (!value.contains(RegExp(r'[A-Z]'))) {
        return 'A senha precisa ter uma letra maiúscula';
      }

      // Precisa ter pelo menos um número (0-9)
      if (!value.contains(RegExp(r'[0-9]'))) {
        return 'A senha precisa ter um número';
      }

      // Precisa ter pelo menos um caractere especial (!@#$%^&*)
      if (!value.contains(RegExp(r'[!@#$%^&*]'))) {
        return 'A senha precisa ter um caractere especial';
      }

      // Não pode ter espaços no meio
      if (value.contains(RegExp(r'\s'))) {
        return 'A senha não pode conter espaços';
      }
    }

    // Se chegou até aqui sem retornar erro, a senha tá válida
    return null;
  }

  // Monta o visual do campo na tela
  @override
  Widget build(BuildContext context) {
    // TextFormField = campo de texto que funciona dentro de um Form
    return TextFormField(
      // Conecta com o controller que veio lá da tela pai (signup ou signin)
      controller: widget.controller,

      // obscureText = quando true, mostra bolinhas em vez das letras
      obscureText: _obscure,

      // Se passaram uma função onChanged, ela roda a cada tecla
      onChanged: widget.onChanged,

      // Se tem confirmController, valida em tempo real enquanto digita
      // Assim o erro "As senhas não são iguais" aparece/desaparece na hora
      autovalidateMode: widget.confirmController != null
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,

      // Visual do campo
      decoration: InputDecoration(
        // Texto do campo (usa o label que passaram ou "Senha" como padrão)
        label: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: widget.label ?? 'Senha'),
              const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),

        // Ícone de cadeado na esquerda
        prefixIcon: const Icon(Icons.lock_outline),

        // Reduz a área do ícone pra alinhar o erro com a borda da caixa
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),

        // Borda retangular
        border: const OutlineInputBorder(),

        // Compacta o campo pra ocupar menos espaço
        isDense: true,

        // Padding interno do campo
        contentPadding: const EdgeInsets.fromLTRB(0, 14, 12, 14),

        // Texto auxiliar dinâmico que mostra apenas o que falta preencher
        helperText: _getMissingRequirements(),
        helperMaxLines: 2,
        helperStyle: _getMissingRequirements() == 'Senha forte e válida!'
            ? const TextStyle(color: Colors.greenAccent)
            : null,

        // Texto de erro menor pra não empurrar os campos de baixo
        errorStyle: const TextStyle(fontSize: 11, height: 0.8),

        // Botão do olhinho na direita do campo
        // Quando clica, alterna entre mostrar e esconder a senha
        suffixIcon: IconButton(
          // Muda o ícone: olho fechado quando tá escondido, olho aberto quando tá visível
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),

          // Ao clicar, inverte o valor de _obscure (true vira false e vice-versa)
          // setState avisa o Flutter pra redesenhar o campo com o novo estado
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),

      // Chama nossa função de validação quando o formulário pede
      validator: (value) {
        return _validarSenha(value);
      },
    );
  }
}
