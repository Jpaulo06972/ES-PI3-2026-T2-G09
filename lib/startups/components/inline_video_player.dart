// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'startup_colors.dart';

// ### Importação Condicional (Conditional Imports em Dart)
// Isso aqui é um truque de mestre no Dart. Como o 'youtube_player_flutter'
// usa uma WebView nativa por baixo dos panos (que não existe na Web e quebra a compilação),
// a gente usa uma importação baseada na plataforma.
// É como dizer: "Se tiver 'dart.library.html' (ou seja, está no navegador), importe o arquivo web.
// Caso contrário (está rodando no celular), importe o stub (um arquivo falso só para não quebrar)."
import 'inline_video_stub.dart' if (dart.library.html) 'inline_video_web.dart';

/// [InlineVideoPlayer] é o nosso tocador de vídeos integrado.
/// Por que isso importa? Porque a cada clique a mais que o usuário dá para sair do app
/// e abrir o YouTube, a gente perde retenção e conversão de investimento. Manter o cara
/// dentro do nosso app assistindo ao pitch é crucial.
class InlineVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const InlineVideoPlayer({super.key, required this.videoUrl});

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  // Esse é o controle remoto da TV. Usado apenas no mobile nativo.
  YoutubePlayerController? _controller;
  
  // Flag defensiva. Nunca confie cegamente nos dados da API, eles podem vir corrompidos.
  bool _isValidUrl = false;
  
  // O ID do YouTube extraído (aqueles 11 caracteres esquisitos da URL)
  String? _videoId;

  @override
  void initState() {
    super.initState();
    
    // Tenta arrancar o ID único da URL, suportando tanto formato longo quanto encurtado.
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    
    // Fallback: Se não achar nada ou a URL estiver zoada, para por aqui e não tenta renderizar lixo.
    if (videoId == null || videoId.isEmpty) return;
    
    _isValidUrl = true;
    _videoId = videoId;

    // Atenção redobrada aqui: o `youtube_player_flutter` explode no Flutter Web
    // porque ele tenta chamar código nativo (Java/Swift) que não existe no Chrome.
    // Então, a gente checa se NÃO é web antes de ligar o controle.
    if (!kIsWeb) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,      // Ninguém gosta que vídeos comecem a berrar ao abrir a tela
          mute: false,          // Quando o cara der play, ele quer ouvir
          loop: false,          // Terminou o pitch? Acabou, não precisa repetir
          forceHD: false,       // Deixa a qualidade adaptativa para não torrar o 4G da pessoa
          enableCaption: true,  // Acessibilidade é inegociável
        ),
      );
    }
  }

  // O `dispose` é o momento da faxina. O usuário fechou a tela, não precisamos mais do player.
  // Se não fizermos isso, o vídeo pode ficar tocando no fundo como fantasma, consumindo RAM (memory leak).
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Se a URL era inválida logo de cara, devolvemos um quadrado amigável avisando o erro,
    // em vez de dar uma tela vermelha na cara do usuário.
    if (!_isValidUrl) {
      return _buildPlaceholder(
        icon: Icons.error_outline_rounded,
        label: 'URL de vídeo inválida',
      );
    }

    // Se estivermos rodando no Web, a gente usa nossa função mágica
    // do import condicional ali em cima para criar um iframe HTML.
    if (kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: double.infinity,
          height: 210,
          child: buildWebVideoPlayer(_videoId!),
        ),
      );
    }

    // Se passou de tudo, é mobile nativo.
    // ClipRRect aqui é para cortar as pontas do vídeo e deixar redondinho,
    // mantendo a consistência visual com os outros cards.
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: StartupColors.green, // Cores da nossa marca
        progressColors: const ProgressBarColors(
          playedColor: StartupColors.green,
          handleColor: Colors.white,
        ),
      ),
    );
  }

  /// Construtor de card vazio (placeholder).
  /// Útil tanto para quando o vídeo não carrega, quanto para exibir feedback amigável
  /// sem estragar o layout da tela que já esperava um bloco retangular ali.
  Widget _buildPlaceholder({required IconData icon, required String label}) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: StartupColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        // Uma bordinha super sutil (alpha 0.05) só para destacar o fundo
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Ocupa só o espaço necessário dentro da coluna
          children: [
            Icon(icon, color: Colors.white24, size: 36),
            const SizedBox(height: 8), // Respiro visual
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
