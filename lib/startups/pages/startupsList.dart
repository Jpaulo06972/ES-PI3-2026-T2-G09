// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote básico de UI do Flutter para construção de layouts e componentes
import 'package:flutter/material.dart';

// Importa o cabeçalho personalizado que contém informações do perfil e notificações
import 'package:mesclainvest_f/components/appBar.dart';
// Importa a barra de navegação inferior que permite transitar entre as áreas do app
import 'package:mesclainvest_f/components/navBar.dart';
// Importa o modelo de dados do usuário para gerenciar autenticação e permissões
import 'package:mesclainvest_f/model/userModel.dart';
// Importa o widget de card customizado para exibir cada startup de forma elegante
import 'package:mesclainvest_f/startups/components/cardStartups.dart';
// Importa a tela de detalhes para onde o usuário será levado ao clicar em uma startup
import 'package:mesclainvest_f/startups/pages/startupsDetails.dart';
// Importa o serviço responsável pela comunicação com o Firebase (Firestore/Functions)
import 'package:mesclainvest_f/startups/services/getStartup.dart';

/// Página que exibe o catálogo de startups disponíveis para investimento.
/// Aqui o usuário pode navegar, filtrar por estágio de maturidade e buscar por nomes específicos.
class StartupsList extends StatefulWidget {
  // Modelo do usuário logado, necessário para manter o contexto de navegação e rodapé
  final UserModel userModel;

  // Construtor que recebe obrigatoriamente os dados do usuário autenticado
  const StartupsList({super.key, required this.userModel});

  // Inicializa o estado mutável desta página
  @override
  State<StartupsList> createState() => _StartupsListState();
}

/// Gerencia toda a lógica de estado, busca e filtragem da lista de startups.
class _StartupsListState extends State<StartupsList> {
  // Instância do serviço para buscar dados dinâmicos do backend mescla-invest
  final StartupService _startupService = StartupService();

  // Controlador de texto para o campo de pesquisa, permitindo ler o que o usuário digita
  final TextEditingController _searchController = TextEditingController();

  // Objeto Future que representa a lista de startups que será carregada de forma assíncrona
  late Future<List<Map<String, dynamic>>> _startupsFuture;

  // Variável que armazena o termo de busca atual limpo (sem espaços extras e minúsculo)
  String _searchQuery = '';

  // Armazena qual estágio de startup foi selecionado no filtro (null significa "Exibir todas")
  String? _selectedStage;

  // Variável booleana para controlar se o painel de filtros está expandido ou recolhido
  bool _showFilters = false;

  // Mapa que define as opções de filtro: chave é o valor técnico, valor é o texto amigável
  static const Map<String?, String> _stageOptions = {
    null: 'Todas',
    'nova': 'Nova',
    'em_operacao': 'Em Operação',
    'em_expansao': 'Em Expansão',
  };

  // Método executado assim que a tela é carregada pela primeira vez
  @override
  void initState() {
    super.initState();
    // Dispara a busca inicial das startups no servidor
    _startupsFuture = _startupService.listStartups();

    // Registra um ouvinte para atualizar a lista sempre que o usuário digitar algo na busca
    _searchController.addListener(_onSearchChanged);
  }

