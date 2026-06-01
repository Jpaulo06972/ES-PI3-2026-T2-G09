// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

// Importa o pacote básico de UI do Flutter (Material Design)
import 'package:flutter/material.dart';

// Importa utilitários para controlar entrada do teclado
// (limitar quantidade de caracteres e filtrar apenas dígitos numéricos)
import 'package:flutter/services.dart';

// Importa componentes reutilizáveis do projeto
import '../components/primaryButton.dart';
import '../components/navLink.dart';

// Importa o serviço de reset de senha e a próxima tela do fluxo
import '../services/passwordResetService.dart';
import 'newPasswordPage.dart'; // Etapa 3: criar nova senha
import 'signin.dart'; // Para o link "Voltar para o login"

/*
 * Tela onde o usuário digita o código de 6 dígitos recebido por e-mail.
 * É a etapa 2 do fluxo de recuperação de senha:
 * 1. passRecovery → 2. passRecoveryCode (esta tela) → 3. newPasswordPage
 *
 * Interface inspirada em apps bancários: 6 quadradinhos individuais
 * com avanço automático do cursor, proporcionando uma experiência fluida.
 */
class PassRecoveryCodePage extends StatefulWidget {
  // E-mail do usuário — recebido da tela anterior (passRecovery)
  // Necessário para identificar a conta no backend ao verificar o código
  final String email;

  const PassRecoveryCodePage({super.key, required this.email});

  @override
  State<PassRecoveryCodePage> createState() => _PassRecoveryCodePageState();
}

// Estado da tela — gerencia os 6 campos de dígito, foco e interações com o backend
class _PassRecoveryCodePageState extends State<PassRecoveryCodePage> {
  // 6 controllers — um para cada quadradinho de dígito
  // Cada um armazena exatamente 1 caractere numérico
  // List.generate cria a lista de forma programática em vez de escrever 6 vezes
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  // 6 FocusNodes para controlar qual campo está ativo (recebendo digitação)
  // Precisamos de nós de foco separados para implementar o avanço automático
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  // Instância do serviço de reset de senha — faz as chamadas às Cloud Functions
  final _service = PasswordResetService();

  // Loading do botão "Continuar" — fica true durante a verificação do código
  bool _isLoading = false;

  // Loading do botão "Reenviar" — separado para não travar os dois botões ao mesmo tempo
  bool _isResending = false;

  // Limpa controllers e focusNodes ao sair da tela para evitar memory leak
  // Cada um aloca recursos nativos que precisam ser liberados manualmente
  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // Getter que junta os 6 dígitos individuais num código só (ex: "123456")
  // Usa map para extrair o texto de cada controller e join para concatenar
  String get _code => _controllers.map((c) => c.text).join();

  // Ao pressionar "Continuar" — valida o código no backend antes de navegar
  // Se o código estiver correto, avança para a tela de criar nova senha
  Future<void> _onVerifyPressed() async {
    // Verifica se todos os 6 dígitos foram preenchidos
    if (_code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os 6 dígitos')),
      );
      return;
    }

    // Liga o loading do botão "Continuar"
    setState(() => _isLoading = true);

