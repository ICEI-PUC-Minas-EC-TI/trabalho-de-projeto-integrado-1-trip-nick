import 'dart:io';
import '../core/image.dart';

/// Represents the result of an image upload operation
///
/// This model tracks the complete lifecycle of an image upload from file selection
/// to final database registration, including progress tracking and error handling.
class UploadResult {
  final File sourceFile;
  final String? uploadUrl;
  final String? blobUrl;
  final Image? registeredImage;
  final UploadStatus status;
  final double progress;
  final String? errorMessage;
  final DateTime startTime;
  final DateTime? completionTime;

  const UploadResult({
    required this.sourceFile,
    this.uploadUrl,
    this.blobUrl,
    this.registeredImage,
    required this.status,
    this.progress = 0.0,
    this.errorMessage,
    required this.startTime,
    this.completionTime,
  });

  /// Creates initial upload result when upload starts
  factory UploadResult.starting(File file) {
    return UploadResult(
      sourceFile: file,
      status: UploadStatus.starting,
      startTime: DateTime.now(),
    );
  }

  /// Creates upload result for URL generation phase
  UploadResult withUploadUrl(String uploadUrl) {
    return copyWith(uploadUrl: uploadUrl, status: UploadStatus.uploading);
  }

  /// Creates upload result with progress update
  UploadResult withProgress(double progress) {
    return copyWith(
      progress: progress.clamp(0.0, 1.0),
      status:
          progress >= 1.0 ? UploadStatus.processing : UploadStatus.uploading,
    );
  }

  /// Creates upload result when blob upload completes
  UploadResult withBlobUrl(String blobUrl) {
    return copyWith(
      blobUrl: blobUrl,
      status: UploadStatus.processing,
      progress: 1.0,
    );
  }

  /// Creates upload result when registration completes
  UploadResult withRegisteredImage(Image image) {
    return copyWith(
      registeredImage: image,
      status: UploadStatus.completed,
      completionTime: DateTime.now(),
    );
  }

  /// Creates upload result for failed upload
  UploadResult withError(String error) {
    return copyWith(
      status: UploadStatus.failed,
      errorMessage: error,
      completionTime: DateTime.now(),
    );
  }

  /// Creates a copy of this result with updated fields
  UploadResult copyWith({
    File? sourceFile,
    String? uploadUrl,
    String? blobUrl,
    Image? registeredImage,
    UploadStatus? status,
    double? progress,
    String? errorMessage,
    DateTime? startTime,
    DateTime? completionTime,
  }) {
    return UploadResult(
      sourceFile: sourceFile ?? this.sourceFile,
      uploadUrl: uploadUrl ?? this.uploadUrl,
      blobUrl: blobUrl ?? this.blobUrl,
      registeredImage: registeredImage ?? this.registeredImage,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      startTime: startTime ?? this.startTime,
      completionTime: completionTime ?? this.completionTime,
    );
  }

  /// Gets the filename from the source file
  String get fileName => sourceFile.path.split('/').last;

  /// Gets the upload duration if completed
  Duration? get uploadDuration {
    if (completionTime == null) return null;
    return completionTime!.difference(startTime);
  }

  /// Checks if upload was successful
  bool get isSuccessful =>
      status == UploadStatus.completed && registeredImage != null;

  /// Checks if upload failed
  bool get isFailed => status == UploadStatus.failed;

  /// Checks if upload is in progress
  bool get isInProgress =>
      status == UploadStatus.uploading || status == UploadStatus.processing;

  /// Gets a human-readable status message
  String get statusMessage {
    switch (status) {
      case UploadStatus.starting:
        return 'Preparando upload...';
      case UploadStatus.uploading:
        return 'Enviando... ${(progress * 100).toInt()}%';
      case UploadStatus.processing:
        return 'Processando imagem...';
      case UploadStatus.completed:
        return 'Upload concluído';
      case UploadStatus.failed:
        return 'Falha no upload: ${errorMessage ?? 'Erro desconhecido'}';
    }
  }

  @override
  String toString() {
    return 'UploadResult($fileName: $status, ${(progress * 100).toInt()}%)';
  }
}

/// Enum representing the different stages of an upload
enum UploadStatus {
  starting, // Upload is being prepared
  uploading, // File is being uploaded to blob storage
  processing, // File uploaded, being processed/registered
  completed, // Upload and registration completed successfully
  failed, // Upload failed at some stage
}
