/// Constants related to post creation and management
class PostConstants {
  // =============================================================================
  // FIELD CONSTRAINTS
  // =============================================================================

  /// Maximum length for post titles (database constraint)
  static const int maxTitleLength = 45;

  /// Maximum length for post descriptions (database constraint)
  static const int maxDescriptionLength = 500;

  /// Maximum number of spots per community post
  static const int maxSpotsPerPost = 10;

  /// Minimum number of spots per community post
  static const int minSpotsPerPost = 1;

  // =============================================================================
  // VALIDATION MESSAGES
  // =============================================================================

  /// Error messages for validation
  static const String titleRequiredError = 'Title is required';
  static const String titleTooLongError =
      'Title must be $maxTitleLength characters or less';
  static const String descriptionTooLongError =
      'Description must be $maxDescriptionLength characters or less';
  static const String spotsRequiredError =
      'Please add at least one spot to your post';
  static const String tooManySpotsError =
      'Maximum $maxSpotsPerPost spots allowed';
  static const String maxSpotsReachedError = 'Maximum spots reached';

  // =============================================================================
  // UI MESSAGES
  // =============================================================================

  /// Success messages
  static const String postCreatedSuccess = 'Post created successfully!';
  static const String postDeletedSuccess = 'Post deleted successfully';
  static const String draftSavedSuccess = 'Draft saved';

  /// Loading messages
  static const String creatingPostMessage = 'Creating your post...';
  static const String loadingSpotsMessage = 'Loading spots...';
  static const String savingDraftMessage = 'Saving draft...';

  /// Error messages
  static const String createPostError =
      'Failed to create post. Please try again.';
  static const String loadSpotsError =
      'Failed to load spots. Please check your connection.';
  static const String networkError =
      'Network error. Please check your connection.';
  static const String unknownError = 'Something went wrong. Please try again.';

  // =============================================================================
  // LIST GENERATION
  // =============================================================================

  /// Template for auto-generated list names for community posts
  /// {0} will be replaced with the post ID
  static const String autoListNameTemplate = 'Post #{0} Spots';

  /// Generate a list name for a community post
  static String generateListName(int postId) {
    return autoListNameTemplate.replaceAll('{0}', postId.toString());
  }

  /// Alternative list name generation using post title
  /// {0} will be replaced with the post title (truncated if needed)
  static const String titleBasedListTemplate = '{0} - Spots';

  /// Generate a list name based on post title
  static String generateListNameFromTitle(String postTitle) {
    // Truncate title to fit within list name constraints
    const maxTitleInListName =
        maxTitleLength - titleBasedListTemplate.length + 3; // +3 for {0}
    String truncatedTitle =
        postTitle.length > maxTitleInListName
            ? '${postTitle.substring(0, maxTitleInListName)}...'
            : postTitle;

    return titleBasedListTemplate.replaceAll('{0}', truncatedTitle);
  }

  // =============================================================================
  // CATEGORY ICONS MAPPING
  // =============================================================================

  /// Maps spot categories to their corresponding icons
  static const Map<String, String> categoryIcons = {
    'praia': 'beach_access',
    'cachoeira': 'water',
    'montanha': 'landscape',
    'parque nacional': 'park',
    'centro histórico': 'account_balance',
    'museu': 'museum',
    'igreja': 'church',
    'mirante': 'visibility',
    'trilha': 'hiking',
    'lagoa': 'water',
    'rio': 'water',
    'gruta': 'explore',
    'hotel': 'hotel',
    'pousada': 'bed',
    'camping': 'outdoor_grill',
    'praça': 'park',
    'monumento': 'account_balance',
    'memorial': 'account_balance',
    'estádio': 'stadium',
    'chalé': 'cabin',
    'natureza': 'nature',
  };

  /// Get icon name for a category (fallback to 'place' if not found)
  static String getIconForCategory(String category) {
    return categoryIcons[category.toLowerCase()] ?? 'place';
  }

