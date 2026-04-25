// Importa os widgets essenciais do Flutter para construção da interface gráfica
import 'package:flutter/material.dart';

// Importa o Enum que define os possíveis estágios de uma Startup (Nova, Em Operação, Em Expansão)
import 'package:mesclainvest_f/enum/stageStartup.dart';

// Componente visual reutilizável para exibir um campo de seleção (Dropdown)
// É um StatelessWidget porque ele não gerencia seu próprio estado; o valor selecionado
// é passado de fora (pelo pai) e ele só avisa o pai quando algo muda via 'onChanged'.
class DropdownField extends StatelessWidget {
  // Valor atualmente selecionado na lista (pode ser nulo caso o usuário ainda não tenha escolhido)
  final StageStartup? value;
  
  // O texto que vai aparecer em cima do campo, indicando o que deve ser selecionado (ex: "Estágio")
  final String label;
  
  // Função que será chamada (disparada) sempre que o usuário selecionar uma nova opção
  // Essa função envia o novo estágio escolhido de volta para a tela principal atualizar seu estado
  final void Function(StageStartup?)? onChanged;

  // Construtor do widget: exige que quem for usar este campo informe o valor atual,
  // o texto da etiqueta (label) e a função que vai lidar com a mudança (onChanged).
  const DropdownField({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  // Método build que constrói de fato a interface do campo na tela
  @override
  Widget build(BuildContext context) {
    // DropdownButtonFormField é a versão de Dropdown que já se integra perfeitamente
    // com o widget 'Form', permitindo fazer validações (como tornar o campo obrigatório)
    return DropdownButtonFormField<StageStartup>(
      // Define qual é o valor que deve aparecer selecionado no momento
      value: value,
      
      // Conecta a ação de selecionar um novo item com a função que passamos lá de fora
      onChanged: onChanged,
      
      // Garante que o texto da opção selecionada vai ocupar todo o espaço disponível
      // sem empurrar o ícone da setinha (dropdown) para fora da tela
      isExpanded: true, 
      
      // Define um tamanho fixo e padrão para o ícone da setinha que abre as opções
      iconSize: 24, 
      
      // Configuração de estilo visual do campo (bordas, ícones, textos)
      decoration: InputDecoration(
        // Utilizamos Text.rich para poder formatar partes diferentes do texto
        label: Text.rich(
          TextSpan(
            children: [
              // Coloca o texto normal que veio no parâmetro (ex: "Estágio")
              TextSpan(text: label),
              
              // Adiciona um asterisco vermelho logo na frente para indicar visualmente
              // ao usuário que este campo é de preenchimento obrigatório
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        
        // Coloca um ícone de maleta (business center) do lado esquerdo do campo
        // para dar uma identidade visual e deixar a interface mais bonita
        prefixIcon: const Icon(Icons.business_center_outlined),
        
        // Limita o tamanho desse ícone para que ele fique alinhado perfeitamente
        // com o ícone de pessoa ou dinheiro dos outros campos
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        
        // Define que a borda do campo será retangular e contínua em toda a volta
        border: const OutlineInputBorder(),
        
        // isDense faz com que o campo fique um pouco mais compacto verticalmente
        isDense: true,
        
        // Ajusta os espaçamentos internos (padding) entre o texto e a borda do campo.
        // Foi deixado exatamente igual aos outros campos para não ter diferença de altura!
        contentPadding: const EdgeInsets.fromLTRB(0, 14, 12, 14),
        
        // Se der algum erro (ex: tentou salvar sem preencher), o texto de erro
        // ficará com esse estilo: letrinha pequena e bem próxima da caixa
        errorStyle: const TextStyle(fontSize: 11, height: 0.8),
      ),
      
      // Lista de opções (itens) que vão aparecer quando o usuário clicar no campo
      items: const [
        // Primeira opção: Startup Nova (Fase de ideia ou inicial)
        DropdownMenuItem(
          value: StageStartup.nova,
          child: Text('Nova'),
        ),
        
        // Segunda opção: Startup já operando no mercado e faturando
        DropdownMenuItem(
          value: StageStartup.em_operacao,
          child: Text('Em Operação'),
        ),
        
        // Terceira opção: Startup consolidada buscando escalar (Expandir)
        DropdownMenuItem(
          value: StageStartup.em_expansao,
          child: Text('Em Expansão'),
        ),
      ],
      
      // Função responsável por validar se o usuário preencheu o campo corretamente
      // quando ele clica no botão de "Salvar" lá na tela principal
      validator: (val) {
        // Se o valor estiver nulo (ou seja, o cara não escolheu nada na lista)
        if (val == null) {
          // Retorna a mensagem de erro que vai ficar vermelhinha debaixo do campo
          return 'Obrigatório';
        }
        // Se passou da verificação (escolheu algo), retorna null, o que significa que "tá tudo certo"
        return null;
      },
    );
  }
}
