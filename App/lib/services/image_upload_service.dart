import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import '../models/api_responses/upload_result.dart';
import '../models/core/image.dart' as models;
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/exceptions.dart';

/// Service for handling image uploads to Azure Blob Storage
///
/// This service manages the complete image upload workflow:
/// 1. Gets signed upload URLs from Azure Functions
/// 2. Uploads images directly to Azure Blob Storage
/// 3. Generates thumbnails for fast display
/// 4. Registers images in the database
/// 5. Links images to posts
class ImageUploadService {
  /// Singleton instance
  static final ImageUploadService _instance = ImageUploadService._internal();

  /// Factory constructor returns singleton
  factory ImageUploadService() => _instance;

  /// Private constructor
  ImageUploadService._internal();

  /// Dio client for blob uploads (with progress tracking)
  late final Dio _dioClient;

  /// API service for database operations
  ApiService get _apiService => ApiService();

  /// Initialize the service
  void initialize() {
    _dioClient = Dio();
    _dioClient.options.connectTimeout = const Duration(seconds: 30);
    _dioClient.options.sendTimeout = const Duration(minutes: 5);
    _dioClient.options.receiveTimeout = const Duration(minutes: 5);
  }

  // =============================================================================
  // SINGLE IMAGE UPLOAD
  // =============================================================================

  /// Uploads a single image with progress tracking
  ///
  /// Parameters:
  /// - [imageFile]: The image file to upload
  /// - [onProgress]: Optional callback for progress updates (0.0 to 1.0)
  ///
  /// Returns:
  /// - [UploadResult]: Complete upload result with registered image data
  Future<UploadResult> uploadSingleImage(
    File imageFile, {
    Function(double progress)? onProgress,
  }) async {
    var result = UploadResult.starting(imageFile);

    try {
      // Step 1: Get signed upload URL
      onProgress?.call(0.1);
      final uploadUrlData = await _getSignedUploadUrl(imageFile);
      result = result.withUploadUrl(uploadUrlData['uploadUrl']);

      // Step 2: Upload to blob storage
      onProgress?.call(0.2);
      await _uploadToBlob(
        imageFile: imageFile,
        uploadUrl: uploadUrlData['uploadUrl'],
        onProgress: (progress) {
          // Map blob upload progress to 20%-80% of total progress
          final totalProgress = 0.2 + (progress * 0.6);
          onProgress?.call(totalProgress);
        },
      );

      result = result.withBlobUrl(uploadUrlData['blobUrl']);

      // Step 3: Generate thumbnail
      onProgress?.call(0.8);
      final thumbnailUrl = await _generateThumbnail(
        imageFile,
        uploadUrlData['blobUrl'],
      );

      // Step 4: Register in database
      onProgress?.call(0.9);
      final registeredImage = await _registerImageInDatabase(
        imageName: uploadUrlData['fileName'],
        blobUrl: uploadUrlData['blobUrl'],
        thumbnailUrl: thumbnailUrl,
        contentType: lookupMimeType(imageFile.path),
        fileSize: await imageFile.length(),
      );

      result = result.withRegisteredImage(registeredImage);
      onProgress?.call(1.0);

      return result;
    } catch (e) {
      return result.withError('Upload failed: ${e.toString()}');
    }
  }

  // =============================================================================
  // BATCH UPLOAD
  // =============================================================================

  /// Uploads multiple images simultaneously with batch progress tracking
  ///
  /// Parameters:
  /// - [imageFiles]: List of image files to upload
  /// - [onBatchProgress]: Optional callback for overall progress (completed, total)
  /// - [onIndividualProgress]: Optional callback for individual file progress
  ///
  /// Returns:
  /// - [List<UploadResult>]: Results for each uploaded image
  Future<List<UploadResult>> uploadBatch(
    List<File> imageFiles, {
    Function(int completed, int total)? onBatchProgress,
    Function(int index, double progress)? onIndividualProgress,
  }) async {
    if (imageFiles.isEmpty) return [];

    final results = <UploadResult>[];
    int completed = 0;

    // Upload all images concurrently
    final futures = imageFiles.asMap().entries.map((entry) {
      final index = entry.key;
      final file = entry.value;

      return uploadSingleImage(
        file,
        onProgress: (progress) {
          onIndividualProgress?.call(index, progress);
        },
      ).then((result) {
        completed++;
        onBatchProgress?.call(completed, imageFiles.length);
        return result;
      });
    });

    // Wait for all uploads to complete
    final allResults = await Future.wait(futures);
    results.addAll(allResults);

    return results;
  }

