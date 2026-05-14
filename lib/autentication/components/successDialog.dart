import 'package:flutter/material.dart';

/// Exibe um dialog bonito de sucesso com ícone, título, mensagem e botão.
///
/// [context] — contexto da tela atual.
/// [title] — título principal do dialog.
/// [message] — mensagem secundária abaixo do título.
/// [buttonLabel] — texto do botão de ação.
/// [onPressed] — callback quando o botão é pressionado.
Future<void> showSuccessDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String buttonLabel,
  required VoidCallback onPressed,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone de sucesso com fundo verde
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF107649),
                size: 64,
              ),
            ),
            const SizedBox(height: 20),

            // Título
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Mensagem
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 24),

            // Botão de ação
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF107649),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
