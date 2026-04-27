// lib/widgets/scan_result_card.dart

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/scan_result.dart';
import '../services/storage_service.dart';

class ScanResultCard extends StatefulWidget {
  final ScanResult scanResult;
  final StorageService storageService;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const ScanResultCard({
    super.key,
    required this.scanResult,
    required this.storageService,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  State<ScanResultCard> createState() => _ScanResultCardState();
}

class _ScanResultCardState extends State<ScanResultCard> {
  String? _base64;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    // If the model already carries an image (e.g. just saved), use it.
    if (widget.scanResult.imageBase64 != null &&
        widget.scanResult.imageBase64!.isNotEmpty) {
      setState(() {
        _base64 = widget.scanResult.imageBase64;
        _loading = false;
      });
      return;
    }

    // Otherwise lazy-load from Firestore (with in-memory cache).
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final base64 = await widget.storageService.getImageBase64(
      uid,
      widget.scanResult.firestoreDocId,
    );

    if (mounted) {
      setState(() {
        _base64 = base64;
        _loading = false;
      });
    }
  }

  Color get _categoryColor {
    switch (widget.scanResult.category) {
      case 'Organik':
        return const Color(0xFF4CAF50);
      case 'Anorganik':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData get _categoryIcon {
    switch (widget.scanResult.category) {
      case 'Organik':
        return Icons.eco_rounded;
      case 'Anorganik':
        return Icons.recycling_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  /// Builds the image widget from the Base64 string cached in the model,
  /// or shows a placeholder icon if no image is available.
  Widget _buildImage() {
    if (_loading) {
      return Container(
        width: 100,
        height: 100,
        color: const Color(0xFF2A3240),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF5A6478),
            ),
          ),
        ),
      );
    }

    if (_base64 != null && _base64!.isNotEmpty) {
      try {
        final bytes = base64Decode(_base64!);
        return Image.memory(
          bytes,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          // Avoid decoding full-res — tell Flutter to limit decode size
          cacheWidth: 200,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      } catch (_) {
        return _placeholder();
      }
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 100,
      height: 100,
      color: const Color(0xFF2A3240),
      child: const Icon(Icons.image_rounded, color: Color(0xFF5A6478), size: 32),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2530),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Image (lazy-loaded Base64) ──────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
              child: _buildImage(),
            ),

            // ── Info ───────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _categoryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _categoryColor.withOpacity(0.4), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_categoryIcon,
                              color: _categoryColor, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            widget.scanResult.category,
                            style: TextStyle(
                              color: _categoryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Label
                    Text(
                      widget.scanResult.detectedLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Date
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm')
                          .format(widget.scanResult.createdAt.toLocal()),
                      style: const TextStyle(
                        color: Color(0xFF8B95A8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Action buttons ──────────────────────────────────────────────
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.onEdit != null)
                  IconButton(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit_outlined,
                        color: Color(0xFF64B5F6), size: 20),
                    tooltip: 'Edit',
                    constraints: const BoxConstraints(
                        minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.all(6),
                  ),
                if (widget.onDelete != null)
                  IconButton(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFEF5350), size: 20),
                    tooltip: 'Hapus',
                    constraints: const BoxConstraints(
                        minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.all(6),
                  ),
              ],
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
