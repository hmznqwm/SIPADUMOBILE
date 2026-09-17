// File: profile_photo_action_sheets.dart
// Deskripsi: Modal aksi avatar (kamera, galeri, tata letak, hapus) dan dialog penyesuaian foto (crop/zoom/rotate).

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../../data/models/user_model.dart';
import '../../auth/view_models/auth_view_model.dart';

void showAvatarActionModal(BuildContext avatarCtx, UserModel? user) {
  final RenderBox? button = avatarCtx.findRenderObject() as RenderBox?;
  final RenderBox? overlay = Overlay.of(avatarCtx).context.findRenderObject() as RenderBox?;
  if (button == null || overlay == null) return;

  final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);
  final buttonSize = button.size;
  final double topPos = buttonPosition.dy + buttonSize.height + 8;

  final hasPhoto = user?.avatarPath != null && user!.avatarPath!.isNotEmpty;
  final isLocalFile = hasPhoto && File(user.avatarPath!).existsSync();

  showGeneralDialog<void>(
    context: avatarCtx,
    barrierDismissible: true,
    barrierLabel: 'AvatarActions',
    barrierColor: Colors.black.withValues(alpha: 0.18),
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (dialogCtx, anim1, anim2) {
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(dialogCtx),
            ),
          ),
          Positioned(
            top: topPos,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Tombol Galeri (Ganti Foto)
                      buildAvatarActionButton(
                        icon: Icons.photo_library_rounded,
                        color: AppColors.primary,
                        bgColor: AppColors.primary.withValues(alpha: 0.12),
                        tooltip: 'Galeri',
                        onTap: () {
                          Navigator.pop(dialogCtx);
                          pickAndCropImage(avatarCtx, ImageSource.gallery);
                        },
                      ),
                      const SizedBox(width: 8),
                      // Tombol Kamera
                      buildAvatarActionButton(
                        icon: Icons.camera_alt_rounded,
                        color: const Color(0xFF0D9488),
                        bgColor: const Color(0xFF0D9488).withValues(alpha: 0.12),
                        tooltip: 'Kamera',
                        onTap: () {
                          Navigator.pop(dialogCtx);
                          pickAndCropImage(avatarCtx, ImageSource.camera);
                        },
                      ),
                      // Tombol Tata Letak Foto (jika foto ada di lokal)
                      if (isLocalFile) ...[
                        const SizedBox(width: 8),
                        buildAvatarActionButton(
                          icon: Icons.crop_rotate_rounded,
                          color: const Color(0xFF0284C7),
                          bgColor: const Color(0xFF0284C7).withValues(alpha: 0.12),
                          tooltip: 'Tata Letak',
                          onTap: () {
                            Navigator.pop(dialogCtx);
                            openPhotoAdjuster(avatarCtx, user.avatarPath!);
                          },
                        ),
                      ],
                      // Tombol Hapus Foto (jika ada foto)
                      if (hasPhoto) ...[
                        const SizedBox(width: 8),
                        buildAvatarActionButton(
                          icon: Icons.delete_outline_rounded,
                          color: const Color(0xFFDC2626),
                          bgColor: const Color(0xFFDC2626).withValues(alpha: 0.12),
                          tooltip: 'Hapus Foto',
                          onTap: () {
                            Navigator.pop(dialogCtx);
                            confirmRemovePhoto(avatarCtx);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (dialogCtx, anim, secondaryAnim, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          ),
          alignment: Alignment.topCenter,
          child: child,
        ),
      );
    },
  );
}

Widget buildAvatarActionButton({
  required IconData icon,
  required Color color,
  required Color bgColor,
  required String tooltip,
  required VoidCallback onTap,
}) {
  return Tooltip(
    message: tooltip,
    child: Material(
      color: bgColor,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: color, size: 19),
        ),
      ),
    ),
  );
}

