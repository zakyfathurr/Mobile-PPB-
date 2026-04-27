// lib/screens/history_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/scan_result.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/scan_result_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _apiService = ApiService();
  final _storageService = StorageService();

  List<ScanResult> _scans = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadScans();
  }

  Future<void> _loadScans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Only fetch the scan metadata from the backend.
      // Images are lazy-loaded per card, not pre-fetched in bulk.
      final scans = await _apiService.getScans();

      setState(() {
        _scans = scans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Gagal memuat riwayat: ${e.toString().replaceAll('Exception: ', '')}';
        _isLoading = false;
      });
    }
  }

  // ─── Edit Scan ──────────────────────────────────────────────────────────────

  Future<void> _editScan(ScanResult scan) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditScanSheet(scan: scan),
    );

    if (result == null || scan.id == null) return;

    try {
      final updated = await _apiService.updateScan(
        id: scan.id!,
        detectedLabel: result['label'],
        category: result['category'],
      );

      setState(() {
        final index = _scans.indexWhere((s) => s.id == scan.id);
        if (index != -1) {
          _scans[index] = updated.copyWith(imageBase64: scan.imageBase64);
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Scan berhasil diperbarui ✅'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Gagal memperbarui: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: const Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─── Delete Scan ────────────────────────────────────────────────────────────

  Future<void> _deleteScan(ScanResult scan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E2530),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hapus Scan?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'Scan "${scan.detectedLabel}" akan dihapus permanen.',
          style: const TextStyle(color: Color(0xFF8B95A8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal',
                style: TextStyle(color: Color(0xFF8B95A8))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus',
                style: TextStyle(
                    color: Color(0xFFEF5350), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true || scan.id == null) return;

    try {
      // Delete from backend API
      await _apiService.deleteScan(scan.id!);

      // Also delete image from Firestore
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await _storageService.deleteImage(uid, scan.firestoreDocId);

      setState(() => _scans.removeWhere((s) => s.id == scan.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scan "${scan.detectedLabel}" dihapus'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus: $e'),
          backgroundColor: const Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadScans,
      color: const Color(0xFF4CAF50),
      backgroundColor: const Color(0xFF1E2530),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: Color(0xFF5A6478), size: 60),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF8B95A8), fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadScans,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_scans.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded,
                color: const Color(0xFF5A6478).withOpacity(0.5), size: 80),
            const SizedBox(height: 16),
            const Text(
              'Belum ada riwayat scan',
              style: TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Mulai scan sampah untuk melihat riwayatmu di sini',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8B95A8), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_scans.length} Riwayat Scan',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Tarik untuk refresh',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.35), fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _scans.length,
            itemBuilder: (context, index) {
              final scan = _scans[index];
              return ScanResultCard(
                scanResult: scan,
                storageService: _storageService,
                onEdit: () => _editScan(scan),
                onDelete: () => _deleteScan(scan),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Edit Bottom Sheet ──────────────────────────────────────────────────────────

class _EditScanSheet extends StatefulWidget {
  final ScanResult scan;
  const _EditScanSheet({required this.scan});

  @override
  State<_EditScanSheet> createState() => _EditScanSheetState();
}

class _EditScanSheetState extends State<_EditScanSheet> {
  late TextEditingController _labelController;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.scan.detectedLabel);
    _selectedCategory = widget.scan.category;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Color _categoryColor(String cat) => switch (cat) {
        'Organik' => const Color(0xFF4CAF50),
        'Anorganik' => const Color(0xFF2196F3),
        _ => const Color(0xFF9E9E9E),
      };

  IconData _categoryIcon(String cat) => switch (cat) {
        'Organik' => Icons.eco_rounded,
        'Anorganik' => Icons.recycling_rounded,
        _ => Icons.help_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF1A2332),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle bar ────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF5A6478),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Title ─────────────────────────────────────────────────────────
          const Row(
            children: [
              Icon(Icons.edit_rounded, color: Color(0xFF4CAF50), size: 22),
              SizedBox(width: 10),
              Text(
                'Edit Hasil Scan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Label ─────────────────────────────────────────────────────────
          const Text('Label Terdeteksi',
              style: TextStyle(color: Color(0xFF8B95A8), fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _labelController,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF2A3240),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
              ),
              hintText: 'Masukkan label...',
              hintStyle: const TextStyle(color: Color(0xFF5A6478)),
            ),
          ),
          const SizedBox(height: 20),

          // ── Category ──────────────────────────────────────────────────────
          const Text('Kategori',
              style: TextStyle(color: Color(0xFF8B95A8), fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildCategoryOption('Organik'),
              const SizedBox(width: 12),
              _buildCategoryOption('Anorganik'),
            ],
          ),
          const SizedBox(height: 28),

          // ── Save button ───────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final label = _labelController.text.trim();
                if (label.isEmpty) return;
                Navigator.pop(context, {
                  'label': label,
                  'category': _selectedCategory,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.check_rounded, size: 20),
              label: const Text(
                'Simpan Perubahan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryOption(String category) {
    final isSelected = _selectedCategory == category;
    final color = _categoryColor(category);
    final icon = _categoryIcon(category);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = category),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color:
                isSelected ? color.withOpacity(0.15) : const Color(0xFF2A3240),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? color.withOpacity(0.5)
                  : const Color(0xFF3A4450),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isSelected ? color : const Color(0xFF8B95A8),
                  size: 22),
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
