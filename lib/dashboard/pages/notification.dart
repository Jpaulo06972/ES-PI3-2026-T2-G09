// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote básico de UI do Flutter.
// Pense no material.dart como a nossa caixa de ferramentas: ele traz todos os blocos de montar visuais do Material Design.
import 'package:flutter/material.dart';

/// Nossa tela de notificações.
/// Como a infraestrutura de mensageria (ex: Firebase Cloud Messaging) ainda está no forno,
/// decidimos colocar uma página temporária ("Em Construção").
/// É uma boa prática de UX não deixar o usuário clicar num botão e nada acontecer.
class NotificationPage extends StatelessWidget {
  // O construtor com 'super.key' ajuda o Flutter a identificar este widget na árvore.
  // Como essa tela é estática e não guarda nenhum estado interno, usamos StatelessWidget.
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold é como o "esqueleto" da nossa tela. Ele já traz o layout básico para
    // colocar uma barra superior (AppBar) e o corpo (body).
    return Scaffold(
      // AppBar é a barra de navegação superior.
      appBar: AppBar(
        // Título da página, usando const porque a string nunca vai mudar (otimiza a memória).
        title: const Text('Notificações'),
        // Nossa cor verde institucional. Usar o código Hex com 0xFF na frente é o padrão do Flutter.
        backgroundColor: const Color(0xFF0C5837),
        // foregroundColor pinta todos os textos e ícones da AppBar (como a seta de voltar) de branco.
        foregroundColor: Colors.white,
        // centerTitle: true garante que o título fique centralizado tanto no iOS quanto no Android.
        centerTitle: true,
      ),

      // O corpo da tela. O widget Center garante que tudo o que for colocado aqui
      // fique exatamente no meio da tela.
      body: Center(
        // O Padding dá uma "respirada" nas bordas. Assim, se o texto for grande,
        // ele não vai colar nos cantos do celular.
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          // Usamos uma Column para empilhar nossos widgets verticalmente: Ícone -> Texto -> Botão.
          child: Column(
            // mainAxisAlignment.center empurra os filhos da coluna para o meio do eixo vertical.
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // O ícone de 'construction' é ótimo para passar a ideia de "obra em andamento".
              // Colocamos um tamanho grande e um cinza suave para não agredir os olhos.
              Icon(Icons.construction, size: 100, color: Colors.grey.shade500),

              // O SizedBox vazio é o nosso "espaçador" clássico no Flutter.
              // Como estamos numa Column, definimos a altura (height) para afastar os widgets.
              const SizedBox(height: 24),

              // O título principal da tela.
              const Text(
                'Em Desenvolvimento',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                // textAlign.center garante que o texto fique centralizado se quebrar de linha.
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // O texto explicativo. É legal ser transparente com o usuário sobre o que está rolando!
              Text(
                'A tela de notificações está sendo construída e estará disponível nas próximas atualizações!',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
                textAlign: TextAlign.center,
              ),

              // Espaço um pouquinho maior antes do botão para dar destaque.
              const SizedBox(height: 40),

              // O botão de voltar. Usamos ElevatedButton.icon porque ele já cria um layout
              // certinho com ícone na esquerda e texto na direita, sem a gente precisar de Row.
              ElevatedButton.icon(
                // O onPressed dita o que acontece quando o botão é clicado.
                // Neste caso, ele fecha a tela atual (dá um pop na pilha de navegação)
                // e devolve o usuário para a tela anterior.
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar'),
                style: ElevatedButton.styleFrom(
                  // Usamos a mesma cor verde da AppBar para manter a consistência visual.
                  backgroundColor: const Color(0xFF0C5837),
                  foregroundColor: Colors.white,
                  // Um padding generoso dentro do botão para ele não ficar "espremido".
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  // Arredondamos as pontas para o botão ficar mais moderno.
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