  // =============================================================================
  // FORM HINTS AND PLACEHOLDERS
  // =============================================================================

  /// Form field hints and placeholders
  static const String titleHint = 'What\'s your post about?';
  static const String descriptionHint =
      'Share details about these amazing places...';
  static const String descriptionLabel =
      'Tell others about your experience (optional)';
  static const String spotsLabel =
      'Add places you want to share with the community';
  static const String searchSpotsHint = 'Search spots...';

  /// Button labels
  static const String addSpotsButton = 'Add Spots';
  static const String removeSpotButton = 'Remove';
  static const String clearAllButton = 'Clear All';
  static const String saveButton = 'Save';
  static const String postButton = 'Post';
  static const String cancelButton = 'Cancel';
  static const String discardButton = 'Discard';
  static const String continueEditingButton = 'Continue editing';
  static const String retryButton = 'Retry';
  static const String clearFiltersButton = 'Clear filters';

  // =============================================================================
  // DIALOG MESSAGES
  // =============================================================================

  /// Confirmation dialog messages
  static const String discardPostTitle = 'Discard post?';
  static const String discardPostMessage =
      'Your changes will be lost if you leave without saving.';
  static const String discardChangesTitle = 'Discard changes?';
  static const String discardChangesMessage =
      'Your selection changes will be lost.';

  /// Empty state messages
  static const String noSpotsTitle = 'No spots available';
  static const String noSpotsMessage = 'There are no spots to display';
  static const String noSpotsFoundTitle = 'No spots found';
  static const String noSpotsFoundMessage =
      'Try adjusting your search or filter';

  // =============================================================================
  // TIMING CONSTANTS
  // =============================================================================

  /// Delays and timeouts
  static const Duration postCreationTimeout = Duration(seconds: 30);
  static const Duration spotSelectionDelay = Duration(milliseconds: 100);
  static const Duration autoSaveDelay = Duration(seconds: 3);
  static const Duration loadingAnimationDuration = Duration(milliseconds: 200);

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================

  /// Validates if a title is within length constraints
  static bool isValidTitleLength(String title) {
    return title.trim().isNotEmpty && title.length <= maxTitleLength;
  }

  /// Validates if a description is within length constraints
  static bool isValidDescriptionLength(String? description) {
    return description == null || description.length <= maxDescriptionLength;
  }

  /// Validates if spots list is within constraints
  static bool isValidSpotsCount(List spots) {
    return spots.length >= minSpotsPerPost && spots.length <= maxSpotsPerPost;
  }

  /// Gets character count display text
  static String getCharacterCountText(int current, int max) {
    return '$current/$max';
  }

  /// Gets spots count display text
  static String getSpotsCountText(int current, int max) {
    return '$current/$max';
  }

  /// Checks if more spots can be added
  static bool canAddMoreSpots(int currentCount) {
    return currentCount < maxSpotsPerPost;
  }

  /// Gets remaining spots count
  static int getRemainingSpots(int currentCount) {
    return maxSpotsPerPost - currentCount;
  }

  // =============================================================================
  // ACCESSIBILITY
  // =============================================================================

  /// Accessibility labels and hints
  static const String titleFieldLabel = 'Post title';
  static const String descriptionFieldLabel = 'Post description';
  static const String addSpotsButtonLabel = 'Add spots to post';
  static const String removeSpotButtonLabel = 'Remove spot from post';
  static const String postButtonLabel = 'Create post';
  static const String cancelButtonLabel = 'Cancel post creation';

  /// Screen reader announcements
  static const String spotAddedAnnouncement = 'Spot added to post';
  static const String spotRemovedAnnouncement = 'Spot removed from post';
  static const String postCreatedAnnouncement = 'Post created successfully';
  static const String maxSpotsReachedAnnouncement =
      'Maximum number of spots reached';

  // Prevent instantiation
  PostConstants._();
}
