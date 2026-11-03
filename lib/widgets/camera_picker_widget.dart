import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

class CameraPickerWidget extends StatefulWidget {
  final String? initialImagePath;
  final ValueChanged<String> onImageSelected;

  const CameraPickerWidget({
    super.key,
    this.initialImagePath,
    required this.onImageSelected,
  });

  @override
  State<CameraPickerWidget> createState() => _CameraPickerWidgetState();
}

class _CameraPickerWidgetState extends State<CameraPickerWidget> {
  String? _selectedImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedImagePath = widget.initialImagePath;
  }

  Future<void> _captureWithCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedImagePath = photo.path;
        });
        widget.onImageSelected(photo.path);
      }
    } catch (e) {
      debugPrint('Camera error: $e. Opening sample picker.');
      _showSampleSelectorModal();
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
        widget.onImageSelected(image.path);
      }
    } catch (e) {
      debugPrint('Gallery error: $e. Opening sample picker.');
      _showSampleSelectorModal();
    }
  }

  void _showSampleSelectorModal() {
    final samplePhotos = [
      {
        'title': 'Plastic Bottles & Jugs',
        'tag': 'sample_plastics',
        'icon': Icons.recycling_rounded,
        'color': const Color(0xFF1E88E5),
      },
      {
        'title': 'Organic Food Scraps',
        'tag': 'sample_organic',
        'icon': Icons.eco_rounded,
        'color': const Color(0xFF43A047),
      },
      {
        'title': 'Old Electronics & Cables',
        'tag': 'sample_ewaste',
        'icon': Icons.battery_alert_rounded,
        'color': const Color(0xFFE53935),
      },
      {
        'title': 'Cardboard & Paper Boxes',
        'tag': 'sample_paper',
        'icon': Icons.inventory_2_outlined,
        'color': const Color(0xFFFB8C00),
      },
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Waste Photo for Verification',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Used for quick testing or when camera device is unattached.',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              ...samplePhotos.map((s) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (s['color'] as Color).withValues(alpha: 0.15),
                      child: Icon(s['icon'] as IconData, color: s['color'] as Color),
                    ),
                    title: Text(s['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Sample photo: ${s['tag']}'),
                    trailing: const Icon(Icons.check_circle_outline),
                    onTap: () {
                      Navigator.pop(ctx);
                      final path = 'simulated_${s['tag']}';
                      setState(() {
                        _selectedImagePath = path;
                      });
                      widget.onImageSelected(path);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage = _selectedImagePath != null && _selectedImagePath!.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: hasImage ? AppTheme.accentMint.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasImage ? AppTheme.primaryGreen : const Color(0xFFDDDDDD),
          width: hasImage ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (hasImage) ...[
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImagePreview(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 18),
                const SizedBox(width: 6),
                const Text(
                  'Waste photo verified & attached',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showOptions,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retake'),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceGrey,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 38,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Move Closer & Take a Photo of the Waste',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Helps the collector inspect volume, sorting & equipment needed.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _showOptions,
              icon: const Icon(Icons.photo_camera_rounded),
              label: const Text('Capture Waste Photo'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    final path = _selectedImagePath ?? '';
    if (path.startsWith('simulated_') || path.startsWith('assets/')) {
      return Container(
        color: AppTheme.accentMint,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_outline_rounded, size: 48, color: AppTheme.primaryGreen),
              const SizedBox(height: 8),
              Text(
                'Waste Photo Attached: ${path.replaceAll('simulated_', '').replaceAll('assets/', '')}',
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.darkForest),
              ),
            ],
          ),
        ),
      );
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 40)),
      );
    } else if (!kIsWeb && File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 40)),
      );
    } else {
      return Container(
        color: AppTheme.accentMint,
        child: const Center(
          child: Icon(Icons.photo_camera_rounded, size: 40, color: AppTheme.primaryGreen),
        ),
      );
    }
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryGreen),
              title: const Text('Take Picture Now (Camera)'),
              onTap: () {
                Navigator.pop(ctx);
                _captureWithCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.lightGreen),
              title: const Text('Choose From Device Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.collections_rounded, color: Colors.blueAccent),
              title: const Text('Choose Verified Sample Waste Photo'),
              subtitle: const Text('Instant simulation for testing/emulator'),
              onTap: () {
                Navigator.pop(ctx);
                _showSampleSelectorModal();
              },
            ),
          ],
        ),
      ),
    );
  }
}
