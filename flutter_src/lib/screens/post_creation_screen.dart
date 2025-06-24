import 'package:flutter/material.dart';
import '../design_system/colors/ui_colors.dart';
import '../design_system/colors/color_aliases.dart';

/// Placeholder screen for post creation
///
/// This is a temporary screen used to test navigation from the SpeedDialFAB.
/// In the next steps, this will be replaced with the full post creation form.
class PostCreationScreen extends StatelessWidget {
  const PostCreationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.surfacePrimary,
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: ColorAliases.primaryDefault,
        foregroundColor: UIColors.textOnAction,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.edit_note,
                size: 80,
                color: ColorAliases.primaryDefault,
              ),
              SizedBox(height: 24),
              Text(
                'Post Creation Screen',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: UIColors.textHeadings,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'This is a placeholder screen.\nThe full post creation form will be implemented in the next steps.',
                style: TextStyle(fontSize: 16, color: UIColors.textBody),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              Text(
                '📝 Coming Soon:\n• Title input\n• Description textarea\n• Spot selection\n• Image upload',
                style: TextStyle(fontSize: 14, color: UIColors.textDisabled),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder screen for list creation
///
/// This is a temporary screen used to test navigation from the SpeedDialFAB.
/// This will be implemented later when we add shareable list functionality.
class ListCreationScreen extends StatelessWidget {
  const ListCreationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.surfacePrimary,
      appBar: AppBar(
        title: const Text('Create List'),
        backgroundColor: ColorAliases.primaryDefault,
        foregroundColor: UIColors.textOnAction,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.list_alt,
                size: 80,
                color: ColorAliases.primaryDefault,
              ),
              SizedBox(height: 24),
              Text(
                'List Creation Screen',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: UIColors.textHeadings,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'This is a placeholder screen.\nShareable list creation will be implemented later.',
                style: TextStyle(fontSize: 16, color: UIColors.textBody),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              Text(
                '📋 Coming Later:\n• List name input\n• Privacy settings\n• Initial spot selection\n• List templates',
                style: TextStyle(fontSize: 14, color: UIColors.textDisabled),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
