// Feito por: Tomás Toniato RA: 25004211

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/enum/userRole.dart';
import 'startup_colors.dart';

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
      height: 200,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (coverImageUrl != null)
            Image.network(
              coverImageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _gradientFallback(),
            )
          else
            _gradientFallback(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.5, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: StartupColors.cardBg.withValues(alpha: 0.65),
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
                        shadows: [
                          Shadow(color: Colors.black87, blurRadius: 12),
                          Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
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

  Widget _gradientFallback() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D5C38), Color(0xFF1A1A1E)],
          ),
        ),
      );

  String _stageLabel() {
    switch (startupStage.toLowerCase()) {
      case 'em_operacao':
        return 'Em operação';
      case 'em_expansao':
        return 'Em expansão';
      case 'nova':
        return 'Nova';
      default:
        return startupStage.replaceAll('_', ' ');
    }
  }

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
