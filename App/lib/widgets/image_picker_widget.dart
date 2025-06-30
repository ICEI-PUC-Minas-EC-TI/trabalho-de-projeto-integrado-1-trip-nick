import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design_system/colors/ui_colors.dart';
import '../design_system/colors/color_aliases.dart';
import '../providers/posts_provider.dart';

/// Widget for selecting images for community posts
///
/// This widget provides options to:
/// - Select multiple images from gallery
/// - Take photos with camera
/// - Preview selected images
/// - Remove selected images
/// - Show upload progress
class ImagePickerWidget extends StatelessWidget {
  /// Maximum number of images that can be selected
  final int maxImages;

  /// Whether to show upload progress
  final bool showProgress;

  /// Callback when images are selected/changed
  final VoidCallback? onImagesChanged;

  const ImagePickerWidget({
    Key? key,
    this.maxImages = 10,
    this.showProgress = true,
    this.onImagesChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PostsProvider>(
      builder: (context, postsProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with image count
            _buildHeader(context, postsProvider),

            const SizedBox(height: 16),

            // Image selection buttons
            if (postsProvider.selectedImages.length < maxImages)
              _buildSelectionButtons(context, postsProvider),

            const SizedBox(height: 16),

            // Selected images preview
            if (postsProvider.selectedImages.isNotEmpty)
              _buildImagePreview(context, postsProvider),

            // Upload progress
            if (showProgress && postsProvider.isUploadingImages)
              _buildUploadProgress(context, postsProvider),

            // Upload status
            if (postsProvider.uploadResults.isNotEmpty)
              _buildUploadStatus(context, postsProvider),

            // Error message
            if (postsProvider.hasUploadError)
              _buildErrorMessage(context, postsProvider),
          ],
        );
      },
    );
  }

  /// Builds the header section with image count
  Widget _buildHeader(BuildContext context, PostsProvider postsProvider) {
    final selectedCount = postsProvider.selectedImages.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Imagens do Post',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              selectedCount == 0
                  ? 'Adicione imagens ao seu post (opcional)'
                  : '$selectedCount/$maxImages imagens selecionadas',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: UIColors.textAction),
            ),
          ],
        ),

        // Clear all button
        if (selectedCount > 0)
          TextButton.icon(
            onPressed: () {
              postsProvider.clearSelectedImages();
              onImagesChanged?.call();
            },
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Limpar'),
            style: TextButton.styleFrom(
              foregroundColor: UIColors.textAction,
              textStyle: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  /// Builds the image selection buttons
  Widget _buildSelectionButtons(
    BuildContext context,
    PostsProvider postsProvider,
  ) {
    return Row(
      children: [
        // Gallery button
        Expanded(
          child: OutlinedButton.icon(
            onPressed:
                postsProvider.isUploadingImages
                    ? null
                    : () async {
                      await postsProvider.selectImagesFromGallery();
                      onImagesChanged?.call();
                    },
            icon: const Icon(Icons.photo_library),
            label: const Text('Galeria'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Camera button
        Expanded(
          child: OutlinedButton.icon(
            onPressed:
                postsProvider.isUploadingImages
                    ? null
                    : () async {
                      await postsProvider.takePhotoWithCamera();
                      onImagesChanged?.call();
                    },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Câmera'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the image preview grid
  Widget _buildImagePreview(BuildContext context, PostsProvider postsProvider) {
    final images = postsProvider.selectedImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Imagens Selecionadas',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 12),

        // Image grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            return _buildImageTile(context, postsProvider, index);
          },
        ),
      ],
    );
  }

  /// Builds individual image tile with preview and remove button
  Widget _buildImageTile(
    BuildContext context,
    PostsProvider postsProvider,
    int index,
  ) {
    final image = postsProvider.selectedImages[index];
    final isUploading = postsProvider.isUploadingImages;
    final uploadProgress = postsProvider.uploadProgress[index] ?? 0.0;
    final hasUploadResult = index < postsProvider.uploadResults.length;
    final isUploadSuccessful =
        hasUploadResult && postsProvider.isImageUploadSuccessful(index);

    return Stack(
      children: [
        // Image preview
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isUploadSuccessful
                      ? Colors.green
                      : ColorAliases.primaryDefault.withOpacity(0.3),
              width: isUploadSuccessful ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.file(
              image,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),

        // Upload progress overlay
        if (isUploading && uploadProgress < 1.0)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.black54,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      value: uploadProgress,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(uploadProgress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Success indicator
        if (isUploadSuccessful)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 12),
            ),
          ),

        // Remove button
        if (!isUploading)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                postsProvider.removeSelectedImage(index);
                onImagesChanged?.call();
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),

        // File size indicator
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              postsProvider.getSelectedImageSize(index),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds upload progress indicator
  Widget _buildUploadProgress(
    BuildContext context,
    PostsProvider postsProvider,
  ) {
    final progress = postsProvider.batchUploadProgress;
    final uploadedCount = postsProvider.successfulUploads;
    final totalCount = postsProvider.selectedImages.length;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorAliases.primaryDefault.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorAliases.primaryDefault.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enviando Imagens...',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '$uploadedCount/$totalCount',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: UIColors.textAction),
              ),
            ],
          ),

          const SizedBox(height: 8),

          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              ColorAliases.primaryDefault,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds upload status message
  Widget _buildUploadStatus(BuildContext context, PostsProvider postsProvider) {
    final statusMessage = postsProvider.getUploadStatusMessage();
    if (statusMessage.isEmpty) return const SizedBox.shrink();

    final hasFailures = postsProvider.failedUploads > 0;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            hasFailures
                ? Colors.orange.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              hasFailures
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasFailures ? Icons.warning : Icons.check_circle,
            color: hasFailures ? Colors.orange : Colors.green,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusMessage,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: hasFailures ? Colors.orange[800] : Colors.green[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Retry button for failures
          if (hasFailures)
            TextButton(
              onPressed:
                  postsProvider.isUploadingImages
                      ? null
                      : () {
                        postsProvider.retryFailedUploads();
                      },
              child: const Text('Tentar Novamente'),
            ),
        ],
      ),
    );
  }

  /// Builds error message display
  Widget _buildErrorMessage(BuildContext context, PostsProvider postsProvider) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              postsProvider.uploadErrorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.red[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
