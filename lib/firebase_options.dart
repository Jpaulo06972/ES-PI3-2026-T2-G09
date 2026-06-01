// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

// Arquivo gerado automaticamente pelo FlutterFire CLI.
// Ele contém as credenciais e configurações do Firebase para cada plataforma
// (Android, iOS, Web, macOS, Windows). Sempre que mudar algo no projeto Firebase,
// basta rodar o CLI de novo que ele atualiza este arquivo.
// ignore_for_file: type=lint

// Importa a classe FirebaseOptions, que carrega as credenciais do projeto Firebase
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

// Importa utilitários para detectar em qual plataforma o app está rodando
// kIsWeb = true se está no navegador, defaultTargetPlatform = Android, iOS, etc.
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Classe que fornece as configurações padrão do Firebase para o app MesclaInvest.
///
/// Exemplo de uso no main.dart:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  // Getter estático que detecta automaticamente a plataforma atual
  // e retorna as credenciais corretas do Firebase para ela.
  // Isso permite que o mesmo código funcione em Android, iOS, Web, etc.
  static FirebaseOptions get currentPlatform {
    // Se está rodando no navegador (Chrome, Firefox, etc.), usa as credenciais web
    if (kIsWeb) {
      return web;
    }
    // Se não é web, verifica qual plataforma nativa está sendo usada
    switch (defaultTargetPlatform) {
      // Retorna as credenciais específicas para cada sistema operacional
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      // Linux não foi configurado — lança erro com instrução para o dev
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      // Qualquer outra plataforma desconhecida também lança erro
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Credenciais do Firebase para a versão Web do app
  // Inclui authDomain (domínio de autenticação) e measurementId (Google Analytics)
  // que são exclusivos da plataforma web
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA4I54E-IfGuokC12adDsVHUm82dvbhghs',
    appId: '1:909599138209:web:1882c7ed494b480d30abe0',
    messagingSenderId: '909599138209',
    projectId: 'mesclainvest-5ee48',
    authDomain: 'mesclainvest-5ee48.firebaseapp.com',
    storageBucket: 'mesclainvest-5ee48.firebasestorage.app',
    measurementId: 'G-QQLZK4E41T',
  );

  // Credenciais do Firebase para Android
  // Não precisa de authDomain nem measurementId porque o SDK nativo resolve isso
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA2IYTCFS4XG01ce65PkSwR6cER-2XrzA8',
    appId: '1:909599138209:android:84a473d2a15b811630abe0',
    messagingSenderId: '909599138209',
    projectId: 'mesclainvest-5ee48',
    storageBucket: 'mesclainvest-5ee48.firebasestorage.app',
  );

  // Credenciais do Firebase para iOS (iPhone e iPad)
  // Usa apiKey diferente do Android por questões de segurança do Firebase
  // iosBundleId identifica o app na App Store da Apple
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDLziOlpdXQcxMhpjcSU-38WYtYjXX_xmU',
    appId: '1:909599138209:ios:9aa4753f301e97d530abe0',
    messagingSenderId: '909599138209',
    projectId: 'mesclainvest-5ee48',
    storageBucket: 'mesclainvest-5ee48.firebasestorage.app',
    iosBundleId: 'com.example.mesclainvestf',
  );

  // Credenciais do Firebase para macOS
  // Compartilha as mesmas credenciais do iOS porque ambos são da Apple
  // e usam o mesmo ecossistema de certificados e bundle IDs
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDLziOlpdXQcxMhpjcSU-38WYtYjXX_xmU',
    appId: '1:909599138209:ios:9aa4753f301e97d530abe0',
    messagingSenderId: '909599138209',
    projectId: 'mesclainvest-5ee48',
    storageBucket: 'mesclainvest-5ee48.firebasestorage.app',
    iosBundleId: 'com.example.mesclainvestf',
  );

  // Credenciais do Firebase para Windows (desktop)
  // Usa as mesmas credenciais da web porque o Flutter desktop no Windows
  // se comunica com o Firebase pela mesma API web
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA4I54E-IfGuokC12adDsVHUm82dvbhghs',
    appId: '1:909599138209:web:2345c03c0e641f9430abe0',
    messagingSenderId: '909599138209',
    projectId: 'mesclainvest-5ee48',
    authDomain: 'mesclainvest-5ee48.firebaseapp.com',
    storageBucket: 'mesclainvest-5ee48.firebasestorage.app',
    measurementId: 'G-6YXGSDER4M',
  );
}
