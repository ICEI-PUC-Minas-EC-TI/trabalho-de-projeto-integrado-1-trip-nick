import 'package:flutter/foundation.dart';
import '../models/core/spot.dart';
import '../models/api_responses/create_post_request.dart';
import '../services/posts_service.dart';
import '../services/lists_service.dart';
import '../utils/exceptions.dart';
import '../utils/post_constants.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/api_responses/upload_result.dart';
import '../models/core/image.dart' as models;
import '../services/image_upload_service.dart';

/// State management for posts data
/// Handles post creation, loading states, error handling, and data caching
class PostsProvider extends ChangeNotifier {
  final PostsService _postsService = PostsService();
  final ListsService _listsService = ListsService();

  // =============================================================================
  // STATE VARIABLES
  // =============================================================================

  // Post creation state
  bool _isCreatingPost = false;
  String? _creationErrorMessage;
  CreateCommunityPostResponse? _lastCreatedPost;

  // Posts data
  List<Map<String, dynamic>> _communityPosts = [];
  List<Map<String, dynamic>> _allPosts = [];
  bool _isLoadingPosts = false;
  String? _postsErrorMessage;

  // Cache control
  DateTime? _lastPostsUpdate;
  static const Duration cacheTimeout = Duration(minutes: 5);

  // =============================================================================
  // IMAGE VARIABLES
  // =============================================================================

  /// Image upload service
  final ImageUploadService _imageUploadService = ImageUploadService();

  /// Image picker for camera/gallery access
  final ImagePicker _imagePicker = ImagePicker();

  /// Selected images for upload
  List<File> _selectedImages = [];

  /// Upload progress for each image (index -> progress)
  Map<int, double> _uploadProgress = {};

  /// Uploaded images results
  List<UploadResult> _uploadResults = [];

  /// Overall upload state
  bool _isUploadingImages = false;

  /// Upload error message
  String? _uploadErrorMessage;

  /// Batch upload progress (completed out of total)
  int _uploadedCount = 0;
  int _totalToUpload = 0;

  // =============================================================================
  // GETTERS - UI reads these values
  // =============================================================================

  // Post creation getters
  bool get isCreatingPost => _isCreatingPost;
  String? get creationErrorMessage => _creationErrorMessage;
  CreateCommunityPostResponse? get lastCreatedPost => _lastCreatedPost;
  bool get hasCreationError => _creationErrorMessage != null;

  // Posts data getters
  List<Map<String, dynamic>> get communityPosts => _communityPosts;
  List<Map<String, dynamic>> get allPosts => _allPosts;
  bool get isLoadingPosts => _isLoadingPosts;
  String? get postsErrorMessage => _postsErrorMessage;
  bool get hasPostsData => _allPosts.isNotEmpty;
  bool get hasPostsError => _postsErrorMessage != null;

  // =============================================================================
  // IMAGE UPLOAD GETTERS - Add these to your existing getters
  // =============================================================================

  /// Selected images for upload
  List<File> get selectedImages => _selectedImages;

  /// Upload progress for each image
  Map<int, double> get uploadProgress => _uploadProgress;

  /// Upload results
  List<UploadResult> get uploadResults => _uploadResults;

  /// Whether images are being uploaded
  bool get isUploadingImages => _isUploadingImages;

  /// Upload error message
  String? get uploadErrorMessage => _uploadErrorMessage;

  /// Whether there's an upload error
  bool get hasUploadError => _uploadErrorMessage != null;

  /// Batch upload progress (0.0 to 1.0)
  double get batchUploadProgress {
    if (_totalToUpload == 0) return 0.0;
    return _uploadedCount / _totalToUpload;
  }

  /// Number of successfully uploaded images
  int get successfulUploads =>
      _uploadResults.where((r) => r.isSuccessful).length;

  /// Number of failed uploads
  int get failedUploads => _uploadResults.where((r) => r.isFailed).length;

  /// Whether all uploads completed (successfully or not)
  bool get allUploadsCompleted =>
      _uploadedCount >= _totalToUpload && _totalToUpload > 0;

