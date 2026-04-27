// lib/services/ml_kit_service.dart

import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class MlKitService {
  // ─── Category Mapping ──────────────────────────────────────────────────────

  /// Keywords that map to each category (all lowercase)
  static const Map<String, List<String>> _categoryKeywords = {
    'Organik': [
      'food',
      'fruit',
      'vegetable',
      'plant',
      'banana',
      'apple',
      'orange',
      'mango',
      'grape',
      'leaf',
      'flower',
      'tree',
      'organic',
      'salad',
      'bread',
      'rice',
      'meat',
      'fish',
      'egg',
      'cheese',
    ],
    'Anorganik': [
      'plastic',
      'bottle',
      'container',
      'can',
      'jug',
      'aluminum',
      'tin',
      'glass',
      'jar',
      'paper',
      'cardboard',
      'newspaper',
      'book',
      'box',
      'packaging',
      'wrapper',
      'bag',
      'rubber',
      'metal',
      'iron',
      'steel',
    ],
  };

  /// Maps an ML Kit label string to a waste category.
  ///
  /// Returns 'Organik', 'Anorganik', or 'Tidak Diketahui'.
  String mapToCategory(String label) {
    final lowerLabel = label.toLowerCase();

    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerLabel.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return 'Tidak Diketahui';
  }

  // ─── Image Labeling ────────────────────────────────────────────────────────

  /// Analyzes [imageFile] using Google ML Kit Image Labeling.
  ///
  /// Returns a [LabelResult] containing the top label string and the
  /// corresponding waste category.
  ///
  /// Throws [Exception] if no labels are detected.
  Future<LabelResult> labelImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);

    final options = ImageLabelerOptions(confidenceThreshold: 0.5);
    final labeler = ImageLabeler(options: options);

    try {
      final List<ImageLabel> labels = await labeler.processImage(inputImage);

      if (labels.isEmpty) {
        throw Exception('No objects detected in the image. Try a clearer photo.');
      }

      // Sort by confidence descending and pick the top label
      labels.sort((a, b) => b.confidence.compareTo(a.confidence));
      final topLabel = labels.first;

      final category = mapToCategory(topLabel.label);

      return LabelResult(
        label: topLabel.label,
        confidence: topLabel.confidence,
        category: category,
        allLabels: labels
            .map((l) => DetectedLabel(label: l.label, confidence: l.confidence))
            .toList(),
      );
    } finally {
      labeler.close();
    }
  }
}

// ─── Data classes ──────────────────────────────────────────────────────────────

class LabelResult {
  final String label;
  final double confidence;
  final String category;
  final List<DetectedLabel> allLabels;

  const LabelResult({
    required this.label,
    required this.confidence,
    required this.category,
    required this.allLabels,
  });
}

class DetectedLabel {
  final String label;
  final double confidence;

  const DetectedLabel({required this.label, required this.confidence});
}
