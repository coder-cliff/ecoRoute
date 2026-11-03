import 'dart:convert';
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
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 65,
      );

      if (photo != null) {
        final String path;
        if (kIsWeb) {
          final bytes = await photo.readAsBytes();
          path = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        } else {
          path = photo.path;
        }
        setState(() {
          _selectedImagePath = path;
        });
        widget.onImageSelected(path);
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
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 65,
      );

      if (image != null) {
        final String path;
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          path = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        } else {
          path = image.path;
        }
        setState(() {
          _selectedImagePath = path;
        });
        widget.onImageSelected(path);
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
                      final path = 'simulated_${s['tag']}';
                      setState(() {
                        _selectedImagePath = path;
                      });
                      widget.onImageSelected(path);
                      Navigator.pop(ctx);
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
    final hasImage = _selectedImagePath != null && _selectedImagePath!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasImage ? AppTheme.primaryGreen : const Color(0xFFDDDDDD),
          width: hasImage ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // PREVIEW BOX
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: _buildImagePreview(),
            ),
          ),

          // BUTTON BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _showOptions,
                    icon: Icon(hasImage ? Icons.cached_rounded : Icons.add_a_photo_rounded, size: 18),
                    label: Text(
                      hasImage ? 'Change Photo' : 'Capture Waste Photo',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                if (hasImage) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedImagePath = null;
                      });
                      widget.onImageSelected('');
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    tooltip: 'Remove photo',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    final path = _selectedImagePath ?? '';
    if (path.isEmpty) {
      return Container(
        color: AppTheme.accentMint,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_camera_rounded, size: 48, color: AppTheme.primaryGreen),
              SizedBox(height: 8),
              Text(
                'No photo attached yet',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.darkForest),
              ),
              Text(
                'Tap below to take photo or choose sample',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    if (path.startsWith('data:image')) {
      try {
        final bytes = base64Decode(path.split(',').last);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 40)),
        );
      } catch (e) {
        return const Center(child: Icon(Icons.broken_image, size: 40));
      }
    }

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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Attach Waste Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.accentMint,
                  child: Icon(Icons.camera_alt, color: AppTheme.primaryGreen),
                ),
                title: const Text('Take Photo with Camera'),
                subtitle: const Text('Live capture of waste pile/bin'),
                onTap: () {
                  Navigator.pop(ctx);
                  _captureWithCamera();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(Icons.photo_library, color: Color(0xFF1976D2)),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select existing photo on device'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFF3E0),
                  child: Icon(Icons.layers_rounded, color: Color(0xFFF57C00)),
                ),
                title: const Text('Select Sample Waste Photo'),
                subtitle: const Text('Quick test without physical camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSampleSelectorModal();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
