// Feito por: Tomás Toniato RA: 25004211

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/startups/services/getStartup.dart';
import 'startup_colors.dart';

class QATab extends StatefulWidget {
  final String startupId;
  final StartupService service;

  const QATab({super.key, required this.startupId, required this.service});

  @override
  State<QATab> createState() => _QATabState();
}

class _QATabState extends State<QATab> {
  late Future<List<Map<String, dynamic>>> _commentsFuture;
  final TextEditingController _controller = TextEditingController();
  bool _isPrivate = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _commentsFuture = widget.service.listComments(widget.startupId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _commentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: StartupColors.green));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Erro ao carregar:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
            ),
          );
        }

        final comments = snapshot.data ?? [];

        return Column(
          children: [
            Expanded(
              child: comments.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, color: Colors.white12, size: 48),
                          SizedBox(height: 12),
                          Text(
                            'Nenhuma pergunta ainda.\nSeja o primeiro a perguntar!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white38, fontSize: 14, height: 1.5),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      itemCount: comments.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _QuestionCard(comment: comments[i]),
                      ),
                    ),
            ),
            _QuestionInput(
              controller: _controller,
              isPrivate: _isPrivate,
              isSending: _isSending,
              onTogglePrivate: () => setState(() => _isPrivate = !_isPrivate),
              onSend: _handleSend,
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      await widget.service.createComment(
        widget.startupId,
        text,
        _isPrivate ? 'privada' : 'publica',
      );
      _controller.clear();
      setState(() {
        _commentsFuture = widget.service.listComments(widget.startupId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}

class _QuestionCard extends StatelessWidget {
  final Map<String, dynamic> comment;

  const _QuestionCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    final text = (comment['text'] as String?) ?? '';
    final isPrivate = (comment['visibility'] as String?) == 'privada';
    final authorEmail = (comment['authorEmail'] as String?) ?? '';

    String maskedEmail = 'Usuário';
    if (authorEmail.contains('@')) {
      final parts = authorEmail.split('@');
      maskedEmail = '${parts[0][0]}***@${parts[1]}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StartupColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrivate
              ? StartupColors.green.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                maskedEmail,
                style: const TextStyle(color: StartupColors.green, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              if (isPrivate)
                const Text('PRIVADA', style: TextStyle(color: Colors.white30, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}

class _QuestionInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isPrivate;
  final bool isSending;
  final VoidCallback onTogglePrivate;
  final VoidCallback onSend;

  const _QuestionInput({
    required this.controller,
    required this.isPrivate,
    required this.isSending,
    required this.onTogglePrivate,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StartupColors.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onTogglePrivate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPrivate ? StartupColors.green.withValues(alpha: 0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isPrivate ? StartupColors.green : Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPrivate ? Icons.lock_rounded : Icons.public_rounded,
                        size: 14,
                        color: isPrivate ? StartupColors.green : Colors.white30,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPrivate ? 'Privada' : 'Pública',
                        style: TextStyle(
                          color: isPrivate ? StartupColors.green : Colors.white30,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: isPrivate
                        ? 'Envie uma pergunta privada para a startup...'
                        : 'Faça uma pergunta pública...',
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                    filled: true,
                    fillColor: StartupColors.pageBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: isSending ? null : onSend,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isSending
                        ? StartupColors.green.withValues(alpha: 0.5)
                        : StartupColors.green,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: StartupColors.green.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: isSending
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
