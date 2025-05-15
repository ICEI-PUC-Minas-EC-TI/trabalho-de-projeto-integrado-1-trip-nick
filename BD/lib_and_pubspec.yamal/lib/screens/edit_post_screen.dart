import 'package:flutter/material.dart';

class EditPostScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const EditPostScreen({Key? key, required this.post}) : super(key: key);

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post['title']);
    _descriptionController = TextEditingController(text: widget.post['description']);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _savePost() {
    final updatedPost = {
      ...widget.post,
      'title': _titleController.text,
      'description': _descriptionController.text,
      'datePosted': DateTime.now().toString().split(' ')[0], // atualiza a data
    };

    Navigator.pop(context, updatedPost);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Post')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _descriptionController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savePost,
                child: const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
