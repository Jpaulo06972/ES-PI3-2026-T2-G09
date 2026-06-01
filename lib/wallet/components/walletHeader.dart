// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

// Importa o pacote material, que fornece as peças de Lego do Flutter (Widgets, Cores, etc.)
import 'package:flutter/material.dart';

/// Componente de cabeçalho da página de carteira, com título e descrição.
/// É um StatelessWidget porque é puramente visual e não muda de estado (não tem dados dinâmicos aqui).
class WalletHeader extends StatelessWidget {
  // Construtor padrão. O super.key ajuda o Flutter a identificar este widget na árvore.
  const WalletHeader({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos um Column para colocar os textos um embaixo do outro
    return const Column(
      // Alinha tudo à esquerda (Start)
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título principal chamativo
        Text(
          'Minha Carteira',
          style: TextStyle(
            color: Colors.white, // Branco para contrastar com fundos escuros
            fontSize: 32, // Tamanho grande, destacando a seção
            fontWeight: FontWeight.w800, // Fonte bem grossa (ExtraBold)
            height: 1.1, // Altura da linha um pouco mais justa
          ),
        ),
        // Espacinho entre o título e a descrição
        SizedBox(height: 12),
        // Descrição secundária explicando o que o usuário pode fazer nesta tela
        Text(
          'Gerencie seu saldo, recarregue e acompanhe seu extrato.',
          style: TextStyle(
            color: Colors
                .white60, // Branco com 60% de opacidade (um pouco "apagado") para não roubar a cena do título
            fontSize: 15,
            height:
                1.4, // Altura da linha maior para melhorar a leitura (respiro)
          ),
        ),
      ],
    );
  }
}
