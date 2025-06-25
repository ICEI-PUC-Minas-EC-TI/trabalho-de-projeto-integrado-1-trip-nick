import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design_system/colors/ui_colors.dart';
import '../design_system/colors/color_aliases.dart';
import '../models/core/spot.dart';
import '../providers/posts_provider.dart';
import '../widgets/spot_selection_widget.dart';

/// Complete post creation screen for creating community posts
///
/// This screen allows users to:
/// - Enter a post title (required, max 45 characters)
/// - Write a description (optional, max 500 characters)
/// - Select spots to include in the post (required, 1-10 spots)
/// - Submit the post for creation
class PostCreationScreen extends StatefulWidget {
  const PostCreationScreen({Key? key}) : super(key: key);

  @override
  State<PostCreationScreen> createState() => _PostCreationScreenState();
}

class _PostCreationScreenState extends State<PostCreationScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Selected spots list
  List<Spot> _selectedSpots = [];

  // Form state
  String? _errorMessage;

  // Constants
  static const int _maxTitleLength = 45;
  static const int _maxDescriptionLength = 500;
  static const int _maxSpots = 10;
  static const int _minSpots = 1;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PostsProvider>(
      builder: (context, postsProvider, child) {
        return Scaffold(
          backgroundColor: UIColors.surfacePrimary,
          appBar: _buildAppBar(postsProvider),
          body: _buildBody(postsProvider),
        );
      },
    );
  }

  /// Builds the app bar with close button and submit action
  PreferredSizeWidget _buildAppBar(PostsProvider postsProvider) {
    return AppBar(
      title: const Text('Create Post'),
      backgroundColor: ColorAliases.primaryDefault,
      foregroundColor: UIColors.textOnAction,
      leading: IconButton(icon: const Icon(Icons.close), onPressed: _onCancel),
      actions: [
        TextButton(
          onPressed:
              _canSubmit() && !postsProvider.isCreatingPost ? _onSubmit : null,
          child: Text(
            'Post',
            style: TextStyle(
              color:
                  (_canSubmit() && !postsProvider.isCreatingPost)
                      ? UIColors.textOnAction
                      : UIColors.textOnAction.withOpacity(0.5),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ],
      elevation: 0,
    );
  }

  /// Builds the main body content
  Widget _buildBody(PostsProvider postsProvider) {
    return Stack(
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              // Main form content (scrollable)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleSection(),
                      const SizedBox(height: 24),
                      _buildDescriptionSection(),
                      const SizedBox(height: 24),
                      _buildSpotsSection(),
                      const SizedBox(height: 24),
                      // Show error from PostsProvider if any
                      if (postsProvider.hasCreationError)
                        _buildErrorMessage(postsProvider.creationErrorMessage!),
                      // Show local error if any (for validation)
                      if (_errorMessage != null &&
                          !postsProvider.hasCreationError)
                        _buildErrorMessage(_errorMessage!),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Loading overlay (from PostsProvider state)
        if (postsProvider.isCreatingPost) _buildLoadingOverlay(),
      ],
    );
  }

  /// Builds the title input section
  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Title', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'What\'s your post about?',
            counterText: '${_titleController.text.length}/$_maxTitleLength',
            suffixIcon:
                _titleController.text.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _titleController.clear();
                        setState(() {});
                      },
                    )
                    : null,
          ),
          maxLength: _maxTitleLength,
          validator: _validateTitle,
          onChanged: (value) {
            setState(() {
              _errorMessage = null; // Clear error when user types
            });
          },
        ),
      ],
    );
  }

  /// Builds the description input section
  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Description', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Tell others about your experience (optional)',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: UIColors.textDisabled),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: 'Share details about these amazing places...',
            counterText:
                '${_descriptionController.text.length}/$_maxDescriptionLength',
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          maxLength: _maxDescriptionLength,
          validator: _validateDescription,
          onChanged: (value) {
            setState(() {
              _errorMessage = null; // Clear error when user types
            });
          },
        ),
      ],
    );
  }

  /// Builds the spots selection section
  Widget _buildSpotsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Spots',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Text(
              '${_selectedSpots.length}/$_maxSpots',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:
                    _selectedSpots.length >= _maxSpots
                        ? UIColors.textError
                        : UIColors.textDisabled,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Add places you want to share with the community',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: UIColors.textDisabled),
        ),
        const SizedBox(height: 12),

        // Selected spots display
        if (_selectedSpots.isNotEmpty) ...[
          _buildSelectedSpotsList(),
          const SizedBox(height: 16),
        ],

        // Add spots button
        _buildAddSpotsButton(),

        // Spots validation error
        if (_selectedSpots.isEmpty) _buildSpotsValidationError(),
      ],
    );
  }

  /// Builds the list of selected spots
  Widget _buildSelectedSpotsList() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: UIColors.borderPrimary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children:
            _selectedSpots.asMap().entries.map((entry) {
              final index = entry.key;
              final spot = entry.value;
              return _buildSelectedSpotItem(spot, index);
            }).toList(),
      ),
    );
  }

  /// Builds an individual selected spot item
  Widget _buildSelectedSpotItem(Spot spot, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border:
            index > 0
                ? const Border(top: BorderSide(color: UIColors.borderPrimary))
                : null,
      ),
      child: Row(
        children: [
          // Spot icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ColorAliases.primary100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCategoryIcon(spot.category),
              color: ColorAliases.primaryDefault,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Spot info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spot.spot_name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  spot.fullLocation,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: UIColors.textDisabled),
                ),
              ],
            ),
          ),

          // Remove button
          IconButton(
            icon: const Icon(Icons.close),
            color: UIColors.iconPrimary,
            onPressed: () => _removeSpot(spot),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  /// Builds the add spots button
  Widget _buildAddSpotsButton() {
    final canAddMore = _selectedSpots.length < _maxSpots;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: canAddMore ? _onAddSpots : null,
        icon: Icon(
          Icons.add_location,
          color:
              canAddMore ? ColorAliases.primaryDefault : UIColors.iconPrimary,
        ),
        label: Text(
          canAddMore ? 'Add Spots' : 'Maximum spots reached',
          style: TextStyle(
            color:
                canAddMore
                    ? ColorAliases.primaryDefault
                    : UIColors.textDisabled,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(
            color:
                canAddMore
                    ? ColorAliases.primaryDefault
                    : UIColors.borderPrimary,
          ),
        ),
      ),
    );
  }

  /// Builds spots validation error message
  Widget _buildSpotsValidationError() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Please add at least one spot to your post',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: UIColors.textError),
      ),
    );
  }

  /// Builds error message display
  Widget _buildErrorMessage(String errorMessage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: UIColors.surfaceError,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: UIColors.borderError),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: UIColors.iconError, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: UIColors.textError),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds loading overlay
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            ColorAliases.primaryDefault,
          ),
        ),
      ),
    );
  }

  // =============================================================================
  // VALIDATION METHODS
  // =============================================================================

  /// Validates the title field
  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    if (value.trim().length > _maxTitleLength) {
      return 'Title must be $_maxTitleLength characters or less';
    }
    return null;
  }

  /// Validates the description field
  String? _validateDescription(String? value) {
    if (value != null && value.length > _maxDescriptionLength) {
      return 'Description must be $_maxDescriptionLength characters or less';
    }
    return null;
  }

  /// Checks if the form can be submitted
  bool _canSubmit() {
    return _titleController.text.trim().isNotEmpty &&
        _selectedSpots.isNotEmpty &&
        _selectedSpots.length <= _maxSpots;
  }

  // =============================================================================
  // EVENT HANDLERS
  // =============================================================================

  /// Handles cancel button press
  void _onCancel() {
    if (_hasUnsavedChanges()) {
      _showCancelDialog();
    } else {
      Navigator.of(context).pop();
    }
  }

  /// Handles form submission
  void _onSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSpots.isEmpty) {
      setState(() {
        _errorMessage = 'Please add at least one spot to your post';
      });
      return;
    }

    // Get PostsProvider
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);

    // Clear any previous errors
    postsProvider.clearCreationError();

    // Create the community post
    final success = await postsProvider.createCommunityPost(
      title: _titleController.text.trim(),
      description:
          _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
      userId: 3, // TODO: Get from actual logged-in user
      selectedSpots: _selectedSpots,
    );

    if (mounted) {
      if (success) {
        // Post created successfully - navigate back
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: ColorAliases.successDefault,
          ),
        );
      }
      // Error handling is done through PostsProvider state
    }
  }

  /// Handles adding spots
  void _onAddSpots() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => SpotSelectionWidget(
              selectedSpots: _selectedSpots,
              maxSpots: _maxSpots,
              onSpotsSelected: (selectedSpots) {
                setState(() {
                  _selectedSpots = selectedSpots;
                  _errorMessage = null;
                });
              },
            ),
      ),
    );
  }

  /// Removes a spot from selection
  void _removeSpot(Spot spot) {
    setState(() {
      _selectedSpots.removeWhere((s) => s.spot_id == spot.spot_id);
    });
  }

  // =============================================================================
  // HELPER METHODS
  // =============================================================================

  /// Checks if there are unsaved changes
  bool _hasUnsavedChanges() {
    return _titleController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _selectedSpots.isNotEmpty;
  }

  /// Shows cancel confirmation dialog
  void _showCancelDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Discard post?'),
            content: const Text(
              'Your changes will be lost if you leave without saving.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue editing'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Close screen
                },
                child: const Text('Discard'),
              ),
            ],
          ),
    );
  }

  /// Gets icon for spot category
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'praia':
        return Icons.beach_access;
      case 'cachoeira':
        return Icons.water;
      case 'montanha':
        return Icons.landscape;
      case 'parque nacional':
        return Icons.park;
      case 'centro histórico':
        return Icons.account_balance;
      case 'museu':
        return Icons.museum;
      default:
        return Icons.place;
    }
  }
}
