// lib/services/storage_service.dart
// Saves scan images to Firestore as Base64-encoded strings.
// This replaces Firebase Storage with Cloud Firestore to avoid Storage billing setup.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class StorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// In-memory cache: "uid/docId" → base64 string.
  /// Avoids re-fetching the same image from Firestore on every rebuild.
  static final Map<String, String> _imageCache = {};

  // ─── Upload ──────────────────────────────────────────────────────────────────

  /// Compresses [imageFile] to a small JPEG thumbnail (max 300 px, quality 40)
  /// using native code via flutter_image_compress (safe on all physical devices),
  /// encodes as Base64, and saves to Firestore under:
  ///   `scan_images/{uid}/{docId}`
  ///
  /// Returns the Firestore document ID (used as a reference in the backend).
  Future<String> uploadScanImage(File imageFile) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    // Compress image using native code — safe on all Android/iOS physical devices.
    final compressedBytes = await _compressForStorage(imageFile);
    final base64Image = base64Encode(compressedBytes);

    // Save to Firestore
    final docRef = await _firestore
        .collection('scan_images')
        .doc(uid)
        .collection('scans')
        .add({
      'image_base64': base64Image,
      'created_at': FieldValue.serverTimestamp(),
    });

    // Warm the local cache so history page doesn't need to re-fetch.
    _imageCache['$uid/${docRef.id}'] = base64Image;

    return docRef.id;
  }

  // ─── Read ────────────────────────────────────────────────────────────────────

  /// Fetches the Base64 image string from Firestore for [uid] and [docId].
  /// Returns a cached value if available. Returns null if not found or on error.
  Future<String?> getImageBase64(String uid, String docId) async {
    final cacheKey = '$uid/$docId';

    // 1. Check in-memory cache first
    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey];
    }

    // 2. Fetch from Firestore
    try {
      final snap = await _firestore
          .collection('scan_images')
          .doc(uid)
          .collection('scans')
          .doc(docId)
          .get();

      if (!snap.exists) return null;
      final base64 = snap.data()?['image_base64'] as String?;

      if (base64 != null) {
        _imageCache[cacheKey] = base64;
      }
      return base64;
    } catch (_) {
      return null;
    }
  }

  // ─── Delete ──────────────────────────────────────────────────────────────────

  /// Deletes the Firestore document for [uid]/[docId].
  Future<void> deleteImage(String uid, String docId) async {
    try {
      await _firestore
          .collection('scan_images')
          .doc(uid)
          .collection('scans')
          .doc(docId)
          .delete();

      _imageCache.remove('$uid/$docId');
    } catch (_) {
      // Non-critical — ignore if already deleted
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// Compresses the image using flutter_image_compress (native JPEG encoder).
  /// Resizes to max 300 × 300 px at quality 40.
  /// Result: typically 10–50 KB instead of 500 KB–2 MB.
  /// Falls back to original bytes if compression fails.
  Future<Uint8List> _compressForStorage(File imageFile) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: 300,
        minHeight: 300,
        quality: 40,
        format: CompressFormat.jpeg,
      );

      if (result != null && result.isNotEmpty) {
        return result;
      }
    } catch (_) {
      // Fall through to raw bytes if compression fails
    }

    // Fallback: use original bytes (still works, just larger payload)
    return await imageFile.readAsBytes();
  }
}
