// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/enum/typeOfOperation.dart';
import 'package:mesclainvest_f/counter/services/operationService.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/startups/components/startup_colors.dart';

/// Tela de ação financeira inspirada no app da Nubank.
/// Suporta Depósito, Saque e Transferência com validações de saldo e destinatário.
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

class _TransactionActionPageState extends State<TransactionActionPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final OperationService _operationService = OperationService();
  bool _isLoading = false;

  // Cor característica (Substituída pelo Verde MesclaInvest)
  static const Color primaryGreen = StartupColors.green;
  static const Color backgroundDark = Color(0xFF0D0F0F);

  String get _title {
    switch (widget.type) {
      case TypeOfOperation.deposito:
        return 'Qual o valor do depósito?';
      case TypeOfOperation.saque:
        return 'Quanto você quer sacar?';
      case TypeOfOperation.transferencia:
        return 'Quanto você quer transferir?';
      default:
        return 'Valor da transação';
    }
  }

  String get _buttonLabel {
    switch (widget.type) {
      case TypeOfOperation.deposito:
        return 'Confirmar Depósito';
      case TypeOfOperation.saque:
        return 'Confirmar Saque';
      case TypeOfOperation.transferencia:
        return 'Continuar para Transferência';
      default:
        return 'Confirmar';
    }
  }

  void _handleConfirm() async {
    final amountText = _amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      _showSnackBar('Insira um valor válido maior que zero.');
      return;
    }

    // Validação de saldo para operações de saída
    if (widget.type != TypeOfOperation.deposito && amount > widget.user.saldo) {
      _showSnackBar('Saldo insuficiente para realizar esta operação.');
      return;
    }

    // Validação de destinatário para transferências
    if (widget.type == TypeOfOperation.transferencia && _targetController.text.trim().isEmpty) {
      _showSnackBar('Informe o e-mail do destinatário.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _operationService.createOperation(
        amount: amount,
        type: widget.type,
        targetIdentifier: widget.type == TypeOfOperation.transferencia ? _targetController.text.trim() : null,
      );

      if (success) {
        if (mounted) {
          Navigator.pop(context, true); // Retorna true para atualizar a lista na tela anterior
        }
      } else {
        _showSnackBar('Não foi possível processar a operação. Verifique os dados.');
      }
    } catch (e) {
      _showSnackBar('Erro de conexão ou destinatário não encontrado.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      appBar: AppBar(
        backgroundColor: backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Título no topo
              Text(
                _title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const Spacer(), // Empurra o conteúdo para o centro
              
              // Conteúdo centralizado (Valor e Saldo)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _amountController,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(
                      prefixText: 'R\$ ',
                      prefixStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      hintText: '0,00',
                      hintStyle: TextStyle(color: Colors.white24),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Saldo disponível: R\$ ${widget.user.saldo.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),

              if (widget.type == TypeOfOperation.transferencia) ...[
                const SizedBox(height: 48),
                const Text(
                  'Para quem?',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                TextField(
                  controller: _targetController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: const InputDecoration(
                    hintText: 'E-mail do destinatário',
                    hintStyle: TextStyle(color: Colors.white24),
                    border: InputBorder.none,
                  ),
                ),
              ],

              const Spacer(), // Empurra o botão para baixo

              // Botão de Confirmação na base
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primaryGreen.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : Text(
                          _buttonLabel,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
