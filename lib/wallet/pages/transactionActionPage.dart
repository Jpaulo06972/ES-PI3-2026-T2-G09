// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesclainvest_f/enum/typeOfOperation.dart';
import 'package:mesclainvest_f/wallet/services/operationService.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/components/successDialog.dart';
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';

/// Tela de ação financeira inspirada no app da Nubank.
/// Suporta Depósito, Saque e Transferência com validações de saldo e destinatário.
/// Apresenta animações suaves e feedback visual premium ao usuário.
class TransactionActionPage extends StatefulWidget {
  final TypeOfOperation type;
  final UserModel user;

  const TransactionActionPage({
    super.key,
    required this.type,
    required this.user,
  });

  @override
  State<TransactionActionPage> createState() => _TransactionActionPageState();
}

class _TransactionActionPageState extends State<TransactionActionPage>
    with TickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final OperationService _operationService = OperationService();
  bool _isLoading = false;

  // Controle de animação do botão
  late AnimationController _buttonAnimController;
  late Animation<double> _buttonScale;

  // Controle de animação de entrada
  late AnimationController _entryAnimController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  final CurrencyInputFormatter _formatter = CurrencyInputFormatter();

  // Cor característica (Verde MesclaInvest)
  static const Color primaryGreen = Color(0xFF107649);

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

    // Animação de escala do botão ao pressionar
    _buttonAnimController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _buttonAnimController, curve: Curves.easeInOut),
    );

    // Animação de entrada suave
    _entryAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryAnimController, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entryAnimController, curve: Curves.easeOut),
        );
    _entryAnimController.forward();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _targetController.dispose();
    _buttonAnimController.dispose();
    _entryAnimController.dispose();
    super.dispose();
  }

  void _handleConfirm() async {
    final String digits = _amountController.text.replaceAll(
      RegExp(r'[^\d]'),
      '',
    );
    final double amount = digits.isEmpty ? 0.0 : double.parse(digits) / 100;
    //debugPrint('[TransactionAction] Valor parseado: $amount (digits: $digits, text: ${_amountController.text})');

    if (amount <= 0) {
      _showSnackBar('Insira um valor válido', isError: true);
      return;
    }

    // Validação de saldo para operações de saída
    if (widget.type != TypeOfOperation.deposito && amount > widget.user.saldo) {
      _showSnackBar(
        'Saldo insuficiente para realizar esta operação.',
        isError: true,
      );
      return;
    }

    // Validação de destinatário para transferências
    if (widget.type == TypeOfOperation.transferencia &&
        _targetController.text.trim().isEmpty) {
      _showSnackBar('Informe o e-mail do destinatário.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    // Feedback háptico ao confirmar
    HapticFeedback.mediumImpact();

    try {
      final success = await _operationService.createOperation(
        amount: amount,
        type: widget.type,
        targetIdentifier: widget.type == TypeOfOperation.transferencia
            ? _targetController.text.trim()
            : null,
      );

      if (success) {
        if (mounted) {
          // Atualiza o saldo localmente dependendo da operação
          if (widget.type == TypeOfOperation.deposito) {
            widget.user.saldo += amount;
          } else {
            widget.user.saldo -= amount;
            // Em caso de transferência, poderíamos atualizar o saldo do destinatário
            // Mas assumimos que se a function não faz, ou faz em background,
            // garantimos pelo menos o nosso saldo aqui.
          }

          // Atualiza o saldo no banco de dados (Firestore)
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.user.uid)
                .update({
                  'balance': widget.user.saldo,
                  'saldo': widget
                      .user
                      .saldo, // garantindo atualização nas chaves usadas
                });
            //debugPrint(
            //'[TransactionAction] Saldo atualizado no Firestore para: ${widget.user.saldo}',
            //);
          } catch (e) {
            //debugPrint(
            //'[TransactionAction] Erro ao atualizar saldo no Firestore: $e',
            //);
          }

          // Mostra a tela de sucesso antes de voltar
          await _showSuccessDialog(amount);
          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      } else {
        _showSnackBar(
          'Não foi possível processar a operação. Verifique os dados.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar(
        'Erro de conexão ou destinatário não encontrado.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Exibe um diálogo de sucesso animado no estilo Nubank
  Future<void> _showSuccessDialog(double amount) async {
    String successTitle;
    String successMessage;
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

    await showSuccessDialog(
      context: context,
      title: successTitle,
      message: successMessage,
      buttonLabel: 'Voltar para a Carteira',
      onPressed: () => Navigator.pop(context),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
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
        backgroundColor: isError ? const Color(0xFFE74C3C) : primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Icon(icon, color: Colors.white54, size: 22),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // ── Título da operação ──────────────────────────────────
                        Text(
                          _title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Saldo atual do usuário
                        Text(
                          'Saldo disponível: ${CurrencyInputFormatter.formatValue(widget.user.saldo)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Campo de valor ──────────────────────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: TextField(
                                key: const ValueKey('amount_field'),
                                controller: _amountController,
                                inputFormatters: [_formatter],
                                keyboardType: TextInputType.number,
                                autofocus: true,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: primaryGreen,
                                  letterSpacing: -1,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'R\$ 0,00',
                                  hintStyle: TextStyle(
                                    color: primaryGreen.withOpacity(0.3),
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -1,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                cursorColor: primaryGreen,
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
                        Text(
                          'Conta MesclaInvest',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Divisor com seta ──────────────────────────────────────
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

                        // ── Destinatário (Apenas Transferência) ─────────────────
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
                                  keyboardType: TextInputType.emailAddress,
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
                          // Caso não seja transferência, mostramos para onde vai o dinheiro ou de onde sai
                          Text(
                            widget.type == TypeOfOperation.deposito
                                ? 'Sua Conta MesclaInvest'
                                : 'Sua Conta Bancária',
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

                        // ── Detalhes adicionais ──────────────────────────────────
                        _buildDetailRow(
                          'Quando',
                          'Agora, sem repetir',
                          Icons.calendar_today_outlined,
                        ),
                        const SizedBox(height: 24),
                        _buildDetailRow(
                          'Via',
                          widget.type == TypeOfOperation.transferencia
                              ? 'Transferência interna'
                              : 'Saldo do app',
                          Icons.account_balance_wallet_outlined,
                        ),
                        const SizedBox(height: 24),

                        // "Detalhes" expandable or just message
                        if (widget.type == TypeOfOperation.transferencia) ...[
                          _buildDetailRow(
                            'Mensagem',
                            'Adicionar mensagem',
                            Icons.chat_bubble_outline_rounded,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Bottom Bar ────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _amountController,
                            builder: (context, value, child) {
                              return Text(
                                value.text.isEmpty ? 'R\$ 0,00' : value.text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Valor Total',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      ScaleTransition(
                        scale: _buttonScale,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: primaryGreen.withOpacity(
                              0.25,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                30,
                              ), // pill shape
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _buttonLabel,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
