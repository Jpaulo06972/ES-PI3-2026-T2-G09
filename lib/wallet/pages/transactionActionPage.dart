// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

// Importa o pacote base do Flutter para construir a interface visual (nossas peças de lego UI)
import 'package:flutter/material.dart';

// Services do sistema — HapticFeedback para gerar vibração tátil (vibração no dedão) ao confirmar, melhorando a UX
import 'package:flutter/services.dart';

// Firestore para atualizar o saldo do usuário diretamente no banco na nuvem
import 'package:cloud_firestore/cloud_firestore.dart';

// Enum com os tipos de operação financeira (deposito, saque, transferencia, pagar, investimento)
// Ajuda a evitar erros de digitação, pois usamos TypeOfOperation.saque em vez da string "saque"
import 'package:mesclainvest_f/enum/typeOfOperation.dart';

// Serviço que conversa com o backend (Cloud Functions) para registrar operações no banco central
import 'package:mesclainvest_f/wallet/services/operationService.dart';

// Modelo de dados do usuário logado — "crachá" do usuário que contém uid, saldo etc.
import 'package:mesclainvest_f/model/userModel.dart';

// Diálogo de sucesso animado — feedback visual que pula na tela após concluir a operação com sucesso
import 'package:mesclainvest_f/components/successDialog.dart';

// Formatador de moeda — pega um double feio (1250) e deixa bonitão ("R$ 1.250,00") e aplica máscara no input
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';

// Barra inferior fixa (rodape) com o valor total e o botão de confirmação que parece teclado
import 'package:mesclainvest_f/wallet/components/transactionBottomBar.dart';

/// Tela de ação financeira.
/// Esta é a tela que abre quando o usuário clica em Depositar, Sacar ou Transferir.
/// Suporta validações de saldo (você não saca se não tem) e destinatário (transferência exige email).
/// É um StatefulWidget porque o valor digitado e os alertas precisam atualizar a tela ao vivo.
class TransactionActionPage extends StatefulWidget {
  // Qual tipo de operação esta tela vai rodar (deposito, saque ou transferencia)?
  final TypeOfOperation type;

  // Quem está fazendo a operação? Precisamos do modelo do usuário pra saber o saldo dele
  final UserModel user;

  const TransactionActionPage({
    super.key,
    required this.type,
    required this.user,
  });

  @override
  State<TransactionActionPage> createState() => _TransactionActionPageState();
}