  // =============================================================================
  // POST ASSOCIATION
  // =============================================================================

  /// Links uploaded images to a community post
  ///
  /// Parameters:
  /// - [postId]: ID of the post to link images to
  /// - [uploadResults]: Results from successful uploads
  /// - [thumbnailImageId]: Optional ID of image to use as thumbnail
  ///
  /// Returns:
  /// - [bool]: True if linking was successful
  Future<bool> linkImagesToPost(
    int postId,
    List<UploadResult> uploadResults, {
    int? thumbnailImageId,
  }) async {
    try {
      // Filter only successful uploads
      final successfulUploads =
          uploadResults.where((result) => result.isSuccessful).toList();

      if (successfulUploads.isEmpty) {
        throw ServerException('No successful uploads to link');
      }

      // Extract image IDs
      final imageIds =
          successfulUploads
              .map((result) => result.registeredImage!.image_id!)
              .toList();

      // Use first image as thumbnail if not specified
      final thumbnailId = thumbnailImageId ?? imageIds.first;

      // Make API call to link images
      final response = await _apiService.post(
        '${ApiConstants.postsEndpoint}/$postId/images',
        body: {'image_ids': imageIds, 'thumbnail_image_id': thumbnailId},
      );

      return response['success'] == true;
    } catch (e) {
      print('Error linking images to post: $e');
      return false;
    }
  }

  // =============================================================================
  // PRIVATE HELPER METHODS
  // =============================================================================

  /// Gets a signed upload URL from Azure Functions
  /// Add this enhanced logging to your ImageUploadService
  ///
  /// Replace your existing _getSignedUploadUrl method with this debug version:
  Future<Map<String, dynamic>> _getSignedUploadUrl(File imageFile) async {
    print('\n🔍 DEBUG: Getting signed upload URL...');

    try {
      final fileName = imageFile.path.split('/').last;
      final contentType = lookupMimeType(imageFile.path);
      final fileSize = await imageFile.length();

      print('📋 Request details:');
      print('   - fileName: $fileName');
      print('   - contentType: $contentType');
      print('   - fileSize: $fileSize bytes');
      print('   - endpoint: /images/upload-url');

      final response = await _apiService.post(
        '/images/upload-url',
        body: {
          'fileName': fileName,
          'contentType': contentType,
          'fileSize': fileSize,
        },
      );

      print('📥 API Response received:');
      print('   - Full response: $response');
      print('   - success: ${response['success']}');
      print('   - error: ${response['error']}');
      print('   - data: ${response['data']}');

      if (response['success'] != true || response['data'] == null) {
        final errorMsg = response['error'] ?? 'Unknown error';
        print('❌ Upload URL request failed: $errorMsg');
        throw ServerException('Failed to get upload URL: $errorMsg');
      }

      final data = response['data'];
      print('✅ Upload URL obtained successfully');
      print(
        '   - uploadUrl: ${data['uploadUrl']?.toString().substring(0, 100)}...',
      );
      print(
        '   - blobUrl: ${data['blobUrl']?.toString().substring(0, 100)}...',
      );

      return data;
    } catch (e) {
      print('❌ Exception in _getSignedUploadUrl: $e');
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException('Failed to get signed URL: ${e.toString()}');
    }
  }

