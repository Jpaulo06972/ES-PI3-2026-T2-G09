// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// O básico do Flutter: pacotes de interface e o nosso modelo de usuário.
import 'package:flutter/material.dart';
import 'package:mesclainvest_f/model/userModel.dart';

/// Nosso cabeçalho customizado (CustomHeader).
/// A gente usa `implements PreferredSizeWidget` para o Flutter entender
/// que esse widget pode ser usado no `appBar:` de um Scaffold.
/// Sem isso, o Scaffold não saberia qual tamanho reservar pra ele.
class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  // Os dados do usuário logado (pra pegar o nome e a inicial pro avatar).
  final UserModel userModel;

  // Variável que diz se o usuário deixou o saldo à mostra (true) ou escondeu (false).
  final bool isVisible;

  // Função disparada quando o cara clica no ícone do olhinho.
  // Deixamos como opcional (VoidCallback?) porque nem toda tela precisa do olhinho.
  final VoidCallback? onToggleVisibility;

  const CustomHeader({
    super.key,
    required this.userModel,
    this.isVisible = true,
    this.onToggleVisibility,
  });

  /// Pega a primeira letra do nome pra colocar dentro da bolinha (avatar).
  /// Se por algum milagre o nome vier vazio, a gente coloca um 'U' de 'Usuário'
  /// pra não dar erro nem ficar vazio.
  String _getInitials() {
    return userModel.firstName.isNotEmpty
        ? userModel.firstName[0].toUpperCase()
        : 'U';
  }

  @override
  Widget build(BuildContext context) {
    // Um Container é ótimo aqui porque permite colocar padding e cor de fundo.
    return Container(
      padding: EdgeInsets.only(
        // Esse MediaQuery.of(context).padding.top é a mágica pra não desenhar
        // em cima da barra de bateria/relógio do celular!
        // A gente soma 20 pra dar um respiro visual bacana.
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 16,
        left: 14,
        right: 16,
      ),
      // Fundo transparente pra pegar a cor gradiente que geralmente vem do Scaffold.
      decoration: const BoxDecoration(color: Colors.transparent),

      // Colocamos os elementos um do lado do outro.
      child: Row(
        // Centraliza tudo na vertical pra ficar alinhadinho.
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- AVATAR DO USUÁRIO ---
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3A), // Um cinza escuro chique.
              borderRadius: BorderRadius.circular(
                20,
              ), // Deixa totalmente redondo.
            ),
            child: Center(
              child: Text(
                _getInitials(), // Coloca a letra no meio do círculo.
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 10,
          ), // Aquele espaço maroto entre avatar e nome.
          // --- NOME DO USUÁRIO ---
          // O Expanded é como se dissesse: "pega todo o espaço que sobrou no meio".
          // Isso empurra o ícone do olhinho lá pra ponta direita.
          Expanded(
            child: Text(
              userModel.firstName.isNotEmpty ? userModel.firstName : 'Usuário',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1, // Impede que nomes gigantes quebrem a linha.
              overflow: TextOverflow
                  .ellipsis, // Bota os '...' se o nome não couber na tela.
            ),
          ),

          const SizedBox(width: 12),

          // --- BOTÃO DO OLHINHO ---
          // Se passamos a função do clique, a gente desenha o botão.
          if (onToggleVisibility != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3A),
                borderRadius: BorderRadius.circular(20),
              ),
              // O Material e o InkWell juntos fazem aquela ondinha bonita (ripple effect)
              // quando o usuário clica no botão. Fica com cara de app nativo.
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip
                    .hardEdge, // Garante que a ondinha não vaze pra fora da bolinha.
                child: InkWell(
                  onTap:
                      onToggleVisibility, // Dispara a função que esconde/mostra saldo.
                  child: Center(
                    child: Icon(
                      // Checa o estado da variável isVisible pra trocar o ícone.
                      isVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }

  // Aqui é onde atendemos o contrato do PreferredSizeWidget.
  // Dizemos pro Flutter: "Garante pra mim pelo menos 100 pixels de altura aqui no topo".
  @override
  Size get preferredSize => const Size.fromHeight(100.0);
}
