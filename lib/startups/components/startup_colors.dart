// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

import 'package:flutter/material.dart';

/// [StartupColors] é a nossa "paleta de tintas" central do módulo de Startups.
/// Por que criar um arquivo só pra isso? Imagina se o chefe decide que o verde
/// do app vai mudar. Se a gente espalhar "Color(0xFF...)" por 50 arquivos,
/// teríamos que dar Replace em tudo. Centralizando aqui, mudamos uma linha
/// e o app inteiro fica de cara nova.
/// 
/// Arquitetura: Ela é 'abstract' para que nenhum programador júnior consiga
/// dar um "new StartupColors()". Não faz sentido instanciar uma paleta de cores,
/// a gente só quer pegar os valores dela emprestados (métodos estáticos).
abstract class StartupColors {
  
  /// [green] é o nosso verde MesclaInvest.
  /// Passa aquela vibe de "dinheiro", "investimento seguro" e "lucro".
  static const green = Color(0xFF1A9B5F);
  
  /// [cardBg] é o fundo dos nossos bloquinhos (cards).
  /// Por que não usar preto puro (0xFF000000)? Porque preto puro com texto
  /// branco cansa a vista rápido (alto contraste demais). Um cinza chumbo
  /// como esse é muito mais elegante e confortável de ler no escuro.
  static const cardBg = Color(0xFF262629);
  
  /// [pageBg] é a cor da parede lá do fundo.
  /// Note que ela é ligeiramente mais escura que os cards (cardBg).
  /// Isso cria uma "ilusão de ótica" de profundidade, fazendo os cards
  /// parecerem estar flutuando em cima do fundo.
  static const pageBg = Color(0xFF1A1A1E);

  /// [chartColors] é o estojo de lápis de cor para pintar os gráficos (tipo o Cap Table).
  /// 
  /// Regra de ouro da acessibilidade UX: Nunca coloque duas cores parecidas
  /// juntas num gráfico (ex: Verde claro e Verde escuro). Usuários com
  /// daltonismo não vão conseguir diferenciar nada.
  /// A gente pegou cores vibrantes e contrastantes (Verde, Azul, Laranja, etc.)
  /// para que cada sócio tenha uma cor bem distinta no gráfico de pizza/barra.
  static const chartColors = [
    Color(0xFF1A9B5F), // Verde (Main)
    Color(0xFF4A90E2), // Azul
    Color(0xFFF5A623), // Laranja
    Color(0xFFE74C3C), // Vermelho
    Color(0xFF9B59B6), // Roxo
    Color(0xFF1ABC9C), // Ciano
    Color(0xFFE67E22), // Laranja puxado pro Bronze
  ];
}
