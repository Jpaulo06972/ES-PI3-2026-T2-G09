// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class cardStartup extends StatefulWidget {
  const cardStartup({super.key});

  @override
  State<cardStartup> createState() => _cardStartupState();
}

class _cardStartupState extends State<cardStartup> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class startupCard extends StatelessWidget {
  final String nome;
  final String descricao;
  final String status;
  final String tokens;
  final String valor;
  final double progress;
  final IconData icon;
  final String? imageUrl;
  final String? storagePath;

  const startupCard({
    required this.nome,
    required this.descricao,
    required this.status,
    required this.tokens,
    required this.valor,
    required this.progress,
    required this.icon,
    this.imageUrl,
    this.storagePath,
  });

  @override
  Widget build(BuildContext context) {
    // Determine status color based on text
    final bool isOpen = status.toLowerCase().contains('aberta');
    final Color statusColor = isOpen
        ? const Color(0xFF1A9B5F)
        : const Color(0xFF4A90E2);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C2C30), Color(0xFF222225)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon and Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor, statusColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Cover Image (Se houver imageUrl HTTP direto ou storagePath)
          if ((imageUrl != null && imageUrl!.isNotEmpty) ||
              (storagePath != null && storagePath!.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: storagePath != null && storagePath!.isNotEmpty
                    // Busca dinamicamente do Firebase Storage
                    ? FutureBuilder<String>(
                        future: FirebaseStorage.instance
                            .ref(storagePath)
                            .getDownloadURL(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Container(
                              height: 140,
                              width: double.infinity,
                              color: Colors.white.withOpacity(0.05),
                              child: const Center(
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF1A9B5F),
                                  ),
                                ),
                              ),
                            );
                          }
                          if (snapshot.hasError || !snapshot.hasData) {
                            if (snapshot.hasError) {
                              debugPrint('Erro ao buscar imagem ($storagePath): ${snapshot.error}');
                            }
                            return Container(
                              height: 140,
                              width: double.infinity,
                              color: Colors.white.withOpacity(0.05),
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported_rounded,
                                  color: Colors.white24,
                                  size: 40,
                                ),
                              ),
                            );
                          }
                          return Image.network(
                            snapshot.data!,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    // Se não tem storagePath, usa a imageUrl (link estático)
                    : Image.network(
                        imageUrl!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 140,
                          width: double.infinity,
                          color: Colors.white.withOpacity(0.05),
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              color: Colors.white24,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
              ),
            ),

          // Middle Row: Title & Description
          Text(
            nome,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            descricao,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Progress Bar (Mockup)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progresso da Captação',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 20),

          // Bottom Row: Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatColumn('Tokens', tokens, Icons.token_outlined),
              _buildStatColumn(
                'Captado',
                valor,
                Icons.payments_outlined,
                crossAxisAlignment: CrossAxisAlignment.end,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    String label,
    String value,
    IconData iconData, {
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (crossAxisAlignment == CrossAxisAlignment.start) ...[
              Icon(iconData, color: Colors.white38, size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (crossAxisAlignment == CrossAxisAlignment.end) ...[
              const SizedBox(width: 4),
              Icon(iconData, color: Colors.white38, size: 14),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
