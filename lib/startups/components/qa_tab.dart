// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/enum/userRole.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/startups/services/getStartup.dart';
import 'startup_colors.dart';

/// [QATab] é o widget com estado (Stateful) que gerencia a aba de Perguntas e Respostas (Q&A).
/// 
/// Por que ele existe?
/// Investidores quase nunca compram tokens de uma startup no escuro. Eles querem tirar
/// dúvidas sobre balanço, cap table, roadmap etc. O Q&A é a ponte de confiança.
/// 
/// Regra de Negócio Crítica (Role Check):
/// Perguntas públicas qualquer um pode fazer. Mas perguntas PRIVADAS (que só o fundador vê)
/// são restritas apenas para quem tem a flag de 'Investidor'. Isso evita spam na caixa de
/// entrada do CEO da startup.
class QATab extends StatefulWidget {
  final String startupId;
  final StartupService service;
  final UserModel userModel;

  const QATab({
    super.key,
    required this.startupId,
    required this.service,
    required this.userModel,
  });

  @override
  State<QATab> createState() => _QATabState();
}

class _QATabState extends State<QATab> {
  // Esse Future guarda a promessa de que a lista de comentários vai chegar do Firestore.
  // Usamos 'late' porque só vamos inicializá-lo no initState.
  late Future<List<Map<String, dynamic>>> _commentsFuture;
  
  // O controlador é como se fosse o caderno onde as teclas são anotadas.
  // Ele guarda o texto que o usuário digita na caixinha lá embaixo.
  final TextEditingController _controller = TextEditingController();
  
  // Guardião do estado de privacidade da pergunta atual.
  bool _isPrivate = false;
  
  // Flag defensiva (debounce/spinner): impede o usuário de apertar o botão
  // "Enviar" 50 vezes seguidas enquanto a internet está lenta.
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Cache do Future. A gente faz a requisição aqui no initState e não no build(),
    // para evitar que o Flutter refaça o download do banco de dados toda vez que a tela piscar.
    _commentsFuture = widget.service.listComments(widget.startupId);
  }

  @override
  void dispose() {
    // Nunca esqueça de jogar os controladores fora. Se não fizer isso, eles
    // ficam ocupando espaço na RAM à toa (famoso memory leak).
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FutureBuilder é fantástico: ele "ouve" a viagem dos dados do servidor
    // até o celular e redesenha a tela de acordo com o estado do voo (esperando, chegou, erro).
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _commentsFuture,
      builder: (context, snapshot) {
        
        // Estado 1: O avião ainda não pousou. Mostra a bolinha girando.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: StartupColors.green));
        }
        
        // Estado 2: O avião caiu (Erro). Mostra o que deu errado.
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Erro ao carregar:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
            ),
          );
        }

        // Se chegou até aqui, temos dados ou pelo menos uma lista vazia.
        final comments = snapshot.data ?? [];

        return Column(
          children: [
            // Expanded empurra o campo de texto lá pro fundo e ocupa o resto.
            Expanded(
              child: comments.isEmpty
                  // Estado 3A: Lista vazia. Em vez de uma tela em branco feia,
                  // colocamos um "Call to Action" incentivando o usuário.
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, color: Colors.white12, size: 48),
                          SizedBox(height: 12),
                          Text(
                            'Nenhuma pergunta ainda.\nSeja o primeiro a perguntar!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white38, fontSize: 14, height: 1.5),
                          ),
                        ],
                      ),
                    )
                  // Estado 3B: Temos comentários! Vamos listá-los.
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(), // Aquele efeitinho elástico do iOS
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      itemCount: comments.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _QuestionCard(comment: comments[i]),
                      ),
                    ),
            ),
            
            // O componente customizado que cuida só do input lá embaixo.
            _QuestionInput(
              controller: _controller,
              isPrivate: _isPrivate,
              isSending: _isSending,
              onTogglePrivate: () {
                // REGRA DE SEGURANÇA NA TELA:
                // Se ele está tentando ativar o modo privado e NÃO é investidor, toma um bloqueio.
                if (!_isPrivate && widget.userModel.role != UserRole.investidor) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Somente investidores podem enviar mensagens privadas'),
                    ),
                  );
                  return; // Aborta a missão
                }
                
                // Se for investidor, inverte o estado (de público pra privado e vice versa)
                // O setState vai redesenhar só as partes que dependem do _isPrivate.
                setState(() => _isPrivate = !_isPrivate);
              },
              onSend: _handleSend, // Passa a função pesada pro botão
            ),
          ],
        );
      },
    );
  }

  // Função assíncrona (vai demorar um pouquinho) que cuida do envio real pro servidor.
  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    // Proteção: não deixa enviar texto vazio nem mandar 2x ao mesmo tempo.
    if (text.isEmpty || _isSending) return;
    
    // Avisa a tela que começou a enviar pra rodar o spinner
    setState(() => _isSending = true);
    
    try {
      // "await" significa: "pode pausar a execução dessa função e ir fazer outras coisas,
      // me avisa quando o Firebase responder."
      await widget.service.createComment(
        widget.startupId,
        text,
        _isPrivate ? 'privada' : 'publica', // Salva a flag no banco
      );
      
      _controller.clear(); // Limpa o text input
      
      setState(() {
        // Truque de UX: Atualiza o Future inteiro pra forçar a tela a baixar os novos dados
        // e o usuário já ver a própria pergunta ali na lista.
        _commentsFuture = widget.service.listComments(widget.startupId);
      });
    } catch (e) {
      // Se a tela já foi fechada enquanto o request rolava, ignora o erro (mounted previne crashes).
      if (mounted) {
        final raw = e.toString();
        final String msg;
        
        // Tratamento elegante do backend. Se o Firebase Cloud Functions rejeitar
        // o payload porque o cara hackeou a UI, nós tratamos aqui.
        if (raw.contains('permission-denied') || raw.contains('investidor')) {
          msg = 'Somente investidores desta startup podem enviar mensagens privadas';
          setState(() => _isPrivate = false);
        } else {
          msg = 'Não foi possível enviar a mensagem. Tente novamente.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      // Independente de dar bom ou ruim, tira o spinner.
      if (mounted) setState(() => _isSending = false);
    }
  }
}

