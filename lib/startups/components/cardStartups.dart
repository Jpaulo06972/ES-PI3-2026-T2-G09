// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684
// Revisado e comentado por: Antigravity AI

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Widget de estado vazio para futuras implementações ou placeholders.
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

/// Widget que representa o card visual de uma startup na lista.
/// Exibe informações como nome, descrição, progresso de captação e status.
class startupCard extends StatelessWidget {
  // Nome da startup exibido em destaque
  final String nome;
  // Breve resumo do que a startup faz
  final String descricao;
  // Estágio atual do negócio para definir a cor e o rótulo do badge
  final String status;
  // Quantidade total de tokens disponíveis para investimento
  final String tokens;
  // Valor monetário já captado ou meta de investimento
  final String valor;
  // Fator decimal (0.0 a 1.0) para preenchimento da barra de progresso
  final double progress;
  // Ícone decorativo que representa a categoria da startup
  final IconData icon;
  // Link direto para uma imagem hospedada na web
  final String? imageUrl;
  // Caminho lógico dentro do bucket do Firebase Storage
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
    // Lógica para definir a cor de identidade do card baseada no status da startup
    final String statusLower = status.toLowerCase();
    Color statusColor = const Color(0xFF4A90E2); // Azul padrão para outros estados

    if (statusLower.contains('nova')) {
      statusColor = const Color(0xFF1A9B5F); // Verde vibrante para novos negócios
    } else if (statusLower.contains('expansao') || statusLower.contains('expansão')) {
      statusColor = const Color(0xFFF5A623); // Laranja para fase de crescimento
    } else if (statusLower.contains('operacao') || statusLower.contains('operação')) {
      statusColor = const Color(0xFF4A90E2); // Azul corporativo para maturidade
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // Gradiente suave para dar profundidade e um aspecto premium ao card
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C2C30), Color(0xFF222225)],
        ),
        borderRadius: BorderRadius.circular(24),
        // Borda fina quase transparente para definição de contorno no dark mode
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
          // Linha Superior: Contém o ícone da categoria e o badge de status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipiente do ícone com gradiente baseado na cor do status
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
              // Badge de status com fundo semi-transparente e borda colorida
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
                    // Pequeno ponto luminoso indicador
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

          // Seção de Imagem: Carrega do Storage se houver um caminho definido, senão tenta URL direta
          if ((imageUrl != null && imageUrl!.isNotEmpty) ||
              (storagePath != null && storagePath!.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: storagePath != null && storagePath!.isNotEmpty
                    // Usa FutureBuilder para resolver a URL temporária do Firebase Storage
                    ? FutureBuilder<String>(
                        future: FirebaseStorage.instance
                            .ref(storagePath)
                            .getDownloadURL(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            // Shimmer/Loading state enquanto a imagem é buscada
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
                          // Trata falhas na busca do arquivo no bucket
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
                          // Renderiza a imagem final após sucesso
                          return Image.network(
                            snapshot.data!,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
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
                          );
                        },
                      )
                    // Fallback para URL estática convencional
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

          // Título e Descrição: Informações principais de identificação
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

          // Barra de Progresso: Representação visual do quão perto a meta de investimento está
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
              // Trilho da barra de progresso
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

          // Rodapé do Card: Estatísticas resumidas de tokens e valor total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Coluna esquerda: Tokens disponíveis
              _buildStatColumn('Tokens', tokens, Icons.token_outlined),
              // Coluna direita: Valor captado (alinhado à direita)
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

  // Método auxiliar para construir as colunas de estatísticas com ícone e rótulo
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
            // Posiciona o ícone antes do texto se estiver alinhado à esquerda
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
            // Posiciona o ícone depois do texto se estiver alinhado à direita
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