/// Estado da tela.
/// O TickerProviderStateMixin é usado porque precisamos gerenciar DOIS controladores de animação
/// (um pro botão afundando, outro pra tela aparecendo). Se fosse um só, usaríamos SingleTickerProviderStateMixin.
class _TransactionActionPageState extends State<TransactionActionPage>
    with TickerProviderStateMixin {
  // Controllers são as "canetas" que leem e escrevem nos campos de texto.
  // Controlador do campo de dinheiro (Ex: 100,00)
  final TextEditingController _amountController = TextEditingController();

  // Controlador do campo de e-mail do destinatário (aparece só se for transferência)
  final TextEditingController _targetController = TextEditingController();

  // Controlador do campo de mensagem opcional ("Pra pagar a pizza")
  final TextEditingController _messageController = TextEditingController();

  // Nosso "mensageiro" que chama a Cloud Function de criação de operação lá no servidor
  final OperationService _operationService = OperationService();

  // Flag que trava o botão e gira um spinner enquanto aguardamos o Firebase (evita clique duplo)
  bool _isLoading = false;

  // Animações do botão (quando clica nele, ele dá uma encolhida pra fingir pressão)
  late AnimationController _buttonAnimController;
  late Animation<double> _buttonScale;

  // Animação de entrada da tela: a tela "escorrega" de baixo pra cima suavemente
  late AnimationController _entryAnimController;
  late Animation<double> _fadeIn; // Opacidade
  late Animation<Offset> _slideUp; // Movimento

  // A máscara do dinheiro, que vai colocando os pontos e vírgulas sozinhos enquanto o usuário digita
  final CurrencyInputFormatter _formatter = CurrencyInputFormatter();

  // O verde padrão do app
  static const Color primaryGreen = Color(0xFF107649);

  // Um getter que traduz o "TypeOfOperation" para um título grandão amigável no topo da tela
  String get _title {
    switch (widget.type) {
      case TypeOfOperation.deposito:
        return 'Você vai depositar';
      case TypeOfOperation.saque:
        return 'Você vai sacar';
      case TypeOfOperation.transferencia:
        return 'Você vai enviar';
      default:
        return 'Valor da transação';
    }
  }

  // Getter que escolhe a palavra que vai ficar estampada no botão verde de confirmar
  String get _buttonLabel {
    switch (widget.type) {
      case TypeOfOperation.deposito:
        return 'Depositar';
      case TypeOfOperation.saque:
        return 'Sacar';
      case TypeOfOperation.transferencia:
        return 'Enviar';
      default:
        return 'Confirmar';
    }
  }

  @override
  void initState() {
    super.initState();

    // -- Preparando a animação de apertar o botão --
    // Ela é bem rápida: só 120ms.
    _buttonAnimController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this, // Relógio sincronizado com a tela
    );
    // Tween de "tamanho" 1.0 (100%) pra 0.96 (96%). É aquele leve encolhimento de botão.
    _buttonScale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _buttonAnimController, curve: Curves.easeInOut),
    );

    // -- Preparando a animação de entrada na tela --
    // Mais demorada: 600ms, pra dar um ar solene e macio.
    _entryAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Começa transparente e vai ficando opaco.
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryAnimController, curve: Curves.easeOut),
    );

    // Começa lá embaixo e sobe pra posição Offset.zero.
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entryAnimController, curve: Curves.easeOut),
        );

    // Manda iniciar essa animação principal da tela.
    _entryAnimController.forward();
  }

  @override
  void dispose() {
    // Lembra sempre de descartar (dispose) controllers e animações.
    // Se você não limpar o lixo ao fechar a tela, vai acumular memória (memory leak) e crashar.
    _amountController.dispose();
    _targetController.dispose();
    _messageController.dispose();
    _buttonAnimController.dispose();
    _entryAnimController.dispose();
    super.dispose();
  }

  /// É acionado quando o usuário toca no botão de confirmar na base da tela.
  /// Valida regras matemáticas antes de falar com o banco.
  void _handleConfirm() async {
    // Pega o texto do campo (Ex: "R$ 1.500,00"), arranca os não-números (sobram 150000)
    final String digits = _amountController.text.replaceAll(
      RegExp(r'[^\d]'),
      '',
    );
    // Como os últimos 2 números são centavos, divide por 100 pra transformar em Double.
    final double amount = digits.isEmpty ? 0.0 : double.parse(digits) / 100;

    // 1ª Validação: tentou enviar R$ 0,00? Dá esporro.
    if (amount <= 0) {
      _showSnackBar('Insira um valor válido', isError: true);
      return; // O return cancela o fluxo na hora.
    }

    // 2ª Validação: a não ser que seja depósito (onde grana entra), a pessoa tem que ter o saldo suficiente!
    if (widget.type != TypeOfOperation.deposito && amount > widget.user.saldo) {
      _showSnackBar(
        'Saldo insuficiente para realizar esta operação.',
        isError: true,
      );
      return;
    }

    // 3ª Validação: se for transferência, a pessoa tem que botar o e-mail de quem vai receber.
    if (widget.type == TypeOfOperation.transferencia &&
        _targetController.text.trim().isEmpty) {
      // O "trim" tira os espaços em branco que a pessoa colocou sem querer
      _showSnackBar('Informe o e-mail do destinatário.', isError: true);
      return;
    }

    // Passou das validações! Ativa a flag de loading pra rolar o "spinnerzinho".
    setState(() => _isLoading = true);

    // Faz o celular do usuário dar uma vibradinha. Traz uma satisfação imensa de ter apertado o botão de verdade.
    HapticFeedback.mediumImpact();

    try {
      // Bate lá na porta do servidor via Firebase Functions.
      final success = await _operationService.createOperation(
        amount: amount,
        type: widget.type,
        // Só joga o email se for transferência, caso contrário envia nulo
        targetIdentifier: widget.type == TypeOfOperation.transferencia
            ? _targetController.text.trim()
            : null,
      );

      // Se o servidor respondeu "Sucesso (true)"
      if (success) {
        // "mounted" garante que o usuário não fechou essa tela enquanto esperava o backend responder.
        if (mounted) {
          // Atualiza a memória viva do celular do usuário (o "userModel.saldo")
          if (widget.type == TypeOfOperation.deposito) {
            widget.user.saldo += amount; // Entrou dinheiro
          } else {
            widget.user.saldo -= amount; // Saiu dinheiro
          }

          // Atualiza o valor no espelho do banco de dados (o documento Firestore) pra manter sincronia bruta
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.user.uid)
                .update({
                  'balance': widget.user.saldo,
                  'saldo': widget
                      .user
                      .saldo, // Atualizamos os dois campos possíveis por precaução
                });
          } catch (e) {
            // Se falhou essa gravação extra não choramos, porque a cloud function já processou a transação.
          }

          // Sobe a telinha verde animada comemorando a transação. Esperamos fechar (`await`).
          await _showSuccessDialog(amount);

          // E quando ele fechar, nós expulsamos ele dessa tela aqui de formulário pra voltar pra tela inicial.
          // O `true` viaja de volta pra tela anterior avisando: "Opa, uma transação rolou de verdade".
          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      } else {
        // Backend respondeu que recusou. Motivos? Conta não achada, etc.
        _showSnackBar(
          'Não foi possível processar a operação. Verifique os dados.',
          isError: true,
        );
      }
    } catch (e) {
      // Caiu a internet? Bug bruto? Avisa com vermelho.
      _showSnackBar(
        'Erro de conexão ou destinatário não encontrado.',
        isError: true,
      );
    } finally {
      // Independente de ter dado certo ou errado, desliga o "carregando".
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Exibe aquele Diálogo de sucesso animado gigante que cobre a tela toda.
  Future<void> _showSuccessDialog(double amount) async {
    String successTitle;
    String successMessage;

    // Preparamos o texto que vai no pop-up dependendo da operação que ele fez.
    switch (widget.type) {
      case TypeOfOperation.deposito:
        successTitle = 'Depósito realizado!';
        successMessage =
            'Você depositou ${CurrencyInputFormatter.formatValue(amount)}';
        break;
      case TypeOfOperation.saque:
        successTitle = 'Saque realizado!';
        successMessage =
            'Você sacou ${CurrencyInputFormatter.formatValue(amount)}';
        break;
      case TypeOfOperation.transferencia:
        successTitle = 'Transferência enviada!';
        successMessage =
            '${CurrencyInputFormatter.formatValue(amount)} enviado para\n${_targetController.text.trim()}';
        break;
      default:
        successTitle = 'Operação realizada!';
        successMessage = 'Valor: ${CurrencyInputFormatter.formatValue(amount)}';
    }

    // Aciona a exibição do popup passando essas variáveis, e trava a tela com "await" até fechar.
    await showSuccessDialog(
      context: context,
      title: successTitle,
      message: successMessage,
      buttonLabel: 'Voltar para a Carteira',
      onPressed: () => Navigator.pop(context), // O botão vai matar o diálogo
    );
  }

  /// Puxa a "torradinha" (SnackBar) vermelha ou verde lá na base da tela pra avisar as coisas
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            // Ícone pra dar um toque a mais — se isError é true usa o 'X', senão o V verdezinho
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            // Expanded para o texto não vazar e quebrar as linhas direitinho
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        // Fundo vermelho de alerta (E74C3C) se for erro, ou verde suave
        backgroundColor: isError ? const Color(0xFFE74C3C) : primaryGreen,
        behavior: SnackBarBehavior.floating, // Descola do rodapé!
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold vazio onde a mágica acontece.
    return Scaffold(
      // AppBar transparente só pra colocar a setinha de voltar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(
            context,
          ), // Se voltar aqui, ele não manda "true" (cancela fluxo)
        ),
      ),

      // Animações abraçando tudo
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          // SafeArea protege do "notch" da câmera do iPhone.
          child: SafeArea(
            // Column geral
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tudo no meio é "esticável" com Expanded pra rolar (formulário e cia)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // ── Título dinâmico lá em cima ────────────────────
                        Text(
                          _title, // Pega o title lá do getter
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // E de quebra mostramos quanto saldo ele tem agora, pra ele não passar vergonha
                        Text(
                          'Saldo disponível: ${CurrencyInputFormatter.formatValue(widget.user.saldo)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Campo principal do "Dinheiro" ─────────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Expanded pro TextField esticar até o final e jogar o ícone pro canto
                            Expanded(
                              child: TextField(
                                key: const ValueKey('amount_field'),
                                controller: _amountController,
                                // Aqui o cara do Formatter entra em ação mascarando em "R$..."
                                inputFormatters: [_formatter],
                                // Abre o teclado só numérico
                                keyboardType: TextInputType.number,
                                autofocus:
                                    true, // Já dá foco na hora pra abrir teclado sozinho
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: primaryGreen, // Texto verde bonitão
                                  letterSpacing: -1,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'R\$ 0,00', // Sombra quando não digitou nada
                                  hintStyle: TextStyle(
                                    color: primaryGreen.withOpacity(0.3),
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -1,
                                  ),
                                  border: InputBorder
                                      .none, // Some com as linhas do campo textfield base
                                  contentPadding: EdgeInsets.zero,
                                ),
                                cursorColor:
                                    primaryGreen, // Até o pino de digitação vira verde
                              ),
                            ),
                            // Um Lápis falso só pra indicar que é editável
                            Icon(
                              Icons.edit_outlined,
                              color: primaryGreen.withOpacity(0.7),
                              size: 22,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Avisa "De onde tá saindo o dinheiro" ou pra onde vai
                        Text(
                          'Conta MesclaInvest',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Linha cheia de fru-fru com setinha no meio ────────
                        const Row(
                          children: [
                            Expanded(child: Divider(color: Colors.white12)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(
                                Icons.arrow_downward_rounded,
                                color: Colors.white38,
                                size: 16,
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.white12)),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Campo extra! Só funciona pra "Transferência" ──────────────
                        if (widget.type == TypeOfOperation.transferencia) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _targetController,
                                  style: const TextStyle(
                                    color: primaryGreen,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'E-mail do destinatário',
                                    hintStyle: TextStyle(
                                      color: primaryGreen.withOpacity(0.7),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  cursorColor: primaryGreen,
                                  keyboardType: TextInputType
                                      .emailAddress, // Exige teclado que tem @
                                ),
                              ),
                              Icon(
                                Icons.edit_outlined,
                                color: primaryGreen.withOpacity(0.7),
                                size: 22,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Label descritivo
                          Text(
                            'Destino da transferência',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 24),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 24),
                        ] else ...[
                          // Caso não seja transerência (É depósito ou saque).
                          Text(
                            widget.type == TypeOfOperation.deposito
                                ? 'Sua Conta MesclaInvest'
                                : 'Sua Conta Bancária', // Saque tira pro mundo real
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.type == TypeOfOperation.deposito
                                ? 'Destino do depósito'
                                : 'Destino do saque',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 24),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 24),
                        ],

                        // ── Mais um campo Opcional para Transferência (Mensagem) ─────────
                        if (widget.type == TypeOfOperation.transferencia) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: Colors.white38,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                  maxLines:
                                      null, // Deixa a linha quebrar infinito se ele quiser textão
                                  decoration: const InputDecoration(
                                    hintText: 'Adicionar mensagem (opcional)',
                                    hintStyle: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 15,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                  cursorColor: primaryGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── A Rodapé que não some ──────
                // Ele gruda lá embaixo na tela e exibe o botão pra gente Confirmar.
                TransactionBottomBar(
                  amountController:
                      _amountController, // Repassa o cara do valor
                  buttonScale: _buttonScale, // Passa a animação do dedão
                  isLoading:
                      _isLoading, // O spinner vai rodar aqui dentro se for true
                  buttonLabel: _buttonLabel, // Depositar / Enviar / Sacar
                  onConfirm:
                      _handleConfirm, // A função enorme de mandar ver lá pra cima
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
