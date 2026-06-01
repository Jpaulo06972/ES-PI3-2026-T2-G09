// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

import 'dart:math';
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/startups/components/startup_colors.dart';

/// Modal (bottom sheet) que permite ao usuário lançar uma Nova Oferta no livro.
/// Diferente da "compra a mercado" (Market Order), aqui o usuário dita as regras:
/// ele diz QUANTO quer pagar e QUANTOS tokens quer. (Limit Order).
/// O bacana é que essa tela suporta tanto intenções de COMPRA quanto de VENDA
/// (passando a prop type == 'buy' ou 'sell').
class PlaceBuyOfferSheet extends StatefulWidget {
  final String startupId;
  final String startupName;
  final UserModel userModel;
  final double currentMarketPrice;
  final String type; // 'buy' (Comprar) ou 'sell' (Vender)

  const PlaceBuyOfferSheet({
    super.key,
    required this.startupId,
    required this.startupName,
    required this.userModel,
    required this.currentMarketPrice,
    required this.type,
  });

  @override
  State<PlaceBuyOfferSheet> createState() => _PlaceBuyOfferSheetState();
}

class _PlaceBuyOfferSheetState extends State<PlaceBuyOfferSheet> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Controlador pro campinho de texto onde o usuário digita o preço manualmente
  final TextEditingController _priceCtrl = TextEditingController();

  double _qty = 10; // Qtd inicial sugerida
  double _price = 0.0;
  bool _isSubmitting = false; // Controle pra evitar clique duplo
  String? _errorMessage; // Mensagem de erro que sobe se algo der errado
  
  // Variáveis para carregar os "limites" do usuário (se tem dinheiro, se tem token)
  double _availableBalance = 0.0; // Grana R$
  double _availableTokens = 0.0; // Tokens daquela startup
  bool _isLoadingLimits = true; // Controla o loader inicial de saldos

  @override
  void initState() {
    super.initState();
    // Inicia o preço com o preço de mercado atual pra facilitar a vida
    _price = widget.currentMarketPrice;
    _priceCtrl.text = _price.toStringAsFixed(2).replaceAll('.', ',');
    // Busca na base os saldos do cara
    _loadUserLimits();
  }

  @override
  void dispose() {
    // É sempre importante limpar os text controllers da memória 
    // quando a tela fecha, senão dá memory leak.
    _priceCtrl.dispose();
    super.dispose();
  }

  /// Vai no Firebase bater os saldos reais do usuário neste exato momento.
  /// A gente faz isso pra não confiar num saldo velho que tava guardado no app.
  Future<void> _loadUserLimits() async {
    setState(() => _isLoadingLimits = true);
    try {
      // 1. Carrega saldo R$ do usuário
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.userModel.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        _availableBalance = (data['saldo'] ?? data['balance'] ?? 0.0).toDouble();
      } else {
        // Fallback pro saldo do UserModel local
        _availableBalance = widget.userModel.saldo;
      }

      // 2. Carrega quantidade de tokens da startup (Coleção 'holdings')
      final holdingDoc = await _firestore
          .collection('holdings')
          .doc('${widget.userModel.uid}_${widget.startupId}')
          .get();
          
      if (holdingDoc.exists) {
        _availableTokens =
            (holdingDoc.data()?['quantity'] as num?)?.toDouble() ?? 0.0;
      } else {
        // Fallback pro modelo velho onde a gente salvava tokens dentro da Startup
        final investorDoc = await _firestore
            .collection('startups')
            .doc(widget.startupId)
            .collection('investors')
            .doc(widget.userModel.uid)
            .get();
        _availableTokens = investorDoc.exists
            ? ((investorDoc.data()?['tokens'] as num?)?.toDouble() ?? 0.0)
            : 0.0;
      }

      // Se a tela não fechou ainda, tira o loader.
      if (mounted) {
        setState(() => _isLoadingLimits = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _availableBalance = widget.userModel.saldo;
          _availableTokens = 0.0;
          _isLoadingLimits = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Valor total da brincadeira
    final double totalCost = _qty * _price;
    final bool isBuy = widget.type == 'buy';
    
    // Verifica os limites. 
    // Se for compra, precisa ter Grana. Se for venda, precisa ter Token.
    final bool hasLimits = isBuy
        ? _availableBalance >= totalCost
        : _availableTokens >= _qty;

    return Container(
      // Padding pro modal não ser coberto pelo teclado
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: StartupColors.pageBg, // Fundo temático
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra indicando que é arrastável (Drag handle)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Cabeçalho e Botão de fechar (X)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.startupName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // O Título muda de cor e de texto de acordo com a operação
                        Text(
                          isBuy
                              ? 'ENVIAR OFERTA DE COMPRA'
                              : 'ENVIAR OFERTA DE VENDA',
                          style: TextStyle(
                            color: isBuy
                                ? StartupColors.green
                                : const Color(0xFFE74C3C),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Caixa informando o Preço Atual de Mercado, serve de guia pro usuário.
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF141416),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Preço de mercado atual:',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                    Text(
                      CurrencyInputFormatter.formatValue(
                        widget.currentMarketPrice,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Controle de Quantidade usando o bom e velho Stepper (+ / -)
              const Text(
                'Quantidade de tokens',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141416),
                  borderRadius: BorderRadius.circular(14),
                  // A borda muda de cor dependendo da operação (verde/vermelha)
                  border: Border.all(
                    color: isBuy
                        ? StartupColors.green.withOpacity(0.3)
                        : const Color(0xFFE74C3C).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    _buildStepBtn(
                      icon: Icons.remove,
                      onTap: () {
                        // Não pode mandar ordem menor que 1 token
                        if (_qty > 1) setState(() => _qty--);
                      },
                    ),
                    Expanded(
                      child: Text(
                        _qty.toInt().toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _buildStepBtn(
                      icon: Icons.add,
                      onTap: () {
                        setState(() => _qty++);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Campo para digitar o Preço Manualmente (Essa é a graça da Limit Order)
              const Text(
                'Preço por token (R\$)',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141416),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isBuy
                        ? StartupColors.green.withOpacity(0.3)
                        : const Color(0xFFE74C3C).withOpacity(0.3),
                  ),
                ),
                child: TextField(
                  controller: _priceCtrl,
                  // Traz o teclado com números e ponto já na cara
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    prefixText: 'R\$ ',
                    prefixStyle: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  // Formata sempre que digita (troca vírgula por ponto pra virar double)
                  onChanged: (val) {
                    final cleanVal = val.replaceAll(',', '.');
                    setState(() {
                      _price = double.tryParse(cleanVal) ?? 0.0;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Resumo (o "boleto" final antes de aprovar)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141416),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Texto diferente se vai pagar ou se vai receber
                    _buildSummaryRow(
                      isBuy
                          ? 'Total da oferta (reservado)'
                          : 'Total estimado a receber',
                      CurrencyInputFormatter.formatValue(totalCost),
                      highlight: true,
                    ),
                    const SizedBox(height: 10),
                    // Se ainda não buscou saldo, joga um spinner aqui
                    if (_isLoadingLimits)
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: StartupColors.green,
                        ),
                      )
                    else
                      // Se já tem saldo, mostra o quanto tem
                      _buildSummaryRow(
                        isBuy ? 'Saldo disponível' : 'Tokens disponíveis',
                        isBuy
                            ? CurrencyInputFormatter.formatValue(
                                _availableBalance,
                              )
                            : '${_availableTokens.toInt()} tokens',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Se estourou os limites, manda bronca visual com texto vermelho!
              if (!_isLoadingLimits && !hasLimits)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFE74C3C),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isBuy
                            ? 'Saldo disponível insuficiente.'
                            : 'Participação de tokens insuficiente.',
                        style: const TextStyle(
                          color: Color(0xFFE74C3C),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              // Se a operação deu erro do backend, exibe aqui.
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFE74C3C),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFE74C3C),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Botão Mestre de Confirmar (O famoso "Vai ou Racha")
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // Botão verde pra compra, vermelho pra venda. Se travar, fica cinza.
                    backgroundColor: hasLimits && _price > 0 && !_isSubmitting
                        ? (isBuy
                              ? StartupColors.green
                              : const Color(0xFFE74C3C))
                        : Colors.white12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: hasLimits && _price > 0 && !_isSubmitting
                      ? _submitOffer
                      : null,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Enviar Oferta',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
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

  /// Construtor pros botõezinhos + e - da quantidade.
  Widget _buildStepBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 54,
        height: 54,
        alignment: Alignment.center,
        child: Icon(
          icon,
          // Cor do icone de acordo com a operação
          color: widget.type == 'buy'
              ? StartupColors.green
              : const Color(0xFFE74C3C),
          size: 22,
        ),
      ),
    );
  }

  /// Construtor de uma "linha de resumo" pro final. Ex: 'Total: R$ 50,00'
  Widget _buildSummaryRow(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight
                ? (widget.type == 'buy'
                      ? StartupColors.green
                      : const Color(0xFFE74C3C))
                : Colors.white,
            fontSize: 14,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Lógica de Matching (O coração financeiro dessa tela).
  /// Envia a oferta para o Firestore rodando o "casamento" com ordens opostas.
  void _submitOffer() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final String currentUserId = widget.userModel.uid;
    final String startupId = widget.startupId;
    final double quantity = _qty;
    final double pricePerToken = _price;
    final double total = quantity * pricePerToken;
    final String type = widget.type;

    try {
      // 1. Busca no banco se já existe alguém do outro lado querendo fechar negócio 
      //    com esse exato mesmo preço (se compramos, busca venda. se vendemos, compra).
      final oppositeOffersQuery = await _firestore
          .collection('offers')
          .where('startupId', isEqualTo: startupId)
          .where('type', isEqualTo: type == 'buy' ? 'sell' : 'buy') // inverte
          .where('status', isEqualTo: 'open') // Só ofertas ativas
          .where('pricePerToken', isEqualTo: pricePerToken) // Matching exato de preço
          .orderBy('timestamp', descending: false) // FIFO (First In First Out)
          .get();

      final candidates = oppositeOffersQuery.docs;

      // 2. Transação Atômica: Se algo der errado no meio do caminho, o Firebase cancela tudo.
      await _firestore.runTransaction((transaction) async {
        
        // --- A. Pega os saldos atuais DENTRO da transação pra evitar concorrência ---
        final userRef = _firestore.collection('users').doc(currentUserId);
        final userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists)
          throw Exception("Sua conta de usuário não foi encontrada.");

        final userData = userSnapshot.data()!;
        final double userBrlBalance =
            (userData['saldo'] ?? userData['balance'] ?? 0.0).toDouble();

        // Pegar Tokens da holding
        final investorRef = _firestore
            .collection('startups')
            .doc(startupId)
            .collection('investors')
            .doc(currentUserId);
        final investorSnapshot = await transaction.get(investorRef);

        final ownHoldingRef = _firestore
            .collection('holdings')
            .doc('${currentUserId}_$startupId');
        final ownHoldingSnap = await transaction.get(ownHoldingRef);
        
        // Resolve legado (versões antigas do app) vs modelo novo
        final double legacyTokens = investorSnapshot.exists
            ? ((investorSnapshot.data()!['tokens'] as num?)?.toDouble() ?? 0.0)
            : 0.0;
        double userTokenHolding = ownHoldingSnap.exists
            ? ((ownHoldingSnap.data()?['quantity'] as num?)?.toDouble() ?? 0.0)
            : legacyTokens;

        // --- B. Checa limite REAL antes de brincar ---
        if (type == 'buy') {
          if (userBrlBalance < total) {
            throw Exception("Saldo insuficiente para esta compra.");
          }
        } else {
          if (userTokenHolding < quantity) {
            throw Exception("Insufficient tokens"); // Tem que ser inglês pra bater o erro padrão
          }
        }

        // --- C. Começa o trabalho ---
        final newOfferRef = _firestore.collection('offers').doc();
        double ourRemainingQty = quantity; // Quantos tokens ainda temos pra casar

        // --- D. Loop do Tinder Financeiro (Matching) ---
        for (final candidate in candidates) {
          if (ourRemainingQty <= 0) break; // Já casei tudo, tchau!

          final candSnapshot = await transaction.get(candidate.reference);
          if (!candSnapshot.exists) continue;

          final candData = candSnapshot.data()!;
          if (candData['status'] != 'open') continue; // Alguém já casou essa ordem

          final double candRemaining =
              (candData['remainingQuantity'] ?? candData['quantity'] ?? 0.0)
                  .toDouble();
          if (candRemaining <= 0) continue;

          // Regra sagrada do mercado: "Não comprarás de ti mesmo"
          final String candUserId = candData['userId'] ?? '';
          if (candUserId == currentUserId) continue;

          // Pega o mínimo entre o que eu preciso e o que o cara tem
          final double matchQty = min(ourRemainingQty, candRemaining);
          if (matchQty <= 0) continue;

          // Atualiza a oferta do candidato lá no banco
          final double newCandRemaining = candRemaining - matchQty;
          transaction.update(candidate.reference, {
            'remainingQuantity': newCandRemaining,
            'status': newCandRemaining <= 0 ? 'filled' : 'open',
          });

          // Pega os dados do Candidato pra entregar os R$ e os Tokens
          final candUserRef = _firestore.collection('users').doc(candUserId);
          final candInvestorRef = _firestore
              .collection('startups')
              .doc(startupId)
              .collection('investors')
              .doc(candUserId);
          final candHoldingRef = _firestore
              .collection('holdings')
              .doc('${candUserId}_$startupId');

          final candUserSnapshot = await transaction.get(candUserRef);
          final candInvestorSnapshot = await transaction.get(candInvestorRef);
          final candHoldingSnap = await transaction.get(candHoldingRef);

          final double candBrl = candUserSnapshot.exists
              ? (candUserSnapshot.data()!['saldo'] ??
                        candUserSnapshot.data()!['balance'] ??
                        0.0)
                    .toDouble()
              : 0.0;
          final double legacyCandTokens = candInvestorSnapshot.exists
              ? ((candInvestorSnapshot.data()!['tokens'] as num?)?.toDouble() ??
                    0.0)
              : 0.0;
          final double candHoldingQty = candHoldingSnap.exists
              ? ((candHoldingSnap.data()?['quantity'] as num?)?.toDouble() ??
                    0.0)
              : legacyCandTokens;
          final double candHoldingAvgCents = candHoldingSnap.exists
              ? ((candHoldingSnap.data()?['averagePriceCents'] as num?)
                        ?.toDouble() ??
                    0.0)
              : 0.0;

          // Fluxo do Dinheiro (Escambo)
          if (type == 'buy') {
            // NÓS = COMPRAMOS | CANDIDATO = VENDE
            
            // Dá R$ pro candidato
            final double newCandBrl = candBrl + (matchQty * pricePerToken);
            transaction.update(candUserRef, {
              'saldo': newCandBrl,
              'balance': newCandBrl,
            });

            // Tira token do candidato
            final double newCandHoldingQty = candHoldingQty - matchQty;
            transaction.set(candHoldingRef, {
              'userId': candUserId,
              'startupId': startupId,
              'quantity': newCandHoldingQty <= 0 ? 0 : newCandHoldingQty,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            // Tira token do candidato do legado (se existir)
            if (candInvestorSnapshot.exists) {
              final double remainingLegacy = legacyCandTokens - matchQty;
              if (remainingLegacy <= 0) {
                transaction.delete(candInvestorRef);
              } else {
                transaction.update(candInvestorRef, {
                  'tokens': remainingLegacy,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
              }
            }

            // Nós recebemos os tokens do cara
            userTokenHolding += matchQty;
          } else {
            // NÓS = VENDEMOS | CANDIDATO = COMPRA

            // Dá tokens pro cara no legado
            final double newCandTokens = legacyCandTokens + matchQty;
            transaction.set(candInvestorRef, {
              'userId': candUserId,
              'startupId': startupId,
              'tokens': newCandTokens,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            // Atualiza holdings do cara calculando novo preço médio do ativo dele
            final double newCandHoldingQty = candHoldingQty + matchQty;
            final double newCandAvgCents = newCandHoldingQty > 0
                ? (candHoldingQty * candHoldingAvgCents +
                          matchQty * (pricePerToken * 100)) /
                      newCandHoldingQty
                : 0.0;
            transaction.set(candHoldingRef, {
              'userId': candUserId,
              'startupId': startupId,
              'quantity': newCandHoldingQty,
              'averagePriceCents': newCandAvgCents.round(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }

          // Abate da nossa necessidade
          ourRemainingQty -= matchQty;
        }

        // --- E. Fechamento da Nossa Parte ---
        if (type == 'buy') {
          // Desconta o dinheiro que a gente gastou (tanto as fatias casadas quanto o que vai ficar retido na Ordem Aberta)
          final double nextUserBrl = userBrlBalance - total;
          transaction.update(userRef, {
            'saldo': nextUserBrl,
            'balance': nextUserBrl,
          });

          // Atualiza nossos tokens legados
          transaction.set(investorRef, {
            'userId': currentUserId,
            'startupId': startupId,
            'tokens': userTokenHolding,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          // Atualiza nossa Holding com novo preço médio
          final double prevOwnQty = ownHoldingSnap.exists
              ? ((ownHoldingSnap.data()?['quantity'] as num?)?.toDouble() ??
                    0.0)
              : 0.0;
          final double prevOwnAvgCents = ownHoldingSnap.exists
              ? ((ownHoldingSnap.data()?['averagePriceCents'] as num?)
                        ?.toDouble() ??
                    0.0)
              : 0.0;
          final double addedQty = userTokenHolding - prevOwnQty;
          final double newOwnAvgCents = userTokenHolding > 0
              ? (prevOwnQty * prevOwnAvgCents +
                        (addedQty > 0 ? addedQty : 0) * (pricePerToken * 100)) /
                    userTokenHolding
              : 0.0;
          transaction.set(ownHoldingRef, {
            'userId': currentUserId,
            'startupId': startupId,
            'quantity': userTokenHolding,
            'averagePriceCents': newOwnAvgCents.round(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else {
          // Desconta os tokens que a gente vendeu
          final double nextUserTokensLegacy = legacyTokens - quantity;
          if (investorSnapshot.exists) {
            if (nextUserTokensLegacy <= 0) {
              transaction.delete(investorRef);
            } else {
              transaction.update(investorRef, {
                'tokens': nextUserTokensLegacy,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }

          // Tira da Holding nova
          final double nextOwnHoldingQty = userTokenHolding - quantity;
          transaction.set(ownHoldingRef, {
            'userId': currentUserId,
            'startupId': startupId,
            'quantity': nextOwnHoldingQty <= 0 ? 0 : nextOwnHoldingQty,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          // E recebe a grana se algo foi casado agora
          final double matchedQty = quantity - ourRemainingQty;
          if (matchedQty > 0) {
            final double nextUserBrl =
                userBrlBalance + (matchedQty * pricePerToken);
            transaction.update(userRef, {
              'saldo': nextUserBrl,
              'balance': nextUserBrl,
            });
          }
        }

        // --- F. Finalmente: Salva o Documento da nossa Ordem! ---
        // Se sobrou 'ourRemainingQty', a ordem fica 'open'. Se zerou, fica 'filled'.
        transaction.set(newOfferRef, {
          'userId': currentUserId,
          'startupId': startupId,
          'quantity': quantity,
          'remainingQuantity': ourRemainingQty,
          'pricePerToken': pricePerToken,
          'pricePerTokenCents': (pricePerToken * 100).round(),
          'total': total,
          'totalCents': (total * 100).round(),
          'type': type,
          'status': ourRemainingQty <= 0 ? 'filled' : 'open',
          'createdAt': FieldValue.serverTimestamp(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      // Sucesso! Fecha a gaveta
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Deu pau: erro pra tela e tira o loader
      final String message = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _errorMessage = message;
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFE74C3C),
            content: Text(message),
          ),
        );
      }
    }
  }
}