  /// Whether any uploads are in progress
  bool get hasUploadsInProgress => _uploadResults.any((r) => r.isInProgress);

  // =============================================================================
  // COMMUNITY POST CREATION (Main Feature)
  // =============================================================================

  /// Creates a community post with automatic hidden list creation
  ///
  /// This orchestrates the complete workflow:
  /// 1. Validates input data
  /// 2. Creates hidden list for spots
  /// 3. Adds spots to the list
  /// 4. Creates the community post
  ///
  /// Parameters:
  /// - [title]: Post title (required, max 45 chars)
  /// - [description]: Post description (optional, max 500 chars)
  /// - [userId]: ID of user creating the post
  /// - [selectedSpots]: List of spots to include (1-10 spots)
  ///
  /// Returns: true if successful, false if failed
  Future<bool> createCommunityPost({
    required String title,
    String? description,
    required int userId,
    required List<Spot> selectedSpots,
  }) async {
    _isCreatingPost = true;
    _creationErrorMessage = null;
    _lastCreatedPost = null;
    notifyListeners(); // Tell UI "I'm creating a post!"

    try {
      // Validate input before making API calls
      _validateCommunityPostInput(title, description, selectedSpots);

      // Create the community post through the service
      final response = await _postsService.createCommunityPost(
        title: title.trim(),
        description: description?.trim(),
        userId: userId,
        selectedSpots: selectedSpots,
      );

      // Success! Update state
      _lastCreatedPost = response;
      _isCreatingPost = false;
      _creationErrorMessage = null;

      // Invalidate posts cache so fresh data loads
      _lastPostsUpdate = null;

      notifyListeners(); // Tell UI "Post created successfully!"

      debugPrint('Community post created successfully: ${response.post_id}');
      return true;
    } catch (e) {
      _isCreatingPost = false;
      _creationErrorMessage = _getCreationErrorMessage(e);
      _lastCreatedPost = null;

      notifyListeners(); // Tell UI "Something went wrong!"

      debugPrint('Error creating community post: $e');
      return false;
    }
  }

  /// Gets progress information during post creation
  /// Useful for showing detailed progress to users
  String getCreationProgressMessage() {
    if (!_isCreatingPost) return '';

    // In a more advanced implementation, you could track
    // which step of the creation process you're on
    return PostConstants.creatingPostMessage;
  }

  // =============================================================================
  // POSTS LOADING (Future Feature)
  // =============================================================================

  /// Load community posts with optional filtering
  Future<void> loadCommunityPosts({
    int page = 1,
    int limit = 20,
    int? userId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && page == 1 && _hasFreshPostsData()) {
      return; // Use cached data
    }

    _isLoadingPosts = true;
    _postsErrorMessage = null;
    notifyListeners();

    try {
      final response = await _postsService.getPosts(
        page: page,
        limit: limit,
        userId: userId,
        type: 'community',
        includeImages: true,
        includeStats: false,
      );

      if (page == 1) {
        // First page - replace all data
        _communityPosts = response['posts'] ?? [];
      } else {
        // Additional pages - append data
        final newPosts = List<Map<String, dynamic>>.from(
          response['posts'] ?? [],
        );
        _communityPosts.addAll(newPosts);
      }

      _lastPostsUpdate = DateTime.now();
      _isLoadingPosts = false;
      _postsErrorMessage = null;

      notifyListeners();
    } catch (e) {
      _isLoadingPosts = false;
      _postsErrorMessage = _getPostsErrorMessage(e);

      notifyListeners();
      debugPrint('Error loading community posts: $e');
    }
  }