  // Método executado quando o widget é removido da árvore (limpeza de recursos)
  @override
  void dispose() {
    // Remove o ouvinte e descarta o controlador para evitar vazamentos de memória (leaks)
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Função interna que sincroniza o texto da busca com o estado da aplicação
  void _onSearchChanged() {
    setState(() {
      // Normaliza o texto para facilitar a comparação (minúsculo e sem espaços nas pontas)
      _searchQuery = _searchController.text.toLowerCase().trim();
    });
  }

  // Lógica principal de filtragem: recebe a lista bruta e devolve apenas o que combina com os filtros
  List<Map<String, dynamic>> _filterStartups(List<Map<String, dynamic>> all) {
    return all.where((startup) {
      // Se houver um estágio selecionado, remove qualquer startup que não pertença a esse estágio
      if (_selectedStage != null) {
        final stage = (startup['stage'] ?? '').toString();
        if (stage != _selectedStage) return false;
      }

      // Se houver texto na busca, verifica se o nome ou descrição da startup contém esse termo
      if (_searchQuery.isNotEmpty) {
        final name = (startup['name'] ?? '').toString().toLowerCase();
        final desc =
            (startup['shortDescription'] ?? '').toString().toLowerCase();
        // Também permite buscar pelo nome formatado do estágio
        final stage = (startup['stage'] ?? '')
            .toString()
            .replaceAll('_', ' ')
            .toLowerCase();
            
        // Se o termo não estiver em nenhum desses campos, a startup é ocultada
        if (!name.contains(_searchQuery) &&
            !desc.contains(_searchQuery) &&
            !stage.contains(_searchQuery)) {
          return false;
        }
      }

      // Se passou por todos os testes, a startup deve ser exibida
      return true;
    }).toList();
  }

  // Constrói a árvore de widgets da página
  @override
  Widget build(BuildContext context) {
    // Scaffold fornece a estrutura básica (header, body, navbar)
    return Scaffold(
      // Header com logo e perfil do usuário
      appBar: CustomHeader(userModel: widget.userModel),
      // Barra inferior com o ícone de catálogo destacado (index 1)
      bottomNavigationBar: CustomNavBar(
        userModel: widget.userModel,
        currentIndex: 1,
      ),
      // FutureBuilder lida automaticamente com os estados de carregamento (loading, erro, pronto)
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _startupsFuture,
        builder: (context, snapshot) {
          // Se ainda está carregando, exibe um spinner centralizado na cor verde do app
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A9B5F)),
            );
          }

          // Se houve falha na comunicação, exibe uma mensagem de erro estilizada
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Erro ao carregar startups:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          // Pega a lista de dados ou uma lista vazia se não houver nada
          final allStartups = snapshot.data ?? [];

          // Aplica os filtros de busca e categoria antes de renderizar
          final startups = _filterStartups(allStartups);

