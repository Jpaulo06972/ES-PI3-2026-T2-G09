// Importa o pacote básico de UI do Flutter
import 'package:flutter/material.dart';

// Tela de notificações — por enquanto está em construção
// Mostra uma mensagem avisando que a funcionalidade será implementada em breve
class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior com título "Notificações"
      appBar: AppBar(
        // Título centralizado na barra
        title: const Text('Notificações'),
        // Cor de fundo verde escuro institucional
        backgroundColor: const Color(0xFF0C5837),
        // Cor dos textos e ícones da barra (branco)
        foregroundColor: Colors.white,
        // Centraliza o título no meio da barra
        centerTitle: true,
      ),

      // Corpo da tela — centralizado na tela toda
      body: Center(
        child: Padding(
          // Espaçamento de 32px em todos os lados para o conteúdo não colar nas bordas
          padding: const EdgeInsets.all(32.0),
          child: Column(
            // Centraliza tudo verticalmente na tela
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone grande de construção (indica que está sendo desenvolvido)
              Icon(
                Icons.construction,
                size: 100,
                color: Colors.grey.shade500,
              ),

              // Espaçamento entre o ícone e o título
              const SizedBox(height: 24),

              // Texto principal: "Em Desenvolvimento"
              const Text(
                'Em Desenvolvimento',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              // Espaçamento entre o título e a descrição
              const SizedBox(height: 16),

              // Texto explicativo dizendo que a tela será implementada em breve
              Text(
                'A tela de notificações está sendo construída e estará disponível nas próximas atualizações!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade400,
                ),
                textAlign: TextAlign.center,
              ),

              // Espaçamento antes do botão
              const SizedBox(height: 40),

              // Botão "Voltar" — retorna à tela anterior
              ElevatedButton.icon(
                // Ao pressionar, desempilha esta tela e volta pra anterior
                onPressed: () {
                  Navigator.pop(context);
                },
                // Ícone de seta para a esquerda
                icon: const Icon(Icons.arrow_back),
                // Texto do botão
                label: const Text('Voltar'),
                // Estilo visual do botão
                style: ElevatedButton.styleFrom(
                  // Fundo verde escuro institucional
                  backgroundColor: const Color(0xFF0C5837),
                  // Texto e ícone em branco
                  foregroundColor: Colors.white,
                  // Espaçamento interno do botão
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  // Cantos arredondados
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