  /// Load all posts (community, review, list) with pagination
  Future<void> loadAllPosts({
    int page = 1,
    int limit = 20,
    String? type,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && page == 1 && _hasFreshPostsData()) {
      return;
    }

    _isLoadingPosts = true;
    _postsErrorMessage = null;
    notifyListeners();

    try {
      final response = await _postsService.getPosts(
        page: page,
        limit: limit,
        type: type,
        includeImages: true,
        includeStats: false,
      );

      if (page == 1) {
        _allPosts = response['posts'] ?? [];
      } else {
        final newPosts = List<Map<String, dynamic>>.from(
          response['posts'] ?? [],
        );
        _allPosts.addAll(newPosts);
      }

      _lastPostsUpdate = DateTime.now();
      _isLoadingPosts = false;
      _postsErrorMessage = null;

      notifyListeners();
    } catch (e) {
      _isLoadingPosts = false;
      _postsErrorMessage = _getPostsErrorMessage(e);

      notifyListeners();
      debugPrint('Error loading posts: $e');
    }
  }

  /// Refresh posts (pull-to-refresh)
  Future<void> refreshPosts() async {
    await loadAllPosts(forceRefresh: true);
  }

  // =============================================================================
  // IMAGE SELECTION METHODS - Add these new methods
  // =============================================================================

