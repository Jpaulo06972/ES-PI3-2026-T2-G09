// Feito por: Tomás Toniato RA: 25004211

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'startup_colors.dart';

class InlineVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const InlineVideoPlayer({super.key, required this.videoUrl});

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  YoutubePlayerController? _controller;
  bool _isValidUrl = false;
  String? _videoId;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    if (videoId == null || videoId.isEmpty) return;
    _isValidUrl = true;
    _videoId = videoId;

    // youtube_player_flutter usa flutter_inappwebview, que não suporta Flutter Web.
    // No web mostramos um fallback (thumbnail + botão "Assistir no YouTube") para evitar
    // o erro `UnimplementedError: addJavaScriptHandler is not implemented`.
    if (!kIsWeb) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          loop: false,
          forceHD: false,
          enableCaption: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isValidUrl) {
      return _buildPlaceholder(
        icon: Icons.error_outline_rounded,
        label: 'URL de vídeo inválida',
      );
    }

    if (kIsWeb) {
      return _buildWebFallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: StartupColors.green,
        progressColors: const ProgressBarColors(
          playedColor: StartupColors.green,
          handleColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPlaceholder({required IconData icon, required String label}) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: StartupColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white24, size: 36),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildWebFallback() {
    final thumbnailUrl = 'https://img.youtube.com/vi/${_videoId!}/hqdefault.jpg';
    final watchUrl = 'https://www.youtube.com/watch?v=${_videoId!}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Image.network(
            thumbnailUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(
              icon: Icons.image_not_supported_outlined,
              label: 'Thumbnail indisponível',
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
              ),
              child: Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE74C3C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final uri = Uri.parse(watchUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text(
                    'Assistir no YouTube',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
