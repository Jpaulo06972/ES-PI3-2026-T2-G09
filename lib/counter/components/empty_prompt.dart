// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

// Componente de estado vazio reutilizável.
// Exibido quando uma lista ou área de conteúdo não tem itens para mostrar,
// orientando o usuário sobre o próximo passo (ex.: selecionar uma startup).
// Centralizado na tela para não parecer um erro — é um estado válido.

import 'package:flutter/material.dart';

/// Um widget bem simples usado para preencher aquele espaço
/// em branco quando não há nada na tela. 
/// Muito útil para evitar que o usuário pense que o app travou.
class EmptyPrompt extends StatelessWidget {
  /// Mensagem explicativa para o usuário 
  /// (ex.: 'Nenhuma ordem encontrada. Seja o primeiro!').
  final String message;

  const EmptyPrompt({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    // Usamos um Center porque esse aviso normalmente ocupa áreas vazias
    // e queremos o texto sempre bonitinho no meio.
    return Center(
      child: Padding(
        // Adicionamos um espaçamento vertical para o texto não ficar 
        // muito colado com os elementos acima ou abaixo dele.
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          message,
          // Se o texto for longo e quebrar linha, garantimos que fica centralizado.
          textAlign: TextAlign.center,
          style: const TextStyle(
            // Cor branca com 38% de opacidade (Colors.white38).
            // A ideia é ser uma cor super fraca mesmo, para não competir 
            // com a atenção do usuário no resto da interface.
            color: Colors.white38, 
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
