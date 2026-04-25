// Importa os widgets essenciais do Flutter para construção da interface gráfica
import 'package:flutter/material.dart';

// Importa o pacote que formata números como moeda (colocando pontos e vírgulas automaticamente)
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';

// Componente visual personalizado para receber números, como valores financeiros ou quantidades
// Utilizado na tela StartupsCreate para os campos "Capital Aportado" e "Tokens Emitidos"
class NumberField extends StatelessWidget {
  // O 'controller' é o "caderninho" que anota e guarda tudo o que o usuário digita no campo
  final TextEditingController controller;
  
  // O 'label' é o título ou etiqueta que explica o que deve ser preenchido (ex: "Capital (R$)")
  final String label;

  // Construtor do nosso campo numérico: ele sempre vai exigir que passemos o controller e o label
  const NumberField({
    super.key,
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    // Retorna um TextFormField, que é o campo de texto padrão do Flutter já com suporte
    // a validação de formulários (Form)
    return TextFormField(
      // Vincula o campo ao controlador, assim conseguimos ler o número depois quando formos salvar
      controller: controller,
      
      // Muda o teclado do celular para mostrar apenas números e símbolos matemáticos
      // O 'decimal: true' garante que o teclado mostre vírgula/ponto para números quebrados
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      
      // Essa é a mágica do formato brasileiro! O inputFormatters altera o texto ENQUANTO
      // o usuário digita.
      inputFormatters: [
        CurrencyTextInputFormatter.currency(
          // Define a linguagem/região como Brasil, ativando o uso de "." para milhar e "," para centavos
          locale: 'pt_BR', 
          
          // Deixamos o símbolo vazio ('') porque não queremos um "R$" colado no número, 
          // já que o próprio título do campo já indica a moeda, e o campo de Tokens não usa R$.
          symbol: '', 
          
          // Obriga o número a ter duas casas decimais, ou seja, "1000" vira "1.000,00"
          decimalDigits: 2, 
        ),
      ],
      
      // Configuração visual do campo (bordas, textos, ícones)
      decoration: InputDecoration(
        // Usamos Text.rich para poder juntar o nome do campo com um asterisco vermelho de obrigatoriedade
        label: Text.rich(
          TextSpan(
            children: [
              // Coloca o texto principal (ex: "Capital (R$)")
              TextSpan(text: label),
              // Adiciona o asterisco em vermelho logo em seguida
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        
        // Ícone de cifrão ($) no lado esquerdo do campo para indicar que é um valor
        prefixIcon: const Icon(Icons.attach_money_outlined),
        
        // Controla o tamanho do ícone para ele não ocupar muito espaço e ficar alinhado 
        // perfeitamente com os ícones de pessoa/maleta dos outros campos do formulário
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        
        // Coloca aquela borda contínua retangular ao redor do campo todo
        border: const OutlineInputBorder(),
        
        // isDense = true faz o campo perder um pouco de "gordura" vertical, ficando mais slim
        isDense: true,
        
        // Padding (espaçamento interno) entre o texto e as bordas. Esse valor (0, 14, 12, 14)
        // é o padrão mágico que usamos em todos os campos para a altura deles ficar idêntica na tela!
        contentPadding: const EdgeInsets.fromLTRB(0, 14, 12, 14),
        
        // Estilo da mensagem de erro (caso exista): letra tamanho 11, bem compacta
        errorStyle: const TextStyle(fontSize: 11, height: 0.8),
      ),
      
      // Função que verifica se o preenchimento do campo está correto na hora de salvar
      validator: (value) {
        // Se o valor estiver nulo ou vazio (usuário não digitou nada)
        if (value == null || value.isEmpty) {
          // Devolve a mensagem "Obrigatório" que vai aparecer em vermelhinho sob o campo
          return 'Obrigatório';
        }
        // OBS: Antigamente checávamos se era um número válido com 'double.tryParse'. 
        // Agora não precisamos mais! O 'CurrencyTextInputFormatter' já bloqueia a digitação 
        // de letras e formata o número perfeitamente, então não tem como o usuário errar.
        return null;
      },
    );
  }
}
