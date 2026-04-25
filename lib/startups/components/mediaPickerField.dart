// 'dart:io' é necessário para trabalhar com o objeto 'File', que representa o arquivo físico da imagem ou vídeo no celular
import 'dart:io';

// Importa os componentes visuais básicos do Flutter
import 'package:flutter/material.dart';

// Importa o pacote oficial 'image_picker' para acessar a câmera e a galeria do dispositivo
import 'package:image_picker/image_picker.dart';

// Componente visual personalizado para selecionar uma imagem ou um vídeo
// Ele precisa ser um StatefulWidget pois guarda o estado interno da mídia selecionada
// (ou seja, a tela precisa se redesenhar quando o usuário escolhe uma foto)
class MediaPickerField extends StatefulWidget {
  // Texto que vai aparecer instruindo o usuário (ex: "Adicionar Logo/Capa")
  final String label;
  
  // Flag (verdadeiro ou falso) que define se esse botão é para pegar um Vídeo (true) ou Imagem (false)
  final bool isVideo;
  
  // Função que será chamada passando o arquivo final (File) para a tela principal (StartupsCreate)
  final void Function(File) onMediaSelected;

  // Construtor: label e onMediaSelected são obrigatórios. isVideo é falso por padrão.
  const MediaPickerField({
    super.key,
    required this.label,
    required this.onMediaSelected,
    this.isVideo = false,
  });

  @override
  State<MediaPickerField> createState() => _MediaPickerFieldState();
}

class _MediaPickerFieldState extends State<MediaPickerField> {
  // Variável que vai guardar o arquivo selecionado. Começa como 'null' (vazio).
  File? _selectedMedia;
  
  // Instância do ImagePicker, que é a ferramenta do pacote que faz o "trabalho sujo" de abrir a galeria/câmera
  final ImagePicker _picker = ImagePicker();

  // Função assíncrona (espera a ação do usuário) que de fato abre a câmera ou galeria
  Future<void> _pickMedia(ImageSource source) async {
    // XFile é um formato temporário que o ImagePicker usa para lidar com o arquivo
    XFile? pickedFile;
    
    // Verifica se o componente foi configurado para pegar vídeo ou imagem
    if (widget.isVideo) {
      // Abre a interface nativa do celular para gravar ou escolher um vídeo
      pickedFile = await _picker.pickVideo(source: source);
    } else {
      // Abre a interface nativa do celular para tirar foto ou escolher da galeria
      pickedFile = await _picker.pickImage(source: source);
    }

    // Se o usuário realmente escolheu algo (não cancelou a ação)
    if (pickedFile != null) {
      // setState avisa o Flutter: "Ei, os dados mudaram! Redesenhe a tela para mostrar que o arquivo foi pego!"
      setState(() {
        // Converte o XFile temporário em um File definitivo e guarda no estado
        _selectedMedia = File(pickedFile!.path);
      });
      // Manda o arquivo para a função do pai (para que a tela de cadastro saiba qual foto salvar no futuro)
      widget.onMediaSelected(_selectedMedia!);
    }
  }

  // Função que exibe um "Bottom Sheet" (aquela gavetinha que sobe de baixo da tela)
  // perguntando se o usuário quer usar a Câmera ou a Galeria
  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        // SafeArea garante que a gaveta não fique em cima dos botões de navegação do Android ou do notch do iPhone
        return SafeArea(
          child: Wrap( // Wrap faz com que o menu se adapte ao conteúdo dentro dele
            children: <Widget>[
              // Opção 1: Galeria de Fotos
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeria'),
                onTap: () {
                  // Chama a função de pegar mídia passando a 'galeria' como origem
                  _pickMedia(ImageSource.gallery);
                  // Fecha a gavetinha
                  Navigator.of(context).pop();
                },
              ),
              // Opção 2: Câmera do Celular
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Câmera'),
                onTap: () {
                  // Chama a função de pegar mídia passando a 'câmera' como origem
                  _pickMedia(ImageSource.camera);
                  // Fecha a gavetinha
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // InkWell cria um botão clicável com um efeitinho de onda (splash) quando toca
    return InkWell(
      onTap: _showPickerOptions, // Quando clicar no campo todo, abre a gaveta de opções
      child: Container(
        // Espaçamento interno da caixa
        padding: const EdgeInsets.all(12),
        // Estilo da caixa (borda cinza e cantinhos arredondados, parecido com o TextFormField)
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            // Ícone do lado esquerdo que muda dependendo se é campo de vídeo ou de foto
            Icon(
              widget.isVideo ? Icons.videocam_outlined : Icons.image_outlined,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            // Expanded faz o texto ocupar o resto do espaço disponível no meio
            Expanded(
              // Lógica condicional: verifica se JÁ TEMOS um arquivo selecionado
              child: _selectedMedia != null
                  // SE TEM MÍDIA: Mostra que deu certo sem asterisco vermelho (Texto simples)
                  ? Text(
                      '${widget.isVideo ? 'Vídeo' : 'Imagem'} selecionado(a)',
                      style: TextStyle(
                        color: Colors.grey.shade400, // Fica mais apagadinho pra mostrar que já foi feito
                        fontSize: 16,
                      ),
                    )
                  // SE NÃO TEM MÍDIA: Mostra o texto original com o asterisco de obrigatório
                  : Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: widget.label),
                          const TextSpan(
                            text: ' *',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
            ),
            // Se o usuário já escolheu a mídia, aparece um "Check" verde de sucesso no finalzinho da linha!
            if (_selectedMedia != null)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }
}
