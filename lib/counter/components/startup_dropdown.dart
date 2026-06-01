// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

import 'package:flutter/material.dart';

/// Um Dropdown (aquela caixa que clica e abre as opções) estilizado pro app.
/// Usamos isso pra pessoa escolher de qual Startup ela quer comprar tokens.
class StartupDropdown extends StatelessWidget {
  /// Lista das startups. Cada map precisa ter 'id' e 'nome'.
  final List<Map<String, String>> startups;
  
  /// O id da startup que está selecionada agora.
  final String? selectedId;
  
  /// O que fazer quando o usuário escolher uma nova startup na lista.
  final void Function(String id, String nome) onSelected;
  
  /// Texto de dica (placeholder) quando não tem nada selecionado.
  final String hint;

  const StartupDropdown({
    super.key,
    required this.startups,
    required this.selectedId,
    required this.onSelected,
    this.hint = 'Selecione a startup',
  });

  @override
  Widget build(BuildContext context) {
    // Procura na lista qual é o nome da startup baseando-se no ID atual.
    // Fazemos isso porque o Dropdown precisa mostrar o nome pro usuário.
    final matches = startups.where((s) => s['id'] == selectedId).toList();
    final selectedNome = matches.isEmpty ? null : matches.first['nome'];

    return Container(
      // Esse container é quem desenha a caixinha bonitinha por volta do dropdown
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF262629), // Cinza escuro
        borderRadius: BorderRadius.circular(12),
        // Bordazinha branca quase transparente pra dar volume
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)), 
      ),
      // DropdownButtonHideUnderline tira aquela linha feia padrão do Material Design
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedNome,
          // Placeholder
          hint: Text(
            hint,
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
          // isExpanded: true faz o dropdown usar toda a largura disponível
          isExpanded: true,
          // A cor de fundo da lista quando ela abre
          dropdownColor: const Color(0xFF262629),
          // A setinha pra baixo do lado direito
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          // Transforma nossa listinha de Maps em DropdownMenuItem de verdade pro Flutter ler
          items: startups
              .map(
                (s) =>
                    DropdownMenuItem(value: s['nome'], child: Text(s['nome']!)),
              )
              .toList(),
          // O que acontece quando ele clica numa opção:
          onChanged: startups.isEmpty
              ? null // Se a lista estiver vazia, ele nem clica.
              : (val) {
                  if (val == null) return;
                  // Busca de volta o ID baseado no nome que ele clicou
                  final match = startups.firstWhere((s) => s['nome'] == val);
                  // Dispara pro pai avisando "Opa, ele escolheu essa!"
                  onSelected(match['id']!, match['nome']!);
                },
        ),
      ),
    );
  }
}
