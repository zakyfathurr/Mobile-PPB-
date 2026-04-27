// lib/models/scan_result.dart

class ScanResult {
  final int? id;
  final String userId;

  /// Firestore document ID pointing to the Base64 image in scan_images/{uid}/scans/{docId}.
  /// This is what gets stored in the backend instead of a Storage URL.
  final String firestoreDocId;

  /// In-memory Base64 string — populated after fetching from Firestore.
  /// Not persisted in the backend DB.
  final String? imageBase64;

  final String detectedLabel;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ScanResult({
    this.id,
    required this.userId,
    required this.firestoreDocId,
    this.imageBase64,
    required this.detectedLabel,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id'] as int?,
      userId: json['user_id'] as String,
      // Backend stores the Firestore doc ID in the image_url column
      firestoreDocId: json['image_url'] as String,
      detectedLabel: json['detected_label'] as String,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'image_url': firestoreDocId,
      'detected_label': detectedLabel,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ScanResult copyWith({
    int? id,
    String? userId,
    String? firestoreDocId,
    String? imageBase64,
    String? detectedLabel,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScanResult(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firestoreDocId: firestoreDocId ?? this.firestoreDocId,
      imageBase64: imageBase64 ?? this.imageBase64,
      detectedLabel: detectedLabel ?? this.detectedLabel,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
