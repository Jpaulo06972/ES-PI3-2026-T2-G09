// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

import 'package:flutter/widgets.dart';

/// Esse é um "stub" (um arquivo falso ou vazio de propósito).
/// Por que isso existe? Quando compilamos para Android ou iOS, a biblioteca `dart:html` 
/// não existe e causaria um erro. Como estamos fazendo um import condicional no player principal,
/// o Flutter precisa de algo para importar quando estiver rodando no mobile.
/// Aqui nós simplesmente criamos uma função que devolve um widget invisível (SizedBox.shrink),
/// porque no mobile quem vai renderizar o vídeo é o pacote nativo, não o HTML.
Widget buildWebVideoPlayer(String videoId) => const SizedBox.shrink();