  /// Also add this debug version of _uploadToBlob:
  Future<void> _uploadToBlob({
    required File imageFile,
    required String uploadUrl,
    Function(double progress)? onProgress,
  }) async {
    print('\n☁️ DEBUG: Starting blob upload...');

    try {
      final fileBytes = await imageFile.readAsBytes();
      final contentType =
          lookupMimeType(imageFile.path) ?? 'application/octet-stream';

      print('📋 Blob upload details:');
      print('   - File size: ${fileBytes.length} bytes');
      print('   - Content-Type: $contentType');
      print('   - Upload URL: ${uploadUrl.substring(0, 100)}...');

      final response = await _dioClient.put(
        uploadUrl,
        data: fileBytes,
        options: Options(
          headers: {'x-ms-blob-type': 'BlockBlob', 'Content-Type': contentType},
        ),
        onSendProgress: (sent, total) {
          if (total > 0) {
            final progress = sent / total;
            print(
              '📊 Upload progress: ${(progress * 100).toInt()}% ($sent/$total bytes)',
            );
            onProgress?.call(progress);
          }
        },
      );

      print('✅ Blob upload completed successfully');
      print('   - Status code: ${response.statusCode}');
      print('   - Headers: ${response.headers}');
    } catch (e) {
      print('❌ Exception in _uploadToBlob: $e');
      if (e is DioException) {
        print('📋 Dio error details:');
        print('   - Type: ${e.type}');
        print('   - Status code: ${e.response?.statusCode}');
        print('   - Response data: ${e.response?.data}');
        print('   - Request headers: ${e.requestOptions.headers}');
      }
      throw NetworkException('Blob upload failed: ${e.toString()}');
    }
  }

  /// Generates a thumbnail for the uploaded image
  Future<String?> _generateThumbnail(File originalFile, String blobUrl) async {
    try {
      // Read original image
      final imageBytes = await originalFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) return null;

      // Create thumbnail (max 300x300, maintain aspect ratio)
      final thumbnail = img.copyResize(
        originalImage,
        width: originalImage.width > originalImage.height ? 300 : null,
        height: originalImage.height > originalImage.width ? 300 : null,
      );

      // Encode as JPEG
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 85);

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final thumbnailFile = File(
        '${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await thumbnailFile.writeAsBytes(thumbnailBytes);

      // Upload thumbnail to blob storage
      final uploadUrlData = await _getSignedUploadUrl(thumbnailFile);
      await _uploadToBlob(
        imageFile: thumbnailFile,
        uploadUrl: uploadUrlData['uploadUrl'],
      );

      // Clean up temp file
      await thumbnailFile.delete();

      return uploadUrlData['blobUrl'];
    } catch (e) {
      print('Thumbnail generation failed: $e');
      return null; // Thumbnail is optional
    }
  }

  /// Registers the uploaded image in the database
  Future<models.Image> _registerImageInDatabase({
    required String imageName,
    required String blobUrl,
    String? thumbnailUrl,
    String? contentType,
    int? fileSize,
  }) async {
    print('\n💾 DEBUG: Registering image in database...');

    try {
      print('📋 Registration request:');
      print('   - imageName: $imageName');
      print('   - blobUrl: ${blobUrl.substring(0, 100)}...');
      print(
        '   - thumbnailUrl: ${thumbnailUrl?.substring(0, 100) ?? 'null'}...',
      );
      print('   - contentType: $contentType');
      print('   - fileSize: $fileSize');

      final response = await _apiService.post(
        '/images/register',
        body: {
          'image_name': imageName,
          'blob_url': blobUrl,
          'thumbnail_url': thumbnailUrl,
          'content_type': contentType,
          'file_size': fileSize,
        },
      );

      print('📥 Registration response received:');
      print('   - Full response: $response');
      print('   - success: ${response['success']}');
      print('   - error: ${response['error']}');

      if (response['success'] != true || response['data']?['image'] == null) {
        final errorMsg = response['error'] ?? 'Unknown database error';
        print('❌ Image registration failed: $errorMsg');
        throw ServerException(
          'Failed to register image in database: $errorMsg',
        );
      }

      final imageData = response['data']['image'];
      print('✅ Image registered successfully');
      print('   - Image ID: ${imageData['image_id']}');
      print('   - Created date: ${imageData['created_date']}');

      return models.Image.fromJson(imageData);
    } catch (e) {
      print('❌ Exception in _registerImageInDatabase: $e');
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException('Database registration failed: ${e.toString()}');
    }
  }
  // =============================================================================
  // UTILITY METHODS
  // =============================================================================

  /// Gets file size in human-readable format
  String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Validates if file is a supported image
  bool isValidImageFile(File file) {
    final mimeType = lookupMimeType(file.path);
    return mimeType != null && mimeType.startsWith('image/');
  }

  /// Gets maximum file size (10MB)
  int get maxFileSize => 10 * 1024 * 1024;
}
