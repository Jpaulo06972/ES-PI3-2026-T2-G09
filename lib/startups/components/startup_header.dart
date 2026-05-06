// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684
// Feito originalmente por: Tomás Toniato RA: 25004211

// Importações básicas de UI e do Enum de papéis do usuário
import 'package:flutter/material.dart';
import 'package:mesclainvest_f/enum/userRole.dart';
import 'startup_colors.dart';

/// Cabeçalho expandido da startup que exibe a imagem de capa, nome e badges de status.
class StartupHeader extends StatelessWidget {
  // Nome da startup exibido em tamanho grande
  final String startupName;
  // Estágio atual (nova, em_operacao, em_expansao)
  final String startupStage;
  // Papel do usuário logado (usado para exibir o badge de tipo de conta)
  final UserRole userRole;
  // URL da imagem de capa (carregada via Firebase Storage na página pai)
  final String? coverImageUrl;
  // Função para voltar à tela anterior
  final VoidCallback onBack;

  const StartupHeader({
    super.key,
    required this.startupName,
    required this.startupStage,
    required this.userRole,
    required this.onBack,
    this.coverImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200, // Altura fixa do cabeçalho
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand, // Faz os filhos ocuparem todo o espaço do Stack
        children: [
          // ── Camada 1: Imagem de Capa ──────────────────────────────────────
          if (coverImageUrl != null)
            Image.network(
              coverImageUrl!,
              fit: BoxFit.cover, // Preenche todo o espaço cortando as sobras
              // Se a imagem falhar ao carregar, usa um degradê verde como segurança
              errorBuilder: (_, __, ___) => _gradientFallback(),
            )
          else
            // Se não houver URL, usa o degradê padrão
            _gradientFallback(),

          // ── Camada 2: Overlay Escuro (Degradê) ────────────────────────────
          // Serve para escurecer a imagem e permitir a leitura dos textos brancos por cima
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.5, 1.0], // Onde cada cor do degradê começa/termina
                colors: [
                  Colors.black.withValues(alpha: 0.25), // Leve no topo (para ver o botão de voltar)
                  Colors.black.withValues(alpha: 0.4),  // Médio no meio
                  Colors.black.withValues(alpha: 0.7),  // Forte na base (onde fica o nome)
                ],
              ),
            ),
          ),

          // ── Camada 3: Conteúdo (Botão de Voltar, Nome e Badges) ─────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Empurra os itens para as extremidades
              children: [
                // Botão de Voltar personalizado e flutuante
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: StartupColors.cardBg.withValues(alpha: 0.65), // Fundo semi-transparente
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Catálogo',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                // Rodapé do Header: Nome e Rótulos
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startupName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        // Sombras duplas para garantir leitura sobre qualquer tipo de imagem
                        shadows: [
                          Shadow(color: Colors.black87, blurRadius: 12),
                          Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        // Badge de Estágio (Verde e com brilho)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: StartupColors.green,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: StartupColors.green.withValues(alpha: 0.4), blurRadius: 8),
                            ],
                          ),
                          child: Text(
                            _stageLabel(), // Função que traduz o estágio para texto amigável
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Badge de Perfil do Usuário (Cinza Escuro e Discreto)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: StartupColors.cardBg.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Text(
                            _roleLabel(), // Função que traduz o Enum de Role para texto amigável
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Degradê de fallback caso a imagem falhe ou não exista.
  Widget _gradientFallback() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D5C38), Color(0xFF1A1A1E)],
          ),
        ),
      );

  /// Traduz o termo técnico do estágio para uma linguagem mais humana.
  String _stageLabel() {
    switch (startupStage.toLowerCase()) {
      case 'em_operacao':
        return 'Em operação';
      case 'em_expansao':
        return 'Em expansão';
      case 'nova':
        return 'Nova';
      default:
        return startupStage.replaceAll('_', ' '); // Remove underscores se for outro valor
    }
  }

  /// Traduz o papel do usuário (Enum) para o rótulo exibido no badge.
  String _roleLabel() {
    switch (userRole) {
      case UserRole.investidor:
        return 'Investidor';
      case UserRole.empreendedor:
        return 'Empreendedor';
      case UserRole.admin:
        return 'Admin';
    }
  }
}
