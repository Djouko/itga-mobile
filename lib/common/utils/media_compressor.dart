import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:video_compress/video_compress.dart';

/// Centralized media compression utility.
///
/// Mirrors what Instagram, WhatsApp, Twitter, and Telegram do:
/// - Images  → WebP format, resize to max dimension, quality 80%
/// - Videos  → H.264 re-encode at 720p, medium quality
/// - Profile → WebP, smaller dimension (400px), quality 75%
/// - Thumb   → WebP, tiny dimension (300px), quality 70%
///
/// This saves bandwidth, reduces server storage, and speeds up
/// both upload and download for every user.
class MediaCompressor {
  MediaCompressor._();
  static final shared = MediaCompressor._();

  // ──────────────────────────────────────────────
  // IMAGE COMPRESSION  (Instagram / WhatsApp style)
  // ──────────────────────────────────────────────

  /// Compress a post/story/chat image → WebP, max 1080px, quality 80.
  Future<XFile> compressImage(XFile file, {
    int maxDimension = 1080,
    int quality = 80,
  }) async {
    return _compressImageInternal(
      file,
      maxDimension: maxDimension,
      quality: quality,
      tag: 'image',
    );
  }

  /// Compress a profile picture → WebP, max 400px, quality 75.
  Future<XFile> compressProfileImage(XFile file) async {
    return _compressImageInternal(
      file,
      maxDimension: 400,
      quality: 75,
      tag: 'profile',
    );
  }

  /// Compress a thumbnail → WebP, max 300px, quality 70.
  Future<XFile> compressThumbnail(XFile file) async {
    return _compressImageInternal(
      file,
      maxDimension: 300,
      quality: 70,
      tag: 'thumbnail',
    );
  }

  Future<XFile> _compressImageInternal(XFile file, {
    required int maxDimension,
    required int quality,
    required String tag,
  }) async {
    try {
      final originalSize = await File(file.path).length();

      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/compressed_${tag}_${DateTime.now().millisecondsSinceEpoch}.webp';

      final Uint8List? result = await FlutterImageCompress.compressWithFile(
        file.path,
        minWidth: maxDimension,
        minHeight: maxDimension,
        quality: quality,
        format: CompressFormat.webp,
        autoCorrectionAngle: true,
        keepExif: false, // Strip EXIF — saves space + privacy (WhatsApp does this)
      );

      if (result == null || result.isEmpty) {
        Loggers.warning('MediaCompressor: $tag compression returned null, using original');
        return file;
      }

      final compressedFile = File(targetPath)..writeAsBytesSync(result);
      final compressedSize = compressedFile.lengthSync();
      final ratio = ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1);

      Loggers.info('📦 MediaCompressor [$tag]: ${_formatBytes(originalSize)} → ${_formatBytes(compressedSize)} (-$ratio%)');

      return XFile(targetPath);
    } catch (e) {
      Loggers.error('MediaCompressor: $tag compression failed: $e');
      return file; // Fallback to original
    }
  }

  // ──────────────────────────────────────────────
  // VIDEO COMPRESSION  (TikTok / Instagram style)
  // ──────────────────────────────────────────────

  /// Compress a video → H.264, 720p, medium quality.
  /// Returns compressed XFile, or original if compression fails.
  Future<XFile> compressVideo(XFile file, {
    VideoQuality videoQuality = VideoQuality.MediumQuality,
  }) async {
    try {
      final originalSize = await File(file.path).length();

      final info = await VideoCompress.compressVideo(
        file.path,
        quality: videoQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (info == null || info.file == null) {
        Loggers.warning('MediaCompressor: video compression returned null, using original');
        return file;
      }

      final compressedSize = info.filesize ?? 0;
      final ratio = originalSize > 0
          ? ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1)
          : '0';

      Loggers.info('📦 MediaCompressor [video]: ${_formatBytes(originalSize)} → ${_formatBytes(compressedSize)} (-$ratio%)');

      return XFile(info.file!.path);
    } catch (e) {
      Loggers.error('MediaCompressor: video compression failed: $e');
      return file; // Fallback to original
    }
  }

  /// Cancel any in-progress video compression.
  Future<void> cancelVideoCompression() async {
    await VideoCompress.cancelCompression();
  }

  // ──────────────────────────────────────────────
  // BATCH OPERATIONS
  // ──────────────────────────────────────────────

  /// Compress multiple images in parallel (for multi-image posts).
  Future<List<XFile>> compressImages(List<XFile> files, {
    int maxDimension = 1080,
    int quality = 80,
  }) async {
    final futures = files.map((f) => compressImage(f, maxDimension: maxDimension, quality: quality));
    return Future.wait(futures);
  }

  // ──────────────────────────────────────────────
  // CLEANUP
  // ──────────────────────────────────────────────

  /// Remove old compressed temp files (call periodically).
  Future<void> cleanupTempFiles() async {
    try {
      final dir = await getTemporaryDirectory();
      final files = dir.listSync().whereType<File>().where(
        (f) => f.path.contains('compressed_'),
      );
      int count = 0;
      for (final f in files) {
        final age = DateTime.now().difference(f.lastModifiedSync());
        if (age.inHours > 24) {
          f.deleteSync();
          count++;
        }
      }
      if (count > 0) {
        Loggers.info('🧹 MediaCompressor: cleaned up $count old temp files');
      }
    } catch (_) {}
  }

  // ──────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
