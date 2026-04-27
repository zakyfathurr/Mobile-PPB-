// lib/screens/scanner_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../services/camera_service.dart';
import '../services/ml_kit_service.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/custom_button.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final _cameraService = CameraService();
  final _mlKitService = MlKitService();
  final _storageService = StorageService();
  final _apiService = ApiService();
  final _notificationService = NotificationService();

  File? _selectedImage;
  LabelResult? _labelResult;

  /// User-overridden category (null = use AI result).
  String? _overriddenCategory;

  bool _isAnalyzing = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool _savedSuccessfully = false;

  late AnimationController _resultAnimController;
  late Animation<Offset> _resultSlideAnim;

  @override
  void initState() {
    super.initState();
    _resultAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _resultSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _resultAnimController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _resultAnimController.dispose();
    super.dispose();
  }

  /// The effective category — either user override or AI result.
  String get _effectiveCategory =>
      _overriddenCategory ?? _labelResult?.category ?? 'Tidak Diketahui';

  /// Whether the AI confidence is below the threshold (70%).
  bool get _isLowConfidence =>
      _labelResult != null && _labelResult!.confidence < 0.70;

  // ─── Image Capture ──────────────────────────────────────────────────────────

  Future<void> _captureImage(ImageSourceType source) async {
    setState(() {
      _errorMessage = null;
      _labelResult = null;
      _overriddenCategory = null;
      _savedSuccessfully = false;
    });

    File? image;
    if (source == ImageSourceType.camera) {
      image = await _cameraService.captureFromCamera();
    } else {
      image = await _cameraService.pickFromGallery();
    }

    if (image == null) return;

    setState(() {
      _selectedImage = image;
      _isAnalyzing = true;
    });

    await _analyzeImage(image);
  }

  // ─── ML Kit Analysis ────────────────────────────────────────────────────────

  Future<void> _analyzeImage(File image) async {
    try {
      final result = await _mlKitService.labelImage(image);
      setState(() {
        _labelResult = result;
        _isAnalyzing = false;
      });
      _resultAnimController.forward(from: 0);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isAnalyzing = false;
      });
    }
  }

  // ─── Save Scan ──────────────────────────────────────────────────────────────

  Future<void> _saveScan() async {
    if (_selectedImage == null || _labelResult == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // 1. Upload image as Base64 to Firestore → get doc ID
      final firestoreDocId =
          await _storageService.uploadScanImage(_selectedImage!);

      // 2. Save to backend API (pass Firestore doc ID as image_url)
      //    Use the effective category (which may have been user-overridden)
      await _apiService.saveScan(
        imageUrl: firestoreDocId,
        detectedLabel: _labelResult!.label,
        category: _effectiveCategory,
      );

      // 3. Show local notification
      await _notificationService.showScanSuccessNotification(
        label: _labelResult!.label,
        category: _effectiveCategory,
      );

      setState(() {
        _savedSuccessfully = true;
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Gagal menyimpan: ${e.toString().replaceAll('Exception: ', '')}';
        _isSaving = false;
      });
    }
  }

  // ─── UI ─────────────────────────────────────────────────────────────────────

  Color _categoryColorFor(String category) => switch (category) {
        'Organik' => const Color(0xFF4CAF50),
        'Anorganik' => const Color(0xFF2196F3),
        _ => const Color(0xFF9E9E9E),
      };

  IconData _categoryIconFor(String category) => switch (category) {
        'Organik' => Icons.eco_rounded,
        'Anorganik' => Icons.recycling_rounded,
        _ => Icons.help_outline_rounded,
      };

  Color get _categoryColor => _categoryColorFor(_effectiveCategory);
  IconData get _categoryIcon => _categoryIconFor(_effectiveCategory);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1923),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan Sampah',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ── Image preview ───────────────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2530),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _selectedImage != null
                        ? _categoryColor.withOpacity(0.4)
                        : const Color(0xFF2A3240),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: _buildImagePreview(),
                ),
              ),

              const SizedBox(height: 20),

              // ── Capture buttons ─────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: 'Kamera',
                      icon: Icons.camera_alt_rounded,
                      onPressed: _isAnalyzing || _isSaving
                          ? null
                          : () => _captureImage(ImageSourceType.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      label: 'Galeri',
                      icon: Icons.photo_library_rounded,
                      variant: ButtonVariant.secondary,
                      onPressed: _isAnalyzing || _isSaving
                          ? null
                          : () => _captureImage(ImageSourceType.gallery),
                    ),
                  ),
                ],
              ),

              // ── Analysis result ─────────────────────────────────────────
              if (_isAnalyzing) ...[
                const SizedBox(height: 32),
                const CircularProgressIndicator(color: Color(0xFF4CAF50)),
                const SizedBox(height: 12),
                const Text('Menganalisis gambar...',
                    style: TextStyle(color: Color(0xFF8B95A8), fontSize: 14)),
              ],

              if (_labelResult != null) ...[
                const SizedBox(height: 24),
                SlideTransition(
                  position: _resultSlideAnim,
                  child: FadeTransition(
                    opacity: _resultAnimController,
                    child: _buildResultCard(),
                  ),
                ),
              ],

              // ── Error ───────────────────────────────────────────────────
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF5350).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFEF5350).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFEF5350), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_errorMessage!,
                            style: const TextStyle(
                                color: Color(0xFFEF5350), fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Success ─────────────────────────────────────────────────
              if (_savedSuccessfully) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF4CAF50).withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          color: Color(0xFF4CAF50), size: 20),
                      SizedBox(width: 10),
                      Text('Scan berhasil disimpan! 🎉',
                          style:
                              TextStyle(color: Color(0xFF4CAF50), fontSize: 13)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_isAnalyzing && _selectedImage != null) {
      return Stack(
        children: [
          Image.file(_selectedImage!, fit: BoxFit.cover,
              width: double.infinity, height: 300),
          Container(color: Colors.black45),
          const Center(
            child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
          ),
        ],
      );
    }

    if (_selectedImage != null) {
      return Image.file(_selectedImage!,
          fit: BoxFit.cover, width: double.infinity, height: 300);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_rounded,
            color: const Color(0xFF5A6478).withOpacity(0.5), size: 60),
        const SizedBox(height: 16),
        Text(
          'Ambil atau pilih gambar\nuntuk dianalisis',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    final result = _labelResult!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2530),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _categoryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _categoryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_categoryIcon, color: _categoryColor, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${(result.confidence * 100).toStringAsFixed(1)}% confidence',
                      style: TextStyle(
                        color: _isLowConfidence
                            ? const Color(0xFFFF9800)
                            : const Color(0xFF8B95A8),
                        fontSize: 12,
                        fontWeight: _isLowConfidence
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Low confidence warning ──────────────────────────────────────
          if (_isLowConfidence && !_savedSuccessfully) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFF9800).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFFF9800), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Confidence rendah — periksa dan ubah kategori di bawah jika perlu.',
                      style: TextStyle(
                          color: Color(0xFFFF9800), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── Category selector (editable) ──────────────────────────────────
          if (!_savedSuccessfully) ...[
            const Text('Kategori:',
                style: TextStyle(color: Color(0xFF8B95A8), fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildCategoryChip('Organik'),
                const SizedBox(width: 10),
                _buildCategoryChip('Anorganik'),
              ],
            ),
            if (_overriddenCategory != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _overriddenCategory = null),
                child: const Text(
                  '↩ Kembali ke hasil AI',
                  style: TextStyle(
                    color: Color(0xFF8B95A8),
                    fontSize: 11,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ] else ...[
            // Show the final saved category (non-editable)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: _categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Kategori: ',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 14),
                  ),
                  Text(
                    _effectiveCategory,
                    style: TextStyle(
                      color: _categoryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Other labels
          if (result.allLabels.length > 1) ...[
            const SizedBox(height: 14),
            const Text('Label lain:',
                style: TextStyle(color: Color(0xFF8B95A8), fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: result.allLabels
                  .skip(1)
                  .take(5)
                  .map(
                    (l) => Chip(
                      label: Text(
                        '${l.label} ${(l.confidence * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: Color(0xFF8B95A8), fontSize: 11),
                      ),
                      backgroundColor: const Color(0xFF2A3240),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
            ),
          ],

          const SizedBox(height: 20),

          if (!_savedSuccessfully)
            CustomButton(
              label: _isSaving ? 'Menyimpan...' : 'Simpan Hasil Scan',
              icon: Icons.save_alt_rounded,
              isLoading: _isSaving,
              onPressed: _saveScan,
            ),
        ],
      ),
    );
  }

  /// Builds a selectable category chip.
  Widget _buildCategoryChip(String category) {
    final isSelected = _effectiveCategory == category;
    final color = _categoryColorFor(category);
    final icon = _categoryIconFor(category);

    return Expanded(
      child: GestureDetector(
        onTap: _isSaving
            ? null
            : () {
                setState(() {
                  // If tapping the same as AI result, clear override
                  if (category == _labelResult?.category) {
                    _overriddenCategory = null;
                  } else {
                    _overriddenCategory = category;
                  }
                });
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : const Color(0xFF2A3240),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color.withOpacity(0.5) : const Color(0xFF3A4450),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : const Color(0xFF8B95A8), size: 20),
              const SizedBox(width: 8),
              Text(
                category,
                style: TextStyle(
                  color: isSelected ? color : const Color(0xFF8B95A8),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum ImageSourceType { camera, gallery }
