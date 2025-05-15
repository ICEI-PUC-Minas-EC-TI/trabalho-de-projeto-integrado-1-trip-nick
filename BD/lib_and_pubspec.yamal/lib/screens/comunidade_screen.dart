import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sql_helper.dart';
import 'dart:async';

final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  runApp(const ComunidadeScreen());
}

class ComunidadeScreen extends StatelessWidget {
  const ComunidadeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Comunidade',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const TelaInicial(),
    );
  }
}

class TelaInicial extends StatefulWidget {
  const TelaInicial({Key? key}) : super(key: key);

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  List<Map<String, dynamic>> _posts = [];
  bool _carregando = true;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _atualizaPosts();
  }

  void _atualizaPosts() async {
    final data = await SQLHelper.pegarPostsCommunity();
    setState(() {
      _posts = data;
      _carregando = false;
    });
  }

  void _mostraEdicao(int? idPost) async {
    if (idPost != null) {
      final postExistente = _posts.firstWhere((element) => element['idPost'] == idPost);
      _titleController.text = postExistente['title'] ?? '';
      _descriptionController.text = postExistente['description'] ?? '';
      _imageController.text = postExistente['image'] ?? '';
    } else {
      _titleController.clear();
      _descriptionController.clear();
      _imageController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          top: 15,
          left: 15,
          right: 15,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: 'Título'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(hintText: 'Descrição'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _imageController,
                decoration: const InputDecoration(hintText: 'URL da Imagem (opcional)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (idPost == null) {
                    await SQLHelper.adicionarPostCommunity(
                      description: _descriptionController.text,
                      title: _titleController.text,
                      image: _imageController.text,
                      id_usuario: 1,
                    );
                  } else {
                    await SQLHelper.atualizarPostCommunity(
                      idPost: idPost,
                      description: _descriptionController.text,
                      title: _titleController.text,
                      image: _imageController.text,
                    );
                  }
                  _titleController.clear();
                  _descriptionController.clear();
                  _imageController.clear();
                  _atualizaPosts();
                  if (!mounted) return;
                  Navigator.of(context).pop();
                },
                child: Text(idPost == null ? 'Adicionar' : 'Atualizar'),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _apagaPost(int idPost) async {
    await SQLHelper.apagarPost(idPost);
    _scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Post apagado!')),
    );
    _atualizaPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Posts da Comunidade')),
      body: SafeArea(
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            final post = _posts[index];
            final imageUrl = post['image'] ?? '';
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {},
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Usuário',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                post['create_date'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        post['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 200,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                      )
                          : Center(
                        child: Icon(
                          Icons.photo,
                          size: 64,
                          color: Theme.of(context).primaryColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        (post['description'] ?? '').length > 120
                            ? '${post['description'].substring(0, 120)}...'
                            : post['description'] ?? '',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).primaryColor,
                            ),
                            child: const Text('Ler mais'),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _mostraEdicao(post['idPost']),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _apagaPost(post['idPost']),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostraEdicao(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