Future<void> pickAndCropImage(BuildContext context, ImageSource source) async {
  try {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked == null || !context.mounted) return;

    final croppedPath = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ProfilePhotoAdjusterDialog(imageFile: File(picked.path)),
    );

    if (croppedPath != null && context.mounted) {
      await context.read<AuthViewModel>().updateProfilePhoto(croppedPath);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

Future<void> openPhotoAdjuster(BuildContext context, String currentPath) async {
  final file = File(currentPath);
  if (!file.existsSync()) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File foto tidak ditemukan untuk diedit.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final croppedPath = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ProfilePhotoAdjusterDialog(imageFile: file),
  );

  if (croppedPath != null && context.mounted) {
    await context.read<AuthViewModel>().updateProfilePhoto(croppedPath);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tata letak foto berhasil diperbarui!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

void confirmRemovePhoto(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 8,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFDC2626),
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hapus Foto Profil?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Foto profil Anda akan dihapus dan kembali menggunakan inisial nama default.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: const Color(0xFFF8FAFC),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await context.read<AuthViewModel>().removeProfilePhoto();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Foto profil berhasil dihapus'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Hapus',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class ProfilePhotoAdjusterDialog extends StatefulWidget {
  final File imageFile;

  const ProfilePhotoAdjusterDialog({super.key, required this.imageFile});

  @override
  State<ProfilePhotoAdjusterDialog> createState() => _ProfilePhotoAdjusterDialogState();
}

class _ProfilePhotoAdjusterDialogState extends State<ProfilePhotoAdjusterDialog> {
  final TransformationController _transformController = TransformationController();
  ui.Image? _decodedImage;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _decodedImage = frame.image;
        });
      }
    } catch (e) {
      debugPrint('Error loading image for adjustment: $e');
    }
  }

  Future<void> _cropAndSave() async {
    if (_decodedImage == null || _isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      const double targetSize = 512.0;
      const double viewportSize = 250.0;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, targetSize, targetSize));

      final path = Path()..addOval(Rect.fromLTWH(0, 0, targetSize, targetSize));
      canvas.clipPath(path);

      canvas.drawColor(Colors.white, BlendMode.src);

      final Matrix4 matrix = _transformController.value;
      final double scaleFactor = targetSize / viewportSize;

      final Matrix4 scaledMatrix = Matrix4.diagonal3Values(scaleFactor, scaleFactor, 1.0)
        ..multiply(matrix);

      canvas.transform(scaledMatrix.storage);

      final double imgW = _decodedImage!.width.toDouble();
      final double imgH = _decodedImage!.height.toDouble();
      final double fitScale = viewportSize / math.min(imgW, imgH);
      final double drawW = imgW * fitScale;
      final double drawH = imgH * fitScale;
      final double offsetX = (viewportSize - drawW) / 2;
      final double offsetY = (viewportSize - drawH) / 2;

      canvas.drawImageRect(
        _decodedImage!,
        Rect.fromLTWH(0, 0, imgW, imgH),
        Rect.fromLTWH(offsetX, offsetY, drawW, drawH),
        Paint()..filterQuality = ui.FilterQuality.high,
      );

      final picture = recorder.endRecording();
      final img = await picture.toImage(targetSize.toInt(), targetSize.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) throw Exception('Gagal mengolah gambar');

      // Simpan permanen ke Documents Directory aplikasi
      final appDir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${appDir.path}/avatars');
      if (!avatarDir.existsSync()) {
        avatarDir.createSync(recursive: true);
      }
      final String croppedPath = '${avatarDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File(croppedPath);
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      // Bersihkan image cache agar UI segera menampilkan foto baru
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      if (mounted) {
        Navigator.pop(context, croppedPath);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan foto profil: $e'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.crop_rotate_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Atur Tata Letak Foto',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Geser & zoom untuk menyesuaikan',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_decodedImage == null)
                    const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
                  else
                    InteractiveViewer(
                      transformationController: _transformController,
                      minScale: 0.5,
                      maxScale: 4.0,
                      boundaryMargin: const EdgeInsets.all(120),
                      child: Image.file(
                        widget.imageFile,
                        fit: BoxFit.cover,
                        width: 250,
                        height: 250,
                      ),
                    ),
                  // Bingkai lingkaran sesuai tema
                  IgnorePointer(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isProcessing ? null : _cropAndSave,
                      child: _isProcessing
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Simpan Foto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
