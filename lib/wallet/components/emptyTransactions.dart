// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:flutter/material.dart';

/// Widget de "Empty State" (estado vazio) exibido quando a lista de transações está vazia.
///
/// O "estado vazio" é uma parte crucial da experiência do usuário (UX).
/// Se você não mostrar nada quando uma lista estiver vazia, o usuário pode achar que
/// o aplicativo travou, está carregando para sempre ou deu algum erro de conexão.
/// Esse componente fornece uma indicação clara e visual de que a busca simplesmente não
/// retornou nada.
class EmptyTransactions extends StatelessWidget {
  // Construtor com chave super.key para melhorar a performance de renderização do Flutter.
  const EmptyTransactions({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos um Padding para desgrudar o conteúdo das bordas e permitir
    // que fique bem centralizado e com um "respiro".
    return const Padding(
      padding: EdgeInsets.all(32), // Uma margem generosa em todas as direções
      // Center vai garantir que o ícone e o texto fiquem perfeitamente alinhados no meio
      // do espaço disponível.
      child: Center(
        // Usamos uma Column para empilhar o ícone em cima do texto explicativo.
        child: Column(
          // centraliza verticalmente dentro do espaço da coluna
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone de "recibo" ou "papel", que remete a transações.
            Icon(
              Icons.receipt_long_rounded,
              // Uma cor muito suave (white24) para o ícone. O objetivo do empty state
              // não é gritar na tela, mas sim dar uma resposta sutil.
              color: Colors.white24,
              size: 48, // Tamanho grandinho para ficar claro
            ),
            SizedBox(height: 16), // Aquele espaço clássico entre ícone e texto
            // Texto direto ao ponto. Sem rodeios.
            Text(
              'Nenhuma transação encontrada.',
              textAlign: TextAlign
                  .center, // Garante que o texto fique bem centralizado se quebrar linha
              style: TextStyle(
                // Branco com 54% de opacidade é um padrão muito comum em Dark Mode
                // para textos secundários ou menos importantes.
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
