import 'package:flutter/material.dart';
import '../design_system/colors/color_aliases.dart';
import '../design_system/colors/ui_colors.dart';

class ReviewScreen extends StatefulWidget {
  final String spotName;
  final String spotId;

  const ReviewScreen({
    Key? key,
    required this.spotName,
    required this.spotId,
  }) : super(key: key);

  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorAliases.parchment,
      appBar: AppBar(
        title: Text(
          "Avaliar: ${widget.spotName}",
          style: const TextStyle(
            color: UIColors.textOnAction,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              const Text(
                "Escolha sua avaliação",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: UIColors.textHeadings,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    icon: Icon(
                      Icons.star,
                      color: selectedRating >= starIndex
                          ? ColorAliases.warningDefault
                          : UIColors.iconPrimary,
                      size: 36,
                    ),
                    onPressed: () {
                      setState(() {
                        selectedRating = starIndex;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              Text(
                "$selectedRating estrela${selectedRating == 1 ? '' : 's'}",
                style: const TextStyle(
                  fontSize: 16,
                  color: UIColors.textBody,
                ),
              ),

              const SizedBox(height: 32),
              const Text(
                "Deixe um comentário sobre o local",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: UIColors.textHeadings,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Escreva sua opinião aqui...",
                  filled: true,
                  fillColor: ColorAliases.white,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: UIColors.borderPrimary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: selectedRating == 0
                    ? null
                    : () {
                  final comment = _commentController.text.trim();

                  // Aqui você pode salvar rating + comentário
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Você avaliou com $selectedRating estrela${selectedRating == 1 ? '' : 's'}",
                      ),
                    ),
                  );

                  // Enviar dados ou voltar com resultado
                  Navigator.pop(context, {
                    'rating': selectedRating,
                    'comment': comment,
                  });
                },
                child: const Text("Enviar Avaliação"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
