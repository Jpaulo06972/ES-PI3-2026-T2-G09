// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:flutter/material.dart';

/// Uma função que "sobe" aquele pop-up bonitão de sucesso na tela.
/// Sabe aquele "Parabéns, você acabou de comprar a startup XPTO"? É esse cara aqui.
///
/// Dica de arquitetura: por que isso é uma Função (Future) e não um Widget (StatelessWidget)?
/// Porque um dialog é uma tela sobreposta, e a gente precisa usar o `showDialog()`
/// para colocar ele na pilha de navegação. Retornando um Future, a gente consegue usar `await`
/// lá na tela que chamou. Ou seja: a tela espera o usuário clicar em "OK" para só depois
/// fazer outra coisa (tipo voltar pro Dashboard). Legal né?
Future<void> showSuccessDialog({
  required BuildContext context, // O passaporte para navegação do Flutter.
  required String title, // Aquela frase de impacto (ex: "Sucesso!").
  required String message, // O texto menor explicando o que rolou.
  required String
  buttonLabel, // O que vai estar escrito no botão ("Bora", "OK", "Voltar").
  required VoidCallback
  onPressed, // A função que vai rodar quando o cara clicar no botão.
}) async {
  // O showDialog é a mágica do Flutter que escurece o fundo e sobe a janelinha.
  await showDialog(
    context: context,

    // Deixamos isso como false. Por quê?
    // Porque se for true, o usuário pode clicar no fundo escuro e o dialog fecha sozinho,
    // quebrando a navegação que você planejou no botão de "OK".
    // Com false, ele é OBRIGADO a ler e clicar no botão.
    barrierDismissible: false,

    builder: (context) => Dialog(
      // Arredondando as pontas pra não ficar aquele quadrado anos 90.
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        // Um padding gordinho (32) deixa o design mais clean e com respiro.
        padding: const EdgeInsets.all(32),
        child: Column(
          // mainAxisSize.min: Fala pra coluna "ocupe só o espaço que seus filhos precisarem",
          // senão o dialog vai esticar lá do teto até o chão da tela.
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- AQUELE ÍCONE GIGANTE E VERDE DE SUCESSO ---
            // Uma bolinha com fundo verde beeeem clarinho e o ícone escuro no meio.
            // Isso dá aquele alívio psicológico no usuário ("Ufa, deu certo!").
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF107649), // Nosso verdão do MesclaInvest.
                size: 64, // Tamanhão exagerado de propósito.
              ),
            ),
            const SizedBox(height: 20),

            // --- TÍTULO ---
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // --- MENSAGEM ---
            // A gente centraliza o texto e deixa ele com uma cor um pouco apagada (white70).
            // Isso cria a "hierarquia visual": os olhos do cara vão pro título primeiro, depois pra cá.
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 24),

            // --- BOTÃO DE CONFIRMAÇÃO ---
            // O SizedBox(width: double.infinity) é um truque clássico:
            // Ele força o botão de dentro a esticar e ocupar toda a largura disponível do dialog.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    onPressed, // Dispara o que você mandou na hora de chamar a função.
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF107649),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
