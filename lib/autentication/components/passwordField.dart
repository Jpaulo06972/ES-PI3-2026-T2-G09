// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote do Flutter com tudo que precisamos pra montar a interface
import 'package:flutter/material.dart';

// Campo de senha reutilizável que pode ser usado em qualquer tela do app
// É StatefulWidget porque guarda internamente o estado do "olhinho"
// (se a senha está visível ou escondida), que muda quando o usuário clica
class PasswordField extends StatefulWidget {
  // controller = guarda o texto que o usuário tá digitando
  // Mantemos fora do widget (na tela pai) para poder ler ao submeter o formulário
  final TextEditingController controller;

  // label = texto que aparece no campo
  // Se não passar, usa "Senha" como padrão
  final String? label;

  // isCadastro = quando true, ativa validações mais rigorosas
  // (letra maiúscula, número, caractere especial, comprimento mínimo)
  // No login, a senha não precisa passar por essas regras
  final bool isCadastro;

  // confirmController = se passar esse parâmetro, o campo valida em tempo real
  // se a senha digitada aqui é igual à senha do outro campo
  // Usado no campo "Confirmar Senha" para comparar com o campo "Senha"
  final TextEditingController? confirmController;

  // onChanged = função opcional que roda a cada tecla pressionada
  // Pode ser útil para disparar validação em outros campos do formulário
  final void Function(String)? onChanged;

  // Construtor — controller é obrigatório, o resto é opcional com padrões razoáveis
  const PasswordField({
    super.key,
    required this.controller,
    this.label,
    this.onChanged,
    this.isCadastro = false,  // Padrão false = modo login (validação simples)
    this.confirmController,
  });

  // Cria o estado do widget — é aqui que mora a variável _obscure
  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

// Classe de estado — aqui ficam as variáveis que mudam e a parte visual
class _PasswordFieldState extends State<PasswordField> {
  // _obscure controla se a senha tá escondida (true) ou visível (false)
  // Começa true (escondida) por segurança — não queremos expor a senha por padrão
  bool _obscure = true;

  // initState é chamado uma única vez quando o widget é criado na tela
  @override
  void initState() {
    super.initState();
    // Adiciona um "ouvinte" no controller da senha principal para que o campo
    // de dicas de força (helperText) seja atualizado enquanto o usuário digita
    // Só faz isso no campo de senha (não no campo de confirmação)
    if (widget.isCadastro && widget.confirmController == null) {
      widget.controller.addListener(_onTextChanged);
    }
  }

  // Chamado a cada vez que o texto da senha muda
  // Força o rebuild do widget para atualizar o helperText com as dicas restantes
  void _onTextChanged() {
    // mounted verifica se o widget ainda está na tela antes de chamar setState
    if (mounted) setState(() {});
  }

