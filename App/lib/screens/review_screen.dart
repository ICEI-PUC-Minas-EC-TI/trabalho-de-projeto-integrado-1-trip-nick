import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design_system/colors/color_aliases.dart';
import '../design_system/colors/ui_colors.dart';
import '../providers/reviews_provider.dart';

class ReviewScreen extends StatefulWidget {
  final String spotName;
  final String spotId;

  const ReviewScreen({Key? key, required this.spotName, required this.spotId})
    : super(key: key);

  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  // Form key
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _commentController = TextEditingController();

  // Form state
  int selectedRating = 0;
  String? _errorMessage;

  // Constants
  static const int _maxDescriptionLength = 500;
  static const int _mockUserId =
      3; // TODO: Replace with actual user ID from auth

  @override
  void initState() {
    super.initState();

    // Debug: Print initialization
    debugPrint(
      'ReviewScreen: Initializing for spot: ${widget.spotName} (ID: ${widget.spotId})',
    );

    // Listen for provider state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reviewsProvider = Provider.of<ReviewsProvider>(
        context,
        listen: false,
      );
      debugPrint(
        'ReviewScreen: Initial provider state: ${reviewsProvider.getStateDebugInfo()}',
      );
    });
  }

  @override
  void dispose() {
    debugPrint('ReviewScreen: Disposing');
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('ReviewScreen: Building UI');

    return Consumer<ReviewsProvider>(
      builder: (context, reviewsProvider, child) {
        // Debug: Print provider state on each build
        debugPrint(
          'ReviewScreen: Consumer build - Provider state: ${reviewsProvider.getStateDebugInfo()}',
        );

        // Handle success state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (reviewsProvider.shouldShowSuccessMessage) {
            debugPrint('ReviewScreen: Success detected, showing message');
            _handleSuccessfulReview(reviewsProvider);
          }
        });

        return Scaffold(
          backgroundColor: ColorAliases.parchment,
          appBar: _buildAppBar(reviewsProvider),
          body: _buildBody(reviewsProvider),
        );
      },
    );
  }

  /// Builds app bar with loading state
  PreferredSizeWidget _buildAppBar(ReviewsProvider reviewsProvider) {
    return AppBar(
      title: Text(
        "Avaliar: ${widget.spotName}",
        style: const TextStyle(
          color: UIColors.textOnAction,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: reviewsProvider.isCreatingReview ? null : _onCancel,
      ),
    );
  }

  /// Builds main body content
  Widget _buildBody(ReviewsProvider reviewsProvider) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildRatingSection(reviewsProvider),
              const SizedBox(height: 32),
              _buildCommentSection(reviewsProvider),
              const SizedBox(height: 32),
              _buildSubmitButton(reviewsProvider),
              _buildErrorMessage(reviewsProvider),
              const SizedBox(height: 16),
              _buildDebugInfo(reviewsProvider), // Debug information
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the header section
  Widget _buildHeader() {
    return Column(
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
        const SizedBox(height: 8),
        Text(
          "Compartilhe sua experiência com outros viajantes",
          style: TextStyle(
            fontSize: 14,
            color: UIColors.textBody.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Builds the rating stars section
  Widget _buildRatingSection(ReviewsProvider reviewsProvider) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            return IconButton(
              icon: Icon(
                Icons.star,
                color:
                    selectedRating >= starIndex
                        ? ColorAliases.warningDefault
                        : UIColors.iconPrimary,
                size: 36,
              ),
              onPressed:
                  reviewsProvider.isCreatingReview
                      ? null
                      : () {
                        debugPrint('ReviewScreen: Rating selected: $starIndex');
                        setState(() {
                          selectedRating = starIndex;
                          _errorMessage = null;
                        });
                        reviewsProvider.clearCreationError();
                      },
            );
          }),
        ),
        const SizedBox(height: 12),
        Text(
          selectedRating == 0
              ? "Toque nas estrelas para avaliar"
              : "$selectedRating estrela${selectedRating == 1 ? '' : 's'}",
          style: TextStyle(
            fontSize: 16,
            color:
                selectedRating == 0
                    ? UIColors.textBody.withOpacity(0.6)
                    : UIColors.textBody,
            fontWeight:
                selectedRating == 0 ? FontWeight.normal : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Builds the comment section
  Widget _buildCommentSection(ReviewsProvider reviewsProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Deixe um comentário sobre o local",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: UIColors.textHeadings,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Opcional - Compartilhe detalhes da sua experiência",
          style: TextStyle(
            fontSize: 14,
            color: UIColors.textBody.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _commentController,
          maxLines: 5,
          maxLength: _maxDescriptionLength,
          enabled: !reviewsProvider.isCreatingReview,
          decoration: InputDecoration(
            hintText: "Escreva sua opinião aqui...",
            filled: true,
            fillColor: ColorAliases.white,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: UIColors.borderPrimary),
              borderRadius: BorderRadius.circular(8),
            ),
            counterText: reviewsProvider.getDescriptionCharacterCount(
              _commentController.text,
            ),
            counterStyle: TextStyle(
              color:
                  reviewsProvider.isDescriptionNearLimit(
                        _commentController.text,
                      )
                      ? ColorAliases.errorDefault
                      : UIColors.textBody.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          validator: (value) => reviewsProvider.validateDescription(value),
          onChanged: (value) {
            setState(() {}); // Update character count
            reviewsProvider.clearCreationError();
          },
        ),
      ],
    );
  }

  /// Builds the submit button
  Widget _buildSubmitButton(ReviewsProvider reviewsProvider) {
    final canSubmit = _canSubmit() && !reviewsProvider.isCreatingReview;

    debugPrint(
      'ReviewScreen: Submit button - canSubmit: $canSubmit, isCreating: ${reviewsProvider.isCreatingReview}, selectedRating: $selectedRating',
    );

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed:
            canSubmit
                ? () {
                  debugPrint('ReviewScreen: Submit button pressed!');
                  _onSubmit();
                }
                : () {
                  debugPrint(
                    'ReviewScreen: Submit button pressed but disabled - canSubmit: $canSubmit',
                  );
                },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              canSubmit
                  ? Theme.of(context).primaryColor
                  : UIColors.textBody.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child:
            reviewsProvider.isCreatingReview
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          UIColors.textOnAction,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Enviando avaliação...",
                      style: TextStyle(
                        color: UIColors.textOnAction,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
                : const Text(
                  "Enviar Avaliação",
                  style: TextStyle(
                    color: UIColors.textOnAction,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
    );
  }

  /// Builds error message display
  Widget _buildErrorMessage(ReviewsProvider reviewsProvider) {
    if (!reviewsProvider.hasCreationError) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorAliases.errorDefault.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorAliases.errorDefault.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: ColorAliases.errorDefault, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reviewsProvider.creationErrorMessage!,
              style: TextStyle(color: ColorAliases.errorDefault, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds debug information (only in debug mode)
  Widget _buildDebugInfo(ReviewsProvider reviewsProvider) {
    // Only show in debug mode
    if (true) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🐛 Debug Info:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            "Spot ID: ${widget.spotId}",
            style: const TextStyle(fontSize: 11),
          ),
          Text(
            "Selected Rating: $selectedRating",
            style: const TextStyle(fontSize: 11),
          ),
          Text(
            "Can Submit: ${_canSubmit()}",
            style: const TextStyle(fontSize: 11),
          ),
          Text(
            "Is Creating: ${reviewsProvider.isCreatingReview}",
            style: const TextStyle(fontSize: 11),
          ),
          Text(
            "Has Error: ${reviewsProvider.hasCreationError}",
            style: const TextStyle(fontSize: 11),
          ),
          if (reviewsProvider.hasCreationError)
            Text(
              "Error: ${reviewsProvider.creationErrorMessage}",
              style: const TextStyle(fontSize: 11),
            ),
        ],
      ),
    );
  }

  // =============================================================================
  // EVENT HANDLERS
  // =============================================================================

  /// Handle form submission
  void _onSubmit() async {
    debugPrint('ReviewScreen: _onSubmit called');

    if (!_canSubmit()) {
      debugPrint('ReviewScreen: Cannot submit - validation failed');
      return;
    }

    final reviewsProvider = Provider.of<ReviewsProvider>(
      context,
      listen: false,
    );

    // Clear any previous errors
    setState(() {
      _errorMessage = null;
    });
    reviewsProvider.clearCreationError();

    // Validate form
    if (!_formKey.currentState!.validate()) {
      debugPrint('ReviewScreen: Form validation failed');
      return;
    }

    // Parse spot ID
    int? spotIdInt;
    try {
      spotIdInt = int.parse(widget.spotId);
      debugPrint('ReviewScreen: Parsed spot ID: $spotIdInt');
    } catch (e) {
      debugPrint(
        'ReviewScreen: Failed to parse spot ID: ${widget.spotId} - Error: $e',
      );
      setState(() {
        _errorMessage = 'ID do local inválido';
      });
      return;
    }

    final description = _commentController.text.trim();
    final finalDescription = description.isEmpty ? null : description;

    debugPrint('ReviewScreen: Submitting review:');
    debugPrint('  - Spot ID: $spotIdInt');
    debugPrint('  - Rating: $selectedRating');
    debugPrint('  - Description: "$finalDescription"');
    debugPrint('  - User ID: $_mockUserId');

    // Submit review
    final success = await reviewsProvider.createReviewPost(
      spotId: spotIdInt,
      rating: selectedRating,
      description: finalDescription,
      userId: _mockUserId,
    );

    debugPrint('ReviewScreen: Review submission result: $success');

    // Handle result
    if (!success && mounted) {
      debugPrint('ReviewScreen: Review submission failed');
      // Error will be displayed automatically through provider state
    } else if (success) {
      debugPrint('ReviewScreen: Review submission succeeded');
    }
  }

  /// Handle cancel action
  void _onCancel() {
    debugPrint('ReviewScreen: Cancel pressed');
    Navigator.of(context).pop();
  }

  /// Handle successful review creation
  void _handleSuccessfulReview(ReviewsProvider reviewsProvider) {
    debugPrint('ReviewScreen: Handling successful review creation');

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: UIColors.textOnAction, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                reviewsProvider.successMessage,
                style: const TextStyle(
                  color: UIColors.textOnAction,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: ColorAliases.successDefault,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    // Acknowledge success and return to previous screen
    reviewsProvider.acknowledgeReviewCreation();

    debugPrint('ReviewScreen: Returning to previous screen with review data');

    // Return review data to previous screen
    Navigator.of(context).pop({
      'rating': selectedRating,
      'comment': _commentController.text.trim(),
      'success': true,
    });
  }

  // =============================================================================
  // VALIDATION HELPERS
  // =============================================================================

  /// Check if form can be submitted
  bool _canSubmit() {
    final isValid = selectedRating > 0 && selectedRating <= 5;
    if (!isValid) {
      debugPrint('ReviewScreen: _canSubmit = false (rating: $selectedRating)');
    }
    return isValid;
  }

  /// Get current form validation state
  Map<String, dynamic> _getFormValidationState() {
    return {
      'has_rating': selectedRating > 0,
      'valid_rating': selectedRating >= 1 && selectedRating <= 5,
      'description_length': _commentController.text.length,
      'valid_description':
          _commentController.text.length <= _maxDescriptionLength,
      'can_submit': _canSubmit(),
    };
  }
}
