// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote do Flutter pra montar a interface
import 'package:flutter/material.dart';

// Botão principal do app — o botão verde que aparece em todas as telas de autenticação
// Suporta estado de loading: quando está processando, mostra uma bolinha girando
// e bloqueia novos cliques para evitar envio duplicado (clique duplo acidental)
// É StatelessWidget porque não guarda estado interno — quem controla o isLoading
// é a tela pai, que sabe quando a requisição começou e terminou
class PrimaryButton extends StatelessWidget {
  // label = o texto que aparece dentro do botão
  // Exemplos: "Entrar", "Concluir Cadastro", "Enviar código"
  final String label;

  // onPressed = a função que roda quando o usuário clica no botão
  // VoidCallback = tipo do Dart para uma função que não recebe nem retorna nada
  final VoidCallback onPressed;

  // isLoading = quando true, mostra o CircularProgressIndicator e desabilita o botão
  // Evita que o usuário clique de novo enquanto a operação está em andamento
  final bool isLoading;

  // Construtor — label e onPressed são obrigatórios
  // isLoading tem padrão false: por padrão o botão está pronto para ser clicado
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  // Monta o botão na tela
  @override
  Widget build(BuildContext context) {
    // ElevatedButton = botão "elevado" do Material Design (com fundo colorido e leve sombra)
    return ElevatedButton(
      // Quando isLoading é true, passamos null para onPressed
      // No Flutter, passar null para onPressed desabilita o botão automaticamente
      // (fica cinza e não responde a cliques)
      onPressed: isLoading ? null : onPressed,

      // Estilo visual do botão
      style: ElevatedButton.styleFrom(
        // Padding vertical generoso para o botão ter uma altura confortável de clicar
        padding: const EdgeInsets.symmetric(vertical: 12),

        // Cantos arredondados (8 pixels de raio) — padrão visual do app
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

        // Cor de fundo: verde principal do MesclaInvest
        backgroundColor: const Color(0xFF107649),

        // Cor do texto/ícone: branco para contrastar com o fundo verde
        foregroundColor: Colors.white,

        // Cor quando o botão está desabilitado (durante o loading)
        // Usa a cor primária com menos opacidade para parecer "apagado"
        // sem sair totalmente do contexto visual
        disabledBackgroundColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.6),
        disabledForegroundColor: Colors.white70,
      ),

      // Conteúdo do botão: muda dependendo do estado de loading
      child: isLoading
          // Quando está carregando: mostra uma bolinha girando branca
          // SizedBox limita o tamanho para não esticar o botão
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,    // Linha fina para ficar elegante dentro do botão
                color: Colors.white,
              ),
            )
          // Quando não está carregando: mostra o texto normal do botão
          : Text(
              label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
    );
  }
}