          // Usa ListView para permitir scroll suave do conteúdo
          return ListView(
            // Adiciona um efeito de "elástico" no scroll (típico de iOS)
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // Título principal e subtítulo da página
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Oportunidades Exclusivas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Invista no futuro com as startups mais promissoras do mercado.',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Barra de Pesquisa com campo de texto e botão de filtros
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    // Sombra sutil para dar profundidade ao campo de busca
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Buscar pelo nome ou setor...',
                    hintStyle: const TextStyle(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                    // Ícone de lupa fixo à esquerda
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 12, right: 8),
                      child: Icon(
                        Icons.search,
                        color: Colors.white54,
                        size: 22,
                      ),
                    ),
                    // Conjunto de botões à direita (Limpar e Abrir Filtros)
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Se o usuário digitou algo, mostra o ícone "X" para apagar tudo rapidamente
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white38,
                                size: 20,
                              ),
                            ),
                          ),
                        // Botão que expande/recolhe o painel de seleção de estágios
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showFilters = !_showFilters;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              // Muda de cor se o painel estiver aberto ou se houver um filtro ativo
                              color: _showFilters || _selectedStage != null
                                  ? const Color(0xFF1A9B5F)
                                  : const Color(0xFF3A3A3D),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              color: _showFilters || _selectedStage != null
                                  ? Colors.white
                                  : Colors.white70,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    filled: true,
                    fillColor: const Color(0xFF262629),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),

              // Painel de filtros de estágio com animação de fade suave
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: _showFilters
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    // Mapeia cada opção de estágio para um "chip" interativo
                    children: _stageOptions.entries.map((entry) {
                      final stageKey = entry.key;
                      final label = entry.value;
                      final isSelected = _selectedStage == stageKey;

                      // Lógica de cores temáticas para cada tipo de estágio
                      Color chipColor;
                      if (stageKey == null) {
                        chipColor = const Color(0xFF4A90E2); // Azul para "Todas"
                      } else if (stageKey == 'nova') {
                        chipColor = const Color(0xFF1A9B5F); // Verde para novas
                      } else if (stageKey == 'em_operacao') {
                        chipColor = const Color(0xFF4A90E2); // Azul para operação
                      } else {
                        chipColor = const Color(0xFFF5A623); // Laranja para expansão
                      }

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            // Ao clicar, define esse estágio como o filtro ativo
                            _selectedStage = stageKey;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            // Se selecionado, ganha um brilho sutil da cor do tema
                            color: isSelected
                                ? chipColor.withOpacity(0.2)
                                : const Color(0xFF2C2C30),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? chipColor
                                  : Colors.white.withOpacity(0.08),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Pequeno indicador circular que aparece quando selecionado
                              if (isSelected) ...[
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: chipColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                label,
                                style: TextStyle(
                                  color: isSelected
                                      ? chipColor
                                      : Colors.white60,
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Se escondido, não ocupa espaço nenhum
                secondChild: const SizedBox.shrink(),
              ),

              const SizedBox(height: 32),

              // Seção de cabeçalho da lista com contador de resultados encontrados
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Em destaque',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Badge verde indicando o número de startups filtradas no momento
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF1A9B5F).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${startups.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Botão de ação rápida para limpar todos os filtros aplicados
                  if (_selectedStage != null || _searchQuery.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedStage = null;
                          _searchController.clear();
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Limpar filtros',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    // Se não houver filtros, mostra uma opção genérica de navegação
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Ver todas',
                        style: TextStyle(
                          color: Color(0xFF1A9B5F),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Tratamento de lista vazia (Empty State)
              if (startups.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        // Ícone triste indicando que a busca não retornou nada
                        const Icon(
                          Icons.search_off_rounded,
                          color: Colors.white24,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _selectedStage != null
                              ? 'Nenhuma startup encontrada com os filtros atuais.'
                              : 'Nenhuma startup encontrada.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 16),
                        ),
                        // Oferece o botão de limpar filtros como saída para o usuário
                        if (_searchQuery.isNotEmpty ||
                            _selectedStage != null) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedStage = null;
                                _searchController.clear();
                              });
                            },
                            child: const Text(
                              'Limpar filtros',
                              style: TextStyle(
                                color: Color(0xFF1A9B5F),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                // Mapeamento dos dados para os widgets de Card
                ...startups.map((startup) {
                  // Extração segura dos dados com valores padrão para evitar quebras de UI
                  final nome = startup['name'] ?? 'Sem Nome';
                  final desc = startup['shortDescription'] ?? '';
                  final status = startup['stage'] ?? 'Desconhecido';

                  // Cálculos matemáticos simples para converter dados brutos do banco (cents) para Real
                  final tokensInt = startup['totalTokensIssued'] ?? 0;
                  final valorCents = startup['capitalRaisedCents'] ?? 0;
                  final valorReal = valorCents / 100;

                  // Calcula o progresso dinâmico baseado em tokens vendidos e emitidos
                  final totalTokensVal = (startup['totalTokensIssued'] as num?)?.toDouble() ?? 0.0;
                  final soldTokensVal = (startup['tokensSold'] as num?)?.toDouble() ?? 0.0;
                  final progressVal = totalTokensVal > 0 
                      ? (soldTokensVal / totalTokensVal).clamp(0.0, 1.0) 
                      : 0.0;

                  // Lógica para encontrar a imagem no Firebase Storage seguindo o padrão de nomes
                  // Ex: "AgriSense" -> "startups_images/agrisense.png"
                  final storageName = nome.toLowerCase().replaceAll(' ', '-');
                  final storagePath = 'startups_images/$storageName.png';

                  // Recupera o identificador único do documento no Firestore
                  final startupId =
                      (startup['id'] ?? startup['uid'] ?? '').toString();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      // Só permite o clique se houver um ID válido para navegar
                      onTap: startupId.isEmpty
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  // Abre a tela de detalhes passando todo o contexto necessário
                                  builder: (_) => StartupsDetails(
                                    startupId: startupId,
                                    startupName: nome,
                                    startupStage: status,
                                    userModel: widget.userModel,
                                    storagePath: storagePath,
                                  ),
                                ),
                              ),
                      // Renderiza o card visual da startup com todos os dados tratados
                      child: startupCard(
                        nome: nome,
                        descricao: desc,
                        // Formata o status para ficar amigável (em_operacao -> EM OPERACAO)
                        status: status.replaceAll('_', ' ').toUpperCase(),
                        tokens: tokensInt.toString(),
                        valor: 'R\$ ${valorReal.toStringAsFixed(0)}',
                        progress: progressVal,
                        icon: Icons.rocket_launch_rounded,
                        imageUrl: null, // Deixamos nulo pois buscamos via storagePath dentro do componente
                        storagePath: storagePath,
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 30), // Padding inferior para não colar na barra de navegação
            ],
          );
        },
      ),
    );
  }
}
