import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design_system/colors/ui_colors.dart';
import '../design_system/colors/color_aliases.dart';
import '../models/core/spot.dart';
import '../providers/posts_provider.dart';
import '../providers/lists_provider.dart';
import '../widgets/spot_selection_widget.dart';
import '../models/enums/post_creation_mode.dart';

/// Complete post creation screen for creating community posts and list posts
///
/// This screen allows users to:
/// - Choose between community post or list post creation
/// - Enter a post title (required, max 45 characters)
/// - Write a description (optional, max 500 characters)
/// - Select spots to include in the post (required, 1-10 spots)
/// - Submit the post for creation
class PostCreationScreen extends StatefulWidget {
  /// The creation mode (community or list post)
  final PostCreationMode mode;

  const PostCreationScreen({Key? key, this.mode = PostCreationMode.community})
    : super(key: key);

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

  // Current user ID (mock - replace with real authentication)
  static const int _currentUserId = 3;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use different providers based on mode
    if (widget.mode == PostCreationMode.listPost) {
      return Consumer<ListPostsProvider>(
        builder: (context, listPostsProvider, child) {
          return _buildScaffold(
            isLoading: listPostsProvider.isCreatingListPost,
            errorMessage: listPostsProvider.creationErrorMessage,
            hasError: listPostsProvider.hasCreationError,
          );
        },
      );
    } else {
      return Consumer<PostsProvider>(
        builder: (context, postsProvider, child) {
          return _buildScaffold(
            isLoading: postsProvider.isCreatingPost,
            errorMessage: postsProvider.creationErrorMessage,
            hasError: postsProvider.hasCreationError,
          );
        },
      );
    }
  }

  /// Builds the main scaffold structure
  Widget _buildScaffold({
    required bool isLoading,
    String? errorMessage,
    required bool hasError,
  }) {
    return Scaffold(
      backgroundColor: UIColors.surfacePrimary,
      appBar: _buildAppBar(isLoading),
      body: _buildBody(isLoading, errorMessage, hasError),
    );
  }

  /// Builds the app bar with close button and submit action
  PreferredSizeWidget _buildAppBar(bool isLoading) {
    final String title =
        widget.mode == PostCreationMode.listPost
            ? 'Create List'
            : 'Create Post';

    final String submitText =
        widget.mode == PostCreationMode.listPost ? 'Create' : 'Post';

    return AppBar(
      title: Text(title),
      backgroundColor: ColorAliases.primaryDefault,
      foregroundColor: UIColors.textOnAction,
      leading: IconButton(icon: const Icon(Icons.close), onPressed: _onCancel),
      actions: [
        TextButton(
          onPressed: _canSubmit() && !isLoading ? _onSubmit : null,
          child: Text(
            submitText,
            style: TextStyle(
              color:
                  (_canSubmit() && !isLoading)
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
  Widget _buildBody(bool isLoading, String? errorMessage, bool hasError) {
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
                      if (widget.mode == PostCreationMode.listPost)
                        _buildListPostHeader(),
                      _buildTitleSection(),
                      const SizedBox(height: 24),
                      _buildDescriptionSection(),
                      const SizedBox(height: 24),
                      _buildSpotsSection(),
                      const SizedBox(height: 24),
                      // Show error from provider if any
                      if (hasError && errorMessage != null)
                        _buildErrorMessage(errorMessage),
                      // Show local error if any (for validation)
                      if (_errorMessage != null && !hasError)
                        _buildErrorMessage(_errorMessage!),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Loading overlay (from provider state)
        if (isLoading) _buildLoadingOverlay(),
      ],
    );
  }

  /// Builds the list post header with explanation
  Widget _buildListPostHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: ColorAliases.primaryDefault.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorAliases.primaryDefault.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list, color: ColorAliases.primaryDefault, size: 20),
              const SizedBox(width: 8),
              Text(
                'Creating a New List',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ColorAliases.primaryDefault,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re creating a new public list and sharing it with the community. Select your favorite spots and give it a great title!',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: UIColors.textAction),
          ),
        ],
      ),
    );
  }

  /// Builds the title input section
  Widget _buildTitleSection() {
    final String hintText =
        widget.mode == PostCreationMode.listPost
            ? 'What\'s your list about?'
            : 'What\'s your post about?';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Title', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: hintText,
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
    final String labelText =
        widget.mode == PostCreationMode.listPost
            ? 'Description'
            : 'Description';

    final String hintText =
        widget.mode == PostCreationMode.listPost
            ? 'Tell others about your list...'
            : 'Share details about these amazing places...';

    final String helperText =
        widget.mode == PostCreationMode.listPost
            ? 'Describe what makes this list special (optional)'
            : 'Tell others about your experience (optional)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          helperText,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: UIColors.textDisabled),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: hintText,
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
    final String sectionTitle =
        widget.mode == PostCreationMode.listPost
            ? 'Spots for Your List'
            : 'Spots';

    final String helperText =
        widget.mode == PostCreationMode.listPost
            ? 'Add amazing places to your new list'
            : 'Add places you want to share with the community';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                sectionTitle,
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
          helperText,
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

  /// Builds the list of selected spots (reused from original)
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

  /// Builds an individual selected spot item (reused from original)
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
          // Spot info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spot.spot_name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '${spot.city}, ${spot.country}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: UIColors.textDisabled),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ColorAliases.primaryDefault.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    spot.category,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ColorAliases.primaryDefault,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Remove button
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            color: UIColors.iconError,
            onPressed: () => _removeSpot(spot),
          ),
        ],
      ),
    );
  }

  /// Builds add spots button (reused from original)
  Widget _buildAddSpotsButton() {
    final bool canAddMore = _selectedSpots.length < _maxSpots;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: canAddMore ? _onAddSpots : null,
        icon: Icon(
          Icons.add_location_alt,
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

  /// Builds spots validation error message (reused from original)
  Widget _buildSpotsValidationError() {
    final String errorText =
        widget.mode == PostCreationMode.listPost
            ? 'Please add at least one spot to your list'
            : 'Please add at least one spot to your post';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        errorText,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: UIColors.textError),
      ),
    );
  }

  /// Builds error message display (reused from original)
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

  /// Builds loading overlay (reused from original)
  Widget _buildLoadingOverlay() {
    final String loadingText =
        widget.mode == PostCreationMode.listPost
            ? 'Criando lista...'
            : 'Criando post...';

    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                ColorAliases.primaryDefault,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              loadingText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // VALIDATION METHODS (Reused from original)
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
        _titleController.text.length <= _maxTitleLength &&
        (_descriptionController.text.isEmpty ||
            _descriptionController.text.length <= _maxDescriptionLength) &&
        _selectedSpots.isNotEmpty &&
        _selectedSpots.length <= _maxSpots;
  }

  // =============================================================================
  // EVENT HANDLERS
  // =============================================================================

  /// Handles form submission
  void _onSubmit() async {
    // Clear local errors
    setState(() {
      _errorMessage = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = 'Please fix the errors above';
      });
      return;
    }

    // Check spots requirement
    if (_selectedSpots.isEmpty) {
      setState(() {
        _errorMessage =
            widget.mode == PostCreationMode.listPost
                ? 'Please add at least one spot to your list'
                : 'Please add at least one spot to your post';
      });
      return;
    }

    // Submit based on mode
    bool success = false;
    if (widget.mode == PostCreationMode.listPost) {
      success = await _submitListPost();
    } else {
      success = await _submitCommunityPost();
    }

    if (success && mounted) {
      Navigator.of(context).pop();
      _showSuccessSnackBar();
    }
  }

  /// Submits list post
  Future<bool> _submitListPost() async {
    final listPostsProvider = Provider.of<ListPostsProvider>(
      context,
      listen: false,
    );

    return await listPostsProvider.createListPost(
      title: _titleController.text.trim(),
      description:
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
      userId: _currentUserId,
      selectedSpots: _selectedSpots,
    );
  }

  /// Submits community post
  Future<bool> _submitCommunityPost() async {
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);

    return await postsProvider.createCommunityPost(
      title: _titleController.text.trim(),
      description:
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
      userId: _currentUserId,
      selectedSpots: _selectedSpots,
    );
  }

  /// Handles cancel action
  void _onCancel() {
    Navigator.of(context).pop();
  }

  /// Opens spot selection modal
  void _onAddSpots() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => SpotSelectionWidget(
              selectedSpots: _selectedSpots,
              maxSpots: _maxSpots,
              onSpotsSelected: (selectedSpots) {
                setState(() {
                  _selectedSpots = selectedSpots;
                  _errorMessage = null; // Clear error when spots are selected
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

  /// Shows success snackbar
  void _showSuccessSnackBar() {
    final String message =
        widget.mode == PostCreationMode.listPost
            ? 'Lista criada e compartilhada com sucesso!'
            : 'Post criado com sucesso!';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