  /// Opens image picker to select images from gallery
  Future<void> selectImagesFromGallery() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        _selectedImages = pickedFiles.map((xFile) => File(xFile.path)).toList();
        _clearUploadState();
        notifyListeners();
      }
    } catch (e) {
      _uploadErrorMessage = 'Erro ao selecionar imagens: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Opens camera to take a photo
  Future<void> takePhotoWithCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _selectedImages = [File(pickedFile.path)];
        _clearUploadState();
        notifyListeners();
      }
    } catch (e) {
      _uploadErrorMessage = 'Erro ao tirar foto: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Removes an image from selection
  void removeSelectedImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages.removeAt(index);
      _clearUploadState();
      notifyListeners();
    }
  }

  /// Clears all selected images
  void clearSelectedImages() {
    _selectedImages.clear();
    _clearUploadState();
    notifyListeners();
  }

  // =============================================================================
  // IMAGE UPLOAD METHODS - Add these new methods
  // =============================================================================

  /// Uploads all selected images with progress tracking
  Future<void> uploadSelectedImages() async {
    if (_selectedImages.isEmpty) return;

    _isUploadingImages = true;
    _uploadErrorMessage = null;
    _uploadProgress.clear();
    _uploadResults.clear();
    _uploadedCount = 0;
    _totalToUpload = _selectedImages.length;
    notifyListeners();

    try {
      // Initialize image upload service
      _imageUploadService.initialize();

      // Upload images in batch
      _uploadResults = await _imageUploadService.uploadBatch(
        _selectedImages,
        onBatchProgress: (completed, total) {
          _uploadedCount = completed;
          _totalToUpload = total;
          notifyListeners();
        },
        onIndividualProgress: (index, progress) {
          _uploadProgress[index] = progress;
          notifyListeners();
        },
      );

      // Check for any failures
      final failedCount = _uploadResults.where((r) => r.isFailed).length;
      if (failedCount > 0) {
        _uploadErrorMessage = 'Falha no upload de $failedCount imagem(ns)';
      }
    } catch (e) {
      _uploadErrorMessage = 'Erro no upload: ${e.toString()}';
    } finally {
      _isUploadingImages = false;
      notifyListeners();
    }
  }

  /// Retries failed uploads
  Future<void> retryFailedUploads() async {
    final failedIndices = <int>[];

    for (int i = 0; i < _uploadResults.length; i++) {
      if (_uploadResults[i].isFailed) {
        failedIndices.add(i);
      }
    }

    if (failedIndices.isEmpty) return;

    _isUploadingImages = true;
    _uploadErrorMessage = null;
    notifyListeners();

    try {
      // Retry each failed upload
      for (final index in failedIndices) {
        final file = _selectedImages[index];
        final newResult = await _imageUploadService.uploadSingleImage(
          file,
          onProgress: (progress) {
            _uploadProgress[index] = progress;
            notifyListeners();
          },
        );
        _uploadResults[index] = newResult;
      }
    } catch (e) {
      _uploadErrorMessage = 'Erro ao tentar novamente: ${e.toString()}';
    } finally {
      _isUploadingImages = false;
      notifyListeners();
    }
  }

  // =============================================================================
  // COMMUNITY POST CREATION WITH IMAGES - Modify existing method
  // =============================================================================

  /// Enhanced community post creation with image upload support
  Future<bool> createCommunityPostWithImages({
    required String title,
    String? description,
    required int userId,
    required List<Spot> selectedSpots,
    List<File>? imageFiles,
  }) async {
    _isCreatingPost = true;
    _creationErrorMessage = null;
    _lastCreatedPost = null;
    notifyListeners();

    try {
      // Step 1: Upload images if provided
      List<UploadResult> uploadResults = [];
      if (imageFiles != null && imageFiles.isNotEmpty) {
        _selectedImages = imageFiles;
        await uploadSelectedImages();

        // Check if image uploads were successful
        uploadResults = _uploadResults;
        final failedUploads = uploadResults.where((r) => r.isFailed).length;
        if (failedUploads > 0) {
          throw ServerException('Falha no upload de $failedUploads imagem(ns)');
        }
      }

      // Step 2: Create the community post (existing logic)
      final response = await _postsService.createCommunityPost(
        title: title.trim(),
        description: description?.trim(),
        userId: userId,
        selectedSpots: selectedSpots,
      );

      // Step 3: Link images to the created post
      if (uploadResults.isNotEmpty && response.post_id != null) {
        final linkSuccess = await _imageUploadService.linkImagesToPost(
          response.post_id!,
          uploadResults,
        );

        if (!linkSuccess) {
          // Post was created but image linking failed
          // This is not a complete failure, just log it
          debugPrint('Warning: Post created but image linking failed');
        }
      }

      // Success! Update state
      _lastCreatedPost = response;
      _isCreatingPost = false;
      _creationErrorMessage = null;

      // Clear image state after successful post creation
      _clearImageState();

      // Invalidate posts cache so fresh data loads
      _lastPostsUpdate = null;

      notifyListeners();

      debugPrint(
        'Community post with images created successfully: ${response.post_id}',
      );
      return true;
    } catch (e) {
      _isCreatingPost = false;
      _creationErrorMessage = _getCreationErrorMessage(e);
      _lastCreatedPost = null;

      notifyListeners();

      debugPrint('Error creating community post with images: $e');
      return false;
    }
  }

  // =============================================================================
  // VALIDATION HELPERS
  // =============================================================================

  /// Validates post title in real-time (for form validation)
  String? validateTitle(String title) {
    final errors = _postsService.validatePostTitle(title);
    return errors.isNotEmpty ? errors.first : null;
  }

  /// Validates post description in real-time
  String? validateDescription(String? description) {
    final errors = _postsService.validatePostDescription(description);
    return errors.isNotEmpty ? errors.first : null;
  }

  /// Validates spot selection in real-time
  String? validateSpotSelection(List<Spot> spots) {
    final errors = _postsService.validateSpotSelection(spots);
    return errors.isNotEmpty ? errors.first : null;
  }

  /// Checks if all form data is valid for submission
  bool isValidForSubmission({
    required String title,
    String? description,
    required List<Spot> selectedSpots,
  }) {
    return validateTitle(title) == null &&
        validateDescription(description) == null &&
        validateSpotSelection(selectedSpots) == null;
  }

  // =============================================================================
  // HELPER METHODS - Add these private methods
  // =============================================================================

  /// Clears upload state but keeps selected images
  void _clearUploadState() {
    _uploadProgress.clear();
    _uploadResults.clear();
    _uploadErrorMessage = null;
    _isUploadingImages = false;
    _uploadedCount = 0;
    _totalToUpload = 0;
  }

  /// Clears all image-related state
  void _clearImageState() {
    _selectedImages.clear();
    _clearUploadState();
  }

  /// Gets upload status message for UI display
  String getUploadStatusMessage() {
    if (_uploadResults.isEmpty) return '';

    final successful = successfulUploads;
    final failed = failedUploads;
    final total = _uploadResults.length;

    if (failed == 0) {
      return '$successful/$total imagens enviadas com sucesso';
    } else if (successful == 0) {
      return 'Falha no envio de todas as $total imagens';
    } else {
      return '$successful/$total imagens enviadas ($failed falharam)';
    }
  }

  /// Validates selected images
  String? validateSelectedImages() {
    if (_selectedImages.isEmpty) return null;

    // Check file sizes
    for (final file in _selectedImages) {
      final fileSize = file.lengthSync();
      if (fileSize > _imageUploadService.maxFileSize) {
        return 'Uma ou mais imagens excedem o tamanho máximo de ${_imageUploadService.getFileSizeString(_imageUploadService.maxFileSize)}';
      }

      // Check if it's a valid image
      if (!_imageUploadService.isValidImageFile(file)) {
        return 'Um ou mais arquivos não são imagens válidas';
      }
    }

    return null;
  }

  // =============================================================================
  // IMAGE PREVIEW HELPERS - Add these utility methods
  // =============================================================================

  /// Gets display URL for uploaded image
  String? getImageDisplayUrl(int index) {
    if (index < 0 || index >= _uploadResults.length) return null;

    final result = _uploadResults[index];
    if (result.registeredImage?.displayUrl != null) {
      return result.registeredImage!.displayUrl;
    }

    // If not uploaded yet, return local file path for preview
    if (index < _selectedImages.length) {
      return _selectedImages[index].path;
    }

    return null;
  }

  /// Gets upload status for specific image
  String getImageUploadStatus(int index) {
    if (index < 0 || index >= _uploadResults.length) {
      return 'Aguardando upload...';
    }

    return _uploadResults[index].statusMessage;
  }

  /// Checks if specific image upload was successful
  bool isImageUploadSuccessful(int index) {
    if (index < 0 || index >= _uploadResults.length) return false;
    return _uploadResults[index].isSuccessful;
  }

  /// Gets file size for selected image
  String getSelectedImageSize(int index) {
    if (index < 0 || index >= _selectedImages.length) return '';

    try {
      final fileSize = _selectedImages[index].lengthSync();
      return _imageUploadService.getFileSizeString(fileSize);
    } catch (e) {
      return 'Tamanho desconhecido';
    }
  }

  // =============================================================================
  // ERROR HANDLING AND MESSAGES
  // =============================================================================

  /// Clear creation error message
  void clearCreationError() {
    _creationErrorMessage = null;
    notifyListeners();
  }

  /// Clear posts error message
  void clearPostsError() {
    _postsErrorMessage = null;
    notifyListeners();
  }

  /// Clear all errors
  void clearAllErrors() {
    _creationErrorMessage = null;
    _postsErrorMessage = null;
    notifyListeners();
  }

  // =============================================================================
  // HELPER METHODS (Following SpotsProvider patterns)
  // =============================================================================

  /// Check if posts data is fresh (within cache timeout)
  bool _hasFreshPostsData() {
    if (_lastPostsUpdate == null) return false;
    return DateTime.now().difference(_lastPostsUpdate!) < cacheTimeout;
  }

  /// Convert exceptions to user-friendly error messages for post creation
  String _getCreationErrorMessage(dynamic error) {
    if (error is NetworkException) {
      return 'Verifique sua conexão com a internet';
    } else if (error is ServerException) {
      return 'Erro no servidor. Tente novamente mais tarde';
    } else if (error is NotFoundException) {
      return 'Algum spot selecionado não foi encontrado';
    } else if (error is TimeoutException) {
      return 'Tempo limite esgotado. Tente novamente';
    } else {
      return 'Falha ao criar post. Tente novamente';
    }
  }

  /// Convert exceptions to user-friendly error messages for posts loading
  String _getPostsErrorMessage(dynamic error) {
    if (error is NetworkException) {
      return 'Verifique sua conexão com a internet';
    } else if (error is ServerException) {
      return 'Erro no servidor. Tente novamente mais tarde';
    } else if (error is NotFoundException) {
      return 'Nenhum post encontrado';
    } else if (error is TimeoutException) {
      return 'Tempo limite esgotado. Tente novamente';
    } else {
      return 'Erro ao carregar posts. Tente novamente';
    }
  }

  /// Validate community post input (client-side validation)
  void _validateCommunityPostInput(
    String title,
    String? description,
    List<Spot> selectedSpots,
  ) {
    final titleError = validateTitle(title);
    if (titleError != null) {
      throw ServerException(titleError);
    }

    final descriptionError = validateDescription(description);
    if (descriptionError != null) {
      throw ServerException(descriptionError);
    }

    final spotsError = validateSpotSelection(selectedSpots);
    if (spotsError != null) {
      throw ServerException(spotsError);
    }
  }

  // =============================================================================
  // UI HELPER METHODS
  // =============================================================================

  /// Get posts by type (for filtering in UI)
  List<Map<String, dynamic>> getPostsByType(String type) {
    return _allPosts.where((post) => post['type'] == type).toList();
  }

  /// Get posts by user (for profile screens)
  List<Map<String, dynamic>> getPostsByUser(int userId) {
    return _allPosts.where((post) => post['user_id'] == userId).toList();
  }

  /// Get recent posts (last 7 days)
  List<Map<String, dynamic>> getRecentPosts() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));

    return _allPosts.where((post) {
      final createdDate = DateTime.tryParse(post['created_date'] ?? '');
      return createdDate != null && createdDate.isAfter(weekAgo);
    }).toList();
  }

  /// Get total number of posts created by user
  int getUserPostCount(int userId) {
    return getPostsByUser(userId).length;
  }

  /// Check if user has created any posts
  bool hasUserCreatedPosts(int userId) {
    return getUserPostCount(userId) > 0;
  }

  /// Get character count for title (for real-time feedback)
  String getTitleCharacterCount(String title) {
    return PostConstants.getCharacterCountText(
      title.length,
      PostConstants.maxTitleLength,
    );
  }

  /// Get character count for description
  String getDescriptionCharacterCount(String? description) {
    final length = description?.length ?? 0;
    return PostConstants.getCharacterCountText(
      length,
      PostConstants.maxDescriptionLength,
    );
  }

  /// Get spots count text
  String getSpotsCountText(List<Spot> spots) {
    return PostConstants.getSpotsCountText(
      spots.length,
      PostConstants.maxSpotsPerPost,
    );
  }

  /// Check if more spots can be added
  bool canAddMoreSpots(List<Spot> currentSpots) {
    return PostConstants.canAddMoreSpots(currentSpots.length);
  }

  /// Get remaining spots that can be added
  int getRemainingSpots(List<Spot> currentSpots) {
    return PostConstants.getRemainingSpots(currentSpots.length);
  }

  // =============================================================================
  // SUCCESS STATE MANAGEMENT
  // =============================================================================

  /// Mark that the success state has been acknowledged (for navigation)
  void acknowledgePostCreation() {
    _lastCreatedPost = null;
    notifyListeners();
  }

  /// Check if we should show success message
  bool get shouldShowSuccessMessage => _lastCreatedPost != null;

  /// Get success message text
  String get successMessage => PostConstants.postCreatedSuccess;

  // =============================================================================
  // DEVELOPMENT AND DEBUGGING HELPERS
  // =============================================================================

  /// Get current state summary for debugging
  Map<String, dynamic> getStateDebugInfo() {
    return {
      'isCreatingPost': _isCreatingPost,
      'hasCreationError': hasCreationError,
      'creationErrorMessage': _creationErrorMessage,
      'isLoadingPosts': _isLoadingPosts,
      'hasPostsError': hasPostsError,
      'postsErrorMessage': _postsErrorMessage,
      'communityPostsCount': _communityPosts.length,
      'allPostsCount': _allPosts.length,
      'hasFreshCache': _hasFreshPostsData(),
      'lastUpdate': _lastPostsUpdate?.toIso8601String(),
      'lastCreatedPostId': _lastCreatedPost?.post_id,
    };
  }

  /// Reset all state (for testing or logout)
  void resetState() {
    _isCreatingPost = false;
    _creationErrorMessage = null;
    _lastCreatedPost = null;
    _communityPosts.clear();
    _allPosts.clear();
    _isLoadingPosts = false;
    _postsErrorMessage = null;
    _lastPostsUpdate = null;
    notifyListeners();
  }
}
