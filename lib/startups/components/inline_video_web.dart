// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

// Ignora o aviso chato do linter sobre usar bibliotecas da web no flutter,
// já que a gente fez um import condicional seguro para chegar até aqui.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/widgets.dart';

// Um conjunto (Set) para registrar as views criadas.
// Pense nisso como uma lista de chamada de alunos que já chegaram. 
// Isso evita tentarmos registrar a mesma view (iframe) duas vezes e causar um erro no Flutter Web.
final Set<String> _registeredTypes = {};

/// Função mágica que cria o player do YouTube quando estamos no navegador (Web).
Widget buildWebVideoPlayer(String videoId) {
  // Cria um nome de view único para cada vídeo, tipo um RG.
  final viewType = 'yt-embed-$videoId';
  
  // Se ainda não registramos esse vídeo no Flutter...
  if (!_registeredTypes.contains(viewType)) {
    // Marcamos como registrado para não dar erro na próxima vez.
    _registeredTypes.add(viewType);
    
    // Agora pedimos pro Flutter injetar um pedaço de HTML de verdade no meio do canvas dele.
    ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      // Criamos um iframe (tipo uma janela dentro da janela) apontando para o YouTube.
      return html.IFrameElement()
        ..src = 'https://www.youtube.com/embed/$videoId?rel=0' // rel=0 esconde vídeos relacionados de outros canais
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none' // Tira a borda feia padrão do navegador
        ..allowFullscreen = true
        ..setAttribute('allow', 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture'); // Permissões pro vídeo rodar lisinho
    });
  }
  
  // Retorna o Widget que o Flutter vai conseguir renderizar e colocar na tela.
  return HtmlElementView(viewType: viewType);
}