    try {
      // Envia o código para a Cloud Function que verifica se é válido e não expirou
      await _service.verifyCode(email: widget.email, code: _code);

      // Verifica se a tela ainda está ativa antes de navegar
      if (!mounted) return;

      // Código verificado com sucesso! Avança para a etapa 3 (criar nova senha)
      // Passa o e-mail e o código para a próxima tela usá-los na redefinição
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NewPasswordPage(email: widget.email, code: _code),
        ),
      );
    } on PasswordResetException catch (e) {
      // Erro tratado: código expirado, inválido ou já usado
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      // Desliga o loading independente do resultado
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Ao pressionar "Reenviar" — gera e envia um novo código para o mesmo e-mail
  // Também limpa os campos e volta o foco para o primeiro quadradinho
  Future<void> _onResendPressed() async {
    // Liga o loading específico do botão "Reenviar"
    setState(() => _isResending = true);

    try {
      // Solicita novo código ao backend — o código anterior é invalidado
      await _service.sendResetCode(widget.email);

      if (!mounted) return;

      // Limpa todos os 6 campos para que o usuário digite o novo código
      for (final c in _controllers) {
        c.clear();
      }

      // Volta o foco para o primeiro campo — UX fluida
      _focusNodes[0].requestFocus();

      // Feedback visual de sucesso para o usuário
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Novo código enviado!')));
    } on PasswordResetException catch (e) {
      // Erro tratado — ex: muitas tentativas, e-mail não encontrado
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      // Desliga o loading do botão "Reenviar"
      if (mounted) setState(() => _isResending = false);
    }
  }

  // Constrói cada quadradinho de dígito com foco automático
  // Recebe o índice (0-5) para saber qual controller e focusNode usar
  Widget _buildDigitBox(int index) {
    return SizedBox(
      width: 44, // Largura fixa de cada quadradinho
      height: 50, // Altura fixa de cada quadradinho
      child: TextFormField(
        controller: _controllers[index], // Controller específico deste campo
        focusNode: _focusNodes[index], // Nó de foco específico deste campo
        textAlign: TextAlign.center, // Centraliza o dígito dentro do quadrado
        keyboardType: TextInputType.number, // Abre o teclado numérico

        // Formatadores de entrada — restringem o que pode ser digitado
        inputFormatters: [
          LengthLimitingTextInputFormatter(1), // Aceita no máximo 1 caractere
          FilteringTextInputFormatter.digitsOnly, // Apenas números (0-9)
        ],

        // Visual do quadradinho — borda arredondada com destaque quando focado
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero, // Sem padding interno extra
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          // Quando o campo está ativo, a borda fica na cor primária e mais grossa
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
        ),

        // Estilo do dígito — grande e em negrito para fácil leitura
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),

        // Lógica de avanço/retrocesso automático do foco
        // Quando o usuário digita um número, o cursor pula para o próximo campo
        // Quando apaga, o cursor volta para o campo anterior
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            // Digitou algo e não é o último campo → avança para o próximo
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          } else if (value.isEmpty && index > 0) {
            // Apagou e não é o primeiro campo → volta para o anterior
            FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
          }
        },
      ),
    );
  }

  // Constrói toda a interface visual da tela
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ícone de e-mail verificado — reforça visualmente que um código foi enviado
              Icon(
                Icons.mark_email_read_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),

              // Título da tela
              const Text(
                'Verifique seu e-mail',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Instrução personalizada com o e-mail do usuário
              // Mostra para qual endereço o código foi enviado
              Text(
                'Insira o código de 6 dígitos enviado para ${widget.email}.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade300),
              ),
              const SizedBox(height: 32),

              // Os 6 quadradinhos de dígito dispostos horizontalmente
              // List.generate cria os widgets programaticamente, evitando repetição
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, _buildDigitBox),
              ),
              const SizedBox(height: 32),

              // Botão "Continuar" — verifica o código no backend
              PrimaryButton(
                label: 'Continuar',
                onPressed: _onVerifyPressed,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 20),

              // Seção "Não recebeu?" com link para reenviar o código
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Texto descritivo
                  Text(
                    'Não recebeu o código?',
                    style: TextStyle(color: Colors.grey.shade300),
                  ),
                  const SizedBox(width: 4),
                  // Alterna entre loading e link clicável "Reenviar"
                  _isResending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          // Bolinha pequena de loading enquanto reenvia
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : GestureDetector(
                          // Ao tocar, dispara o reenvio do código
                          onTap: _onResendPressed,
                          child: Container(
                            padding: const EdgeInsets.only(bottom: 1),
                            // Sublinhado customizado — mesmo estilo do NavLink
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Text(
                              'Reenviar',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 12),

              // Link para desistir e voltar à tela de login
              NavLink(
                destination: const SignInPage(),
                label: 'Voltar para o login',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
