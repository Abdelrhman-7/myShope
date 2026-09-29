import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';

/// Centralized storage service for Supabase Storage.
/// Handles uploads to product-images, category-images, profile-images buckets.
class StorageService {
  final SupabaseClient _client = SupabaseConfig.client;

  // ─── Bucket names ──────────────────────────────────────────────
  static const String productImagesBucket = 'product-images';
  static const String categoryImagesBucket = 'category-images';
  static const String profileImagesBucket = 'profile-images';

  // ─── Upload ────────────────────────────────────────────────────

  /// Upload a file to a Supabase Storage bucket.
  /// Returns the public URL of the uploaded file.
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required Uint8List fileBytes,
    String? contentType,
  }) async {
    await _client.storage.from(bucket).uploadBinary(
          path,
          fileBytes,
          fileOptions: FileOptions(
            contentType: contentType ?? 'image/jpeg',
            upsert: true,
          ),
        );

    return _client.storage.from(bucket).getPublicUrl(path);
  }

  /// Upload a product image
  Future<String> uploadProductImage(
      String fileName, Uint8List fileBytes) async {
    return uploadFile(
      bucket: productImagesBucket,
      path: fileName,
      fileBytes: fileBytes,
    );
  }

  /// Upload a category image
  Future<String> uploadCategoryImage(
      String fileName, Uint8List fileBytes) async {
    return uploadFile(
      bucket: categoryImagesBucket,
      path: fileName,
      fileBytes: fileBytes,
    );
  }

  /// Upload a profile image
  Future<String> uploadProfileImage(
      String fileName, Uint8List fileBytes) async {
    return uploadFile(
      bucket: profileImagesBucket,
      path: fileName,
      fileBytes: fileBytes,
    );
  }

  // ─── Delete ────────────────────────────────────────────────────

  /// Delete a file from a bucket
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    await _client.storage.from(bucket).remove([path]);
  }

  // ─── URL ───────────────────────────────────────────────────────

  /// Get the public URL of a file
  String getPublicUrl(String bucket, String path) {
    return _client.storage.from(bucket).getPublicUrl(path);
  }
}