/// [_QuestionCard] é o widget "burro" (Stateless) que só pega dados e pinta na tela.
/// 
/// Segurança: Ele implementa ofuscação de e-mail pra estarmos de boa com a LGPD
/// e evitar scraping dos contatos dos nossos investidores.
class _QuestionCard extends StatelessWidget {
  final Map<String, dynamic> comment;

  const _QuestionCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    // Extraindo dados com cast seguro. Se vier nulo, cai pro padrão.
    final text = (comment['text'] as String?) ?? '';
    final isPrivate = (comment['visibility'] as String?) == 'privada';
    final authorEmail = (comment['authorEmail'] as String?) ?? '';

    String maskedEmail = 'Usuário';
    
    // Ofuscação marota de e-mail.
    // 'joao.silva@teste.com' vira 'j***@teste.com'.
    if (authorEmail.contains('@')) {
      final parts = authorEmail.split('@');
      maskedEmail = '${parts[0][0]}***@${parts[1]}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StartupColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        
        // Feedback visual: Se for privada, a borda fica verdinha pra avisar o usuário:
        // "Relaxa, tá seguro". Se for pública, fica quase transparente.
        border: Border.all(
          color: isPrivate
              ? StartupColors.green.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Alinha à esquerda
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Empurra um pro canto e outro pro outro
            children: [
              Text(
                maskedEmail,
                style: const TextStyle(color: StartupColors.green, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              // Mostra a tagzinha "PRIVADA" só se for privada.
              if (isPrivate)
                const Text('PRIVADA', style: TextStyle(color: Colors.white30, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8), // Espaçamento entre o autor e o texto
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}

/// [_QuestionInput] é o rodapé onde a mágica da digitação acontece.
class _QuestionInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isPrivate;
  final bool isSending;
  final VoidCallback onTogglePrivate;
  final VoidCallback onSend;

  const _QuestionInput({
    required this.controller,
    required this.isPrivate,
    required this.isSending,
    required this.onTogglePrivate,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StartupColors.cardBg,
        // Uma sombra invertida (offset Y negativo) para destacar o input do resto da lista
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Botão que vira a chave de Público/Privado
              GestureDetector(
                onTap: onTogglePrivate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    // Fica aceso (verde fraco) se tiver ativado
                    color: isPrivate ? StartupColors.green.withValues(alpha: 0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isPrivate ? StartupColors.green : Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPrivate ? Icons.lock_rounded : Icons.public_rounded, // Cadeado ou mundão
                        size: 14,
                        color: isPrivate ? StartupColors.green : Colors.white30,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPrivate ? 'Privada' : 'Pública',
                        style: TextStyle(
                          color: isPrivate ? StartupColors.green : Colors.white30,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(), // Ocupa o resto do espaço para empurrar o botão pra esquerda
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // O Expanded aqui diz pro TextField: "Cresça o máximo que der até bater no botão de enviar"
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: null, // Deixa a caixa crescer de acordo com as quebras de linha (tipo Zap)
                  textInputAction: TextInputAction.newline, // Enter no teclado virtual quebra a linha
                  decoration: InputDecoration(
                    // O placeholder (dica) também muda dinamicamente
                    hintText: isPrivate
                        ? 'Envie uma pergunta privada para a startup...'
                        : 'Faça uma pergunta pública...',
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                    filled: true, // Pinta o fundo do input
                    fillColor: StartupColors.pageBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none, // Sem contorno extra
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              
              // Botão gigante e bonitão de Enviar
              GestureDetector(
                onTap: isSending ? null : onSend, // Se já tá enviando, trava o clique
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    // Quando tá enviando, o botão fica "desbotado" (alpha 0.5)
                    color: isSending
                        ? StartupColors.green.withValues(alpha: 0.5)
                        : StartupColors.green,
                    borderRadius: BorderRadius.circular(14),
                    // Sombreado glow (brilhante) pra chamar o clique
                    boxShadow: [
                      BoxShadow(
                        color: StartupColors.green.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: isSending
                      // Mostra a bolinha se tiver ocupado, senão mostra o aviãozinho do Telegram
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
