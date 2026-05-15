// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote básico de UI do Flutter
import 'package:flutter/material.dart';

// Importa a paleta de cores oficial do módulo de startups para manter consistência visual
import 'package:mesclainvest_f/startups/components/startup_colors.dart';

/// Seção de recarga rápida no estilo visual das telas de startups.
/// Chips de valores, campo personalizado e botão no padrão de cores da aplicação.
class QuickRecharge extends StatelessWidget {
  // Valor atualmente selecionado nos chips (null = nenhum selecionado)
  final double? selectedValue;

  // Controller do campo de texto para valor personalizado
  final TextEditingController customValueController;

  // Callback quando o usuário toca em um chip de valor rápido
  final ValueChanged<double?> onValueSelected;

  // Callback quando o campo de texto personalizado é alterado
  final ValueChanged<String> onCustomValueChanged;

  // Callback quando o botão "Depositar" é pressionado
  final VoidCallback onConfirm;

  // Valores disponíveis para recarga rápida
  static const List<double> _quickValues = [50, 100, 200, 500, 1000];

  const QuickRecharge({
    super.key,
    required this.selectedValue,
    required this.customValueController,
    required this.onValueSelected,
    required this.onCustomValueChanged,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de seção no padrão _SectionTitle das telas de startups
        // (verde, maiúsculas, letterSpacing)
        const Text(
          "RECARGA RÁPIDA",
          style: TextStyle(
            color: Color(0xFF107649),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Selecione um valor ou insira manualmente",
          style: TextStyle(fontSize: 13, color: Colors.white38),
        ),
        const SizedBox(height: 16),

        // Chips de valores pré-definidos dispostos horizontalmente com scroll
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _quickValues.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final value = _quickValues[index];
              final isSelected = selectedValue == value;

              return GestureDetector(
                onTap: () {
                  // Toggle: se já está selecionado, desmarca; senão, seleciona
                  onValueSelected(isSelected ? null : value);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    // Quando selecionado, usa o fundo verde translúcido igual aos chips de filtro das startups
                    color: isSelected
                        ? const Color(0xFF107649).withOpacity(0.2)
                        : StartupColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF107649)
                          : Colors.white.withValues(alpha: 0.08),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pequeno ponto verde quando selecionado — igual ao chip de filtro das startups
                      if (isSelected) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF107649),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        "R\$ ${value.toInt()}",
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF107649)
                              : Colors.white60,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Campo de valor personalizado — mesmo estilo dos containers da tela de detalhes
        Container(
          decoration: BoxDecoration(
            color: StartupColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: TextField(
            controller: customValueController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            onChanged: onCustomValueChanged,
            decoration: const InputDecoration(
              hintText: "Outro valor (R\$)",
              hintStyle: TextStyle(color: Colors.white30),
              prefixIcon: Icon(
                Icons.attach_money_rounded,
                color: Colors.white30,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Botão de confirmar — sólido verde, sem elevation, mesmo padrão dos botões de ação das startups
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: onConfirm,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
            label: const Text(
              "Confirmar Depósito",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF107649),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}
