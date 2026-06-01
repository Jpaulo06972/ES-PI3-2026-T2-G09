// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

// Rótulo de campo de formulário padronizado.
// Usado acima de inputs (TextFields, dropdowns, steppers) para identificá-los.
// Ter um widget dedicado garante que todos os rótulos do Balcão usem
// exatamente o mesmo estilo tipográfico sem duplicar código.

import 'package:flutter/material.dart';

/// Widget de texto simples para padronizar rótulos (labels) de campos.
/// Garante que "Quantidade", "Preço" e outros títulos fiquem visualmente idênticos.
class FieldLabel extends StatelessWidget {
  /// O texto que será exibido (ex.: 'Quantidade de tokens', 'Preço por token (R$)').
  final String text;

  const FieldLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        // Colors.white70 dá um contraste bom, mas sem roubar a cena do input em si.
        // É levemente mais claro que white54 — legível mas sutil.
        color: Colors.white70,
        fontSize: 13,
        // FontWeight.w500 é o "Medium" da fonte, um meio-termo entre 
        // o normal (w400) e o negrito (w700). Dá uma presença bacana.
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
