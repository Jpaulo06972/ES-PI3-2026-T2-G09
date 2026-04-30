// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote do Flutter pra montar a interface
import 'package:flutter/material.dart';

// Botão principal do app - aquele verdão/azulão que aparece em todas as telas
// Agora com suporte a loading: quando tá processando, mostra uma bolinha girando
// e bloqueia novos cliques pra evitar envio duplicado
class PrimaryButton extends StatelessWidget {
  // label = o texto que aparece dentro do botão (ex: "Entrar", "Concluir Cadastro")
  final String label;

  // onPressed = a função que roda quando o usuário clica no botão
  // VoidCallback = função que não recebe nada e não retorna nada
  final VoidCallback onPressed;

  // isLoading = quando true, mostra um loading giratório e desabilita o botão
  // Útil pra quando tá esperando resposta da API (evita clique duplo)
  final bool isLoading;

  // Construtor - label e onPressed são obrigatórios, isLoading é opcional (padrão: false)
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  // Monta o botão na tela
  @override
  Widget build(BuildContext context) {
    // ElevatedButton = botão elevado (com sombra e cor de fundo)
    return ElevatedButton(
      // Se tá carregando, passa null pro onPressed = botão fica desabilitado (cinza)
      // Se não tá carregando, funciona normal
      onPressed: isLoading ? null : onPressed,

      // Estilo visual do botão
      style: ElevatedButton.styleFrom(
        // Espaçamento interno (dá uma altura confortável pro botão)
        padding: const EdgeInsets.symmetric(vertical: 12),

        // Cantos arredondados (8 pixels de raio)
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

        // Cor de fundo = pega a cor primária do tema do app (verde/azul)
        backgroundColor: Theme.of(context).colorScheme.primary,

        // Cor do texto = pega a cor que contrasta com o fundo
        foregroundColor: Theme.of(context).colorScheme.onPrimary,

        // Cor quando o botão tá desabilitado (durante o loading)
        // Usa a mesma cor primária mas com opacidade pra parecer "meio apagado"
        disabledBackgroundColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.6),
        disabledForegroundColor: Colors.white70,
      ),

      // Se tá carregando, mostra a bolinha girando
      // Se não, mostra o texto normal
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
    );
  }
}