  // dispose é chamado quando o widget sai da tela — limpeza de memória
  @override
  void dispose() {
    // Remove o ouvinte que adicionamos, evitando memory leak
    if (widget.isCadastro && widget.confirmController == null) {
      widget.controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  // Gera o texto dinâmico mostrando apenas o que falta para a senha ficar forte
  // Retorna null se não for campo de cadastro (sem dicas no login)
  String? _getMissingRequirements() {
    // Só mostra dicas no campo de senha de cadastro (não no campo de confirmação)
    if (!widget.isCadastro || widget.confirmController != null) return null;

    final value = widget.controller.text;

    // Se o campo está vazio, mostra a descrição completa dos requisitos
    if (value.isEmpty) {
      return 'A senha precisa de 6+ caracteres, contendo letra maiúscula, número e símbolo especial.';
    }

    // Lista de requisitos que ainda faltam ser atendidos
    List<String> faltam = [];
    if (value.length < 6) faltam.add('6+ caracteres');
    if (!value.contains(RegExp(r'[A-Z]'))) faltam.add('letra maiúscula');
    if (!value.contains(RegExp(r'[0-9]'))) faltam.add('número');
    if (!value.contains(RegExp(r'[!@#$%^&*]'))) faltam.add('símbolo especial');
    if (value.contains(RegExp(r'\s'))) faltam.add('remover espaços');

    // Se a lista de "faltam" está vazia, todos os requisitos foram atendidos!
    if (faltam.isEmpty) return 'Senha forte e válida!';
    // Mostra o que falta de forma amigável: "Faltam: número, símbolo especial"
    return 'Faltam: ${faltam.join(', ')}';
  }

  // Função que valida a senha e retorna a mensagem de erro (ou null se tá ok)
  // Essa função é passada pro campo como validator do Form
  String? _validarSenha(String? value) {
    // Se o campo tá vazio, já retorna erro direto
    if (value == null || value.isEmpty) return 'Informe sua senha';

    // Se tem um confirmController, significa que esse campo é o "Confirmar Senha"
    // Compara em tempo real com o campo de senha principal
    if (widget.confirmController != null) {
      if (value != widget.confirmController!.text) {
        return 'As senhas não são iguais';
      }
    }

    // Essas regras extras só valem na tela de cadastro (não no login)
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

      // Precisa ter pelo menos um caractere especial dos listados
      if (!value.contains(RegExp(r'[!@#$%^&*]'))) {
        return 'A senha precisa ter um caractere especial';
      }

      // Não pode ter espaços — senhas com espaços causam problemas em muitos sistemas
      if (value.contains(RegExp(r'\s'))) {
        return 'A senha não pode conter espaços';
      }
    }

    // Se chegou até aqui sem retornar nenhum erro, a senha tá válida!
    return null;
  }

  // Monta o visual do campo na tela
  @override
  Widget build(BuildContext context) {
    // TextFormField = campo de texto que funciona dentro de um Form
    return TextFormField(
      // Conecta com o controller que veio lá da tela pai (signup ou signin)
      controller: widget.controller,

      // obscureText = quando true, mostra bolinhas (•••) em vez das letras da senha
      // Controlado pelo estado _obscure que o usuário altera clicando no olhinho
      obscureText: _obscure,

      // Se passaram uma função onChanged, ela roda a cada tecla
      onChanged: widget.onChanged,

      // Se tem confirmController (campo de confirmação), valida em tempo real
      // Assim o erro "As senhas não são iguais" aparece/desaparece conforme o usuário digita
      // Se não tem (campo de senha principal), desabilita a validação automática
      autovalidateMode: widget.confirmController != null
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,

      // Visual do campo
      decoration: InputDecoration(
        // Texto do campo com asterisco vermelho indicando obrigatoriedade
        label: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: widget.label ?? 'Senha'),
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),

        // Ícone de cadeado na esquerda — identifica visualmente como campo de senha
        prefixIcon: const Icon(Icons.lock_outline),

        // Reduz a área do ícone para manter o alinhamento com os outros campos
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),

        // Borda retangular padrão do app
        border: const OutlineInputBorder(),

        // Compacta o campo para ocupar menos espaço vertical
        isDense: true,

        // Padding interno do campo
        contentPadding: const EdgeInsets.fromLTRB(0, 14, 12, 14),

        // Texto auxiliar dinâmico que mostra apenas o que falta preencher
        // Aparece logo abaixo do campo, em verde quando tudo está ok
        helperText: _getMissingRequirements(),
        helperMaxLines: 2,
        // Se a mensagem for "Senha forte e válida!", muda a cor para verde
        helperStyle: _getMissingRequirements() == 'Senha forte e válida!'
            ? const TextStyle(color: Colors.greenAccent)
            : null,

        // Texto de erro menor para não empurrar os campos de baixo
        errorStyle: const TextStyle(fontSize: 11, height: 0.8),

        // Botão do olhinho na direita do campo
        // Alterna entre mostrar e esconder a senha quando clicado
        suffixIcon: IconButton(
          // Muda o ícone: olho fechado (visibility_off) quando tá escondido,
          // olho aberto (visibility) quando a senha está visível
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),

          // Ao clicar, inverte o valor de _obscure (true vira false e vice-versa)
          // setState avisa o Flutter para redesenhar o campo com o novo estado
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),

      // Chama nossa função de validação quando o formulário chama validate()
      validator: (value) {
        return _validarSenha(value);
      },
    );
  }
}
