// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Um widget em branco. Talvez tenha sido o esqueleto inicial ou deixado 
/// aqui para alguma tela vazia do app. A gente podia deletar, mas vamos deixar quietinho!
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

/// O nosso "Card" da vitrine de Startups! 
/// É a cara do projeto. Ele que aparece na listagem do feed com as cores e fotos.
class startupCard extends StatelessWidget {
  // O nome do negócio. Tem que ter destaque!
  final String nome;
  
  // Aquele pitch de 1 linha. O "O que fazemos".
  final String descricao;
  
  // Esse status muda a cor do card (Nova = Verde, Expansão = Laranja, Operação = Azul)
  final String status;
  
  // A oferta atual.
  final String tokens;
  
  // Valor que os caras já conseguiram de grana!
  final String valor;
  
  // Um doublezinho de 0.0 a 1.0 que o Front usa pra pintar a barrinha de progresso.
  final double progress;
  
  // O íconezinho do ramo de atuação (ex: um foguete, um carrinho).
  final IconData icon;
  
  // Url caso a imagem venha de fora.
  final String? imageUrl;
  
  // Onde a gente guardou a foto lá no baldinho (bucket) do Firebase Storage.
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
    // A inteligência visual: a gente lê a string do status e pinta a identidade do card.
    final String statusLower = status.toLowerCase();
    Color statusColor = const Color(0xFF4A90E2); // Começa com Azul de base

    if (statusLower.contains('nova')) {
      statusColor = const Color(0xFF1A9B5F); // Verde é sinal de coisa fresquinha
    } else if (statusLower.contains('expansao') || statusLower.contains('expansão')) {
      statusColor = const Color(0xFFF5A623); // Laranja de energia crescendo
    } else if (statusLower.contains('operacao') || statusLower.contains('operação')) {
      statusColor = const Color(0xFF4A90E2); // Azul sério de quem já fatura pesado
    }

    // Container que engloba tudo, como se fosse um papel em cima da mesa.
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // LinearGradient é o truque para não ser só uma cor chapada e dar uma textura rica.
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C2C30), Color(0xFF222225)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.5),
        boxShadow: [
          // Sombra para o card não ficar grudado no fundo. Sensação 3D é tudo de bom!
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
          // Linha de cima: Ícone na esquerda, Status na direita.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Esse quadradinho abriga o ícone e leva a mesma cor do status.
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
                    BoxShadow(color: statusColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              
              // O badge arredondado. A clássica "pílula" de status.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Um círculo minúsculo, que pisca na nossa mente como um "led" aceso.
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
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

          // Renderização avançada de imagens.
          // Só tenta renderizar se existir um caminho ou URL.
          if ((imageUrl != null && imageUrl!.isNotEmpty) || (storagePath != null && storagePath!.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              // ClipRRect impede que a imagem quebre o arredondamento (borda redonda).
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: storagePath != null && storagePath!.isNotEmpty
                    // Aqui a mágica do FutureBuilder! Como a foto tá no Firebase Storage, a gente não tem a URL pública.
                    // O app pede pro Storage "me dá a URL temporária desse path" e renderiza só quando tiver sucesso.
                    ? FutureBuilder<String>(
                        future: FirebaseStorage.instance.ref(storagePath).getDownloadURL(),
                        builder: (context, snapshot) {
                          // Se estiver pensando, mostra um loader elegante.
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                              height: 140,
                              width: double.infinity,
                              color: Colors.white.withOpacity(0.05),
                              child: const Center(
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A9B5F)),
                                ),
                              ),
                            );
                          }
                          // Deu pau ou não tem dado? Ícone quebrado na cara!
                          if (snapshot.hasError || !snapshot.hasData) {
                            return Container(
                              height: 140,
                              width: double.infinity,
                              color: Colors.white.withOpacity(0.05),
                              child: const Center(
                                child: Icon(Icons.image_not_supported_rounded, color: Colors.white24, size: 40),
                              ),
                            );
                          }
                          // Tudo certinho. Pinta a imagem!
                          return Image.network(
                            snapshot.data!,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover, // Faz a imagem caber cortando o que não precisa, sem distorcer.
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 140,
                              width: double.infinity,
                              color: Colors.white.withOpacity(0.05),
                              child: const Center(
                                child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 40),
                              ),
                            ),
                          );
                        },
                      )
                    // Plano B: Se só veio o link direto.
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
                            child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 40),
                          ),
                        ),
                      ),
              ),
            ),

          // Título forte chamando a atenção
          Text(
            nome,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          
          // E um textinho descritivo macio pro usuário ler.
          Text(
            descricao,
            style: const TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
          ),

          const SizedBox(height: 24),

          // A barra que indica o quão perto eles tão de fechar a rodada.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progresso da Captação',
                    style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  // Pega nosso float de 0.8 e vira "80%"
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // O Container de fundo cinza, que é a pista.
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(3)),
                
                // FractionallySizedBox é um atalho matador pra barras de progresso!
                // O widthFactor é exatamente nosso número (ex: 0.5 pinta metade).
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(color: statusColor.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 0)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          // Linha divisória debaixo da capa
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 20),

          // Por fim, as duas estatísticas chaves pra balançar o coração do investidor.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatColumn('Tokens', tokens, Icons.token_outlined),
              _buildStatColumn('Captado', valor, Icons.payments_outlined, crossAxisAlignment: CrossAxisAlignment.end),
            ],
          ),
        ],
      ),
    );
  }

  // Ajuda muito a não repetir o código da "coluninha" de ícone + valor. DRY sempre!
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
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500)),
            if (crossAxisAlignment == CrossAxisAlignment.end) ...[
              const SizedBox(width: 4),
              Icon(iconData, color: Colors.white38, size: 14),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
