// Importa o pacote básico de UI do Flutter (widgets, Material Design, etc.)
import 'package:flutter/material.dart';

// Importa suporte a localização (tradução de textos do sistema para PT-BR)
import 'package:flutter_localizations/flutter_localizations.dart';

// Importa o Firebase Core para inicializar a conexão com o Firebase
import 'package:firebase_core/firebase_core.dart';

// Importa as configurações automáticas do Firebase (gerado pelo FlutterFire CLI)
import 'firebase_options.dart';

// Importa a tela de login como tela inicial do app
import 'autentication/pages/signin.dart';

// Função principal que inicia o aplicativo
// É async porque precisa esperar o Firebase inicializar antes de rodar o app
void main() async {
  // Garante que os bindings do Flutter estejam prontos antes de inicializar o Firebase
  // Isso é obrigatório quando usamos código assíncrono no main()
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase com as configurações da plataforma atual (Android, iOS, Web)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicia o app com o widget raiz MyApp
  runApp(const MyApp());
}

// Widget raiz do aplicativo MesclaInvest
// Configura o tema, idioma e a tela inicial
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Nome do app que aparece no gerenciador de tarefas do celular
      title: 'Mescla Invest',

      // Remove a faixa "DEBUG" vermelha do canto superior direito
      debugShowCheckedModeBanner: false,

      // Define o idioma do app como Português do Brasil
      // Isso traduz textos do sistema (ex: "OK", "Cancelar", calendários, etc.)
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        // Traduz componentes do Material Design (botões, diálogos, etc.)
        GlobalMaterialLocalizations.delegate,
        // Traduz direção de texto e formatação de widgets
        GlobalWidgetsLocalizations.delegate,
        // Traduz componentes do estilo iOS (Cupertino)
        GlobalCupertinoLocalizations.delegate,
      ],

      // Tema claro — usado se o celular estiver no modo claro
      // A cor base é o verde institucional do MesclaInvest
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF107649)),
        useMaterial3: true,
      ),

      // Tema escuro — usado se o celular estiver no modo escuro
      // Mesma cor verde, mas com brilho adaptado para fundos escuros
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF107649),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),

      // Força o tema escuro independente da configuração do celular do usuário
      themeMode: ThemeMode.dark,

      // Tela inicial do app: tela de Login
      home: const SignInPage(),
    );
  }
}
