// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

// Importações necessárias para construirmos a UI e gerenciarmos a entrada de dados.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/primaryButton.dart';
import '../../model/userModel.dart';
import '../../dashboard/pages/home.dart';
import '../services/two_factor_service.dart';

/// Tela de autenticação em duas etapas (2FA/MFA)
/// É um StatefulWidget porque precisamos gerenciar os 6 campos de digitação,
/// o estado de carregamento e as mensagens de erro dinamicamente.
class TwoFactsAuthPage extends StatefulWidget {
  final UserModel userModel;

  const TwoFactsAuthPage({super.key, required this.userModel});

  @override
  State<TwoFactsAuthPage> createState() => _TwoFactsAuthPageState();
}

class _TwoFactsAuthPageState extends State<TwoFactsAuthPage> {
  // Lista de controladores para os 6 campos de digitação (um para cada dígito).
  // Os controladores são como "cadernos" que anotam o que o usuário digita.
  // Criar 6 deles nos permite recuperar o valor de cada caixinha separadamente.
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  // FocusNodes servem para controlar onde o "cursor" está piscando.
  // Quando o usuário preenche um dígito, o foco pula automaticamente para o próximo.
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  // Instância do serviço que se conecta com o backend (Cloud Functions) para lidar com o código 2FA.
  final _service = TwoFactorService();

  // Controla se o aplicativo está validando o código. Usado para mostrar aquele spinner maroto no botão.
  bool _isLoading = false;

  // Diz se o envio/reenvio do código está acontecendo agora no backend.
  bool _isSending = true;

  // Guarda uma mensagem de erro caso o envio do código falhe, assim podemos mostrar na tela.
  String? _sendError;

  @override
  void initState() {
    super.initState();
    // Assim que a tela nasce, já disparamos o envio do código.
    // É uma boa prática para poupar um clique do usuário.
    _sendCode();
  }

  @override
  void dispose() {
    // É fundamental limpar os controladores e focos quando a tela morre.
    // Se não fizer isso, eles ficam ocupando memória à toa (memory leak)!
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  /// Pede para o serviço enviar o código 2FA para o e-mail do usuário.
  Future<void> _sendCode() async {
    // Atualizamos o estado da tela para mostrar que o envio começou e limpamos erros antigos.
    setState(() {
      _isSending = true;
      _sendError = null;
    });

    try {
      // O await segura a execução aqui até que o backend responda.
      await _service.sendCode(widget.userModel.uid, widget.userModel.email);
    } on TwoFactorException catch (e) {
      // O mounted verifica se a tela ainda existe antes de tentarmos dar setState.
      // Nunca atualize uma tela que já foi fechada!
      if (mounted) setState(() => _sendError = e.message);
    } finally {
      // Independentemente de dar certo ou errado, temos que parar de mostrar que estamos enviando.
      if (mounted) setState(() => _isSending = false);
    }
  }

  // Pega o que foi digitado nos 6 controladores e junta tudo numa String só.
  // Assim fica fácil de enviar pro backend validar.
  String get _code => _controllers.map((c) => c.text).join();

  /// O que acontece quando o usuário clica em "Verificar".
  Future<void> _onVerifyPressed() async {
    // Validação simples: se não tem 6 dígitos, nem perde tempo chamando a API.
    if (_code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os 6 dígitos')),
      );
      return;
    }

    // Liga o spinner do botão!
    setState(() => _isLoading = true);

    try {
      // Pede pro serviço validar o código digitado com o backend.
      final valid = await _service.verifyCode(widget.userModel.uid, _code);

      // Sempre faça essa checagem após um await que muda a UI.
      if (!mounted) return;

      if (valid) {
        // Se deu bom, manda o usuário direto pra HomePage e mata a tela atual (pushReplacement).
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(user: widget.userModel),
          ),
        );
      } else {
        // Se o código for errado, avisa com um SnackBar amigável.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código inválido ou expirado.')),
        );
      }
    } on TwoFactorException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      // Desliga o spinner. A validação já terminou.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Limpa os campos e pede um novo código pro backend.
  Future<void> _onResendPressed() async {
    // Esvazia as caixinhas como se nada tivesse acontecido.
    for (final c in _controllers) {
      c.clear();
    }
    // Devolve o foco para o primeiro quadradinho.
    _focusNodes[0].requestFocus();

    // Dispara o envio de novo.
    await _sendCode();

    // Dá um feedback de que funcionou.
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Novo código enviado!')));
    }
  }

  /// Monta um dos 6 bloquinhos numéricos.
  Widget _buildDigitBox(int index) {
    return SizedBox(
      width: 48, // Deixa cada quadradinho com um tamanho agradável para clique.
      height: 56,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center, // Texto centralizado pra ficar bonitinho.
        keyboardType:
            TextInputType.number, // Já sobe o teclado numérico por padrão.
        // Garante que só cabe 1 número aqui, nem letras nem mais dígitos.
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            // Uma borda colorida quando a caixinha tá selecionada ajuda o usuário a se achar.
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
        ),
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        onChanged: (value) {
          // Mágica de UX:
          // Se digitou algo e não é a última caixa, pula pra próxima.
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          }
          // Se apagou e não é a primeira caixa, volta pra anterior.
          else if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // O Scaffold nos dá a tela em branco para trabalhar.
    return Scaffold(
      body: Center(
        // SingleChildScrollView salva nossa vida em telas menores ou quando o teclado sobe,
        // evitando aquele erro feio de overflow amarelo e preto.
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ícone bacana para dar a ideia de segurança no topo.
              Icon(
                Icons.verified_user_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16), // Espaçamento básico entre elementos.

              const Text(
                'Verificação em duas etapas',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Controla o que mostrar dependendo de onde o backend está.
              if (_isSending)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_sendError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _sendError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                )
              else
                Text(
                  'Insira o código de 6 dígitos enviado para ${widget.userModel.email}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade300),
                ),

              const SizedBox(height: 40),

              // Row com MainAxisAlignment.spaceBetween espalha as 6 caixinhas uniformemente.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, _buildDigitBox),
              ),
              const SizedBox(height: 32),

              // Botão gigante de "Verificar" (nosso componente customizado).
              PrimaryButton(
                label: 'Verificar',
                onPressed: _onVerifyPressed,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 20),

              // Botão em formato de texto para reenvio do código.
              Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  // Se já estiver enviando, desabilita o toque para não fazer spam de chamadas.
                  onTap: _isSending ? null : _onResendPressed,
                  child: Text(
                    'Não recebi o código',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Um botão de fuga: às vezes o usuário lembrou que precisa logar com outra conta.
              Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () => Navigator.pop(
                    context,
                  ), // Tira a tela atual da pilha (volta pro login).
                  child: Text(
                    'Voltar para o login',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
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
}
