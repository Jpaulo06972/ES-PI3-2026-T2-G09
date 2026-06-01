// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

import 'package:flutter/material.dart';

/// Uma label super simples usada como separador de seções.
/// Normalmente usada com letras maíusculas como "MINHAS OFERTAS" ou "LIVRO DE ORDENS".
/// Cria aquela sensação de organização e hierarquia no layout.
class SectionLabel extends StatelessWidget {
  /// O texto que vai dar nome à seção.
  final String text;
  
  const SectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11, // Fonte pequena pra não ser espalhafatoso
        fontWeight: FontWeight.w600, // Pesinho legal (SemiBold)
        // letterSpacing 1.2 é o truque de UI design pra "textos pequenos em MAIÚSCULO".
        // Dá um ar mais sofisticado.
        letterSpacing: 1.2, 
      ),
    );
  }
}
