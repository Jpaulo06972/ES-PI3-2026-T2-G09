// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/enum/userRole.dart';
import 'startup_colors.dart';

/// [StartupHeader] é aquele "outdoor" lindão que fica no topo da tela de detalhes da startup.
/// Ele mostra a imagem de capa, o nome da empresa e os badges de estágio e perfil.
/// 
/// Por que usar Stack?
/// Stack permite colocar widgets "um em cima do outro" (como panquecas). 
/// Precisamos disso porque a imagem de capa fica por baixo, depois vem um filtro escuro (gradiente)
/// para melhorar a leitura, e por cima de tudo vai o texto e o botão de voltar.
class StartupHeader extends StatelessWidget {
  final String startupName;
  final String startupStage;
  final UserRole userRole;
  final String? coverImageUrl;
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
      height: 200, // Altura perfeita: grande o suficiente pra impactar, pequena o suficiente pra não esconder o conteúdo debaixo
      width: double.infinity, // Estica até as bordas do celular
      child: Stack(
        fit: StackFit.expand, // Manda as panquecas da Stack ocuparem todo o tamanho da panela (SizedBox)
        children: [
          
          // Panqueca 1: A Imagem de Fundo (ou um fundo verde se der pau)
          if (coverImageUrl != null)
            Image.network(
              coverImageUrl!,
              fit: BoxFit.cover, // Preenche tudo cortando as bordas se necessário (igual papel de parede do PC)
              
              // Se a internet cair, a URL estiver morta ou o formato for zuado,
              // o errorBuilder entra em ação desenhando um gradiente verdinho pra não 
              // mostrar aquele ícone horrível de "imagem quebrada" do Android.
              errorBuilder: (_, __, ___) => _gradientFallback(),
            )
          else
            _gradientFallback(),
          
          // Panqueca 2: A Película Escura (Scrim)
          // Isso aqui é um truque clássico de UI/UX. Se a imagem da startup for muito clara (ex: um fundo branco),
          // o texto branco não vai dar pra ler. Esse gradiente pinta um preto translúcido que vai 
          // escurecendo mais na base, garantindo que o nome da startup sempre fique 100% legível.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.5, 1.0], // Onde a cor começa e termina
                colors: [
                  Colors.black.withValues(alpha: 0.25), // Escurece um pouco no topo
                  Colors.black.withValues(alpha: 0.4),  // Meio do caminho
                  Colors.black.withValues(alpha: 0.7),  // Fica bem escurinho na base perto do texto
                ],
              ),
            ),
          ),
          
          // Panqueca 3: Textos e Botões (O recheio)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // mainAxisAlignment.spaceBetween empurra o botão de voltar lá pro teto 
              // e os textos pro chão.
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                
                // Botão "Voltar" com efeito de vidro fosco (Glassmorphism)
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: StartupColors.cardBg.withValues(alpha: 0.65), // Fundo translúcido
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)), // Bordinha super fina pra dar brilho
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min, // Só ocupa o espaço das letras + ícone
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
                
                // Textos descritivos (Nome e Tags)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome gigantesco da startup
                    Text(
                      startupName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5, // Deixa as letras mais grudadinhas, dá um ar de "título de jornal"
                        // Sombras duplas: uma desfocada espalhada (glow preto) e uma dura pra baixo (peso visual)
                        shadows: [
                          Shadow(color: Colors.black87, blurRadius: 12),
                          Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14), // Respiro
                    
                    // As plaquinhas/badges (Estágio e Role do usuário)
                    Row(
                      children: [
                        // Plaquinha 1: Estágio da empresa (Verdona, brilhante pra chamar atenção)
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
                            _stageLabel(),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 10),
                        
                        // Plaquinha 2: Role do usuário (Glassmorphism de novo, mais contido pra não roubar a cena do verde)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: StartupColors.cardBg.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Text(
                            _roleLabel(),
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

  /// O salva-vidas. Se a capa quebrar, isso aqui entra em cena: um gradiente de "Verde escuro" pra "Preto quase puro".
  Widget _gradientFallback() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D5C38), Color(0xFF1A1A1E)],
          ),
        ),
      );

  /// Tradutor do backend pra língua do usuário.
  /// O banco salva enum tipo "em_operacao". A gente conserta isso pra exibir bonito na tela.
  String _stageLabel() {
    switch (startupStage.toLowerCase()) {
      case 'em_operacao':
        return 'Em operação';
      case 'em_expansao':
        return 'Em expansão';
      case 'nova':
        return 'Nova';
      default:
        // Curinga: se botarem um novo tipo lá na gringa amanhã, o replace tira o '_' pelo menos.
        return startupStage.replaceAll('_', ' ');
    }
  }

  /// Pega o enum esquisito do Dart e cospe uma string limpa.
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
