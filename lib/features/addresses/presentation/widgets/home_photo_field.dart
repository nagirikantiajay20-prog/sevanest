import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_photo.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Test seam: replaces the camera / gallery picker (the platform picker cannot run in a widget test).
@visibleForTesting
Future<XFile?> Function(ImageSource source)? debugPickHomePhoto;

/// Largest home photo accepted (the picker also downsizes to 1600 px first).
const maxHomePhotoBytes = 5 * 1024 * 1024;

/// JPEG or PNG by file signature (the extension on a camera or gallery path can lie).
bool isSupportedPhoto(Uint8List b) =>
    b.length > 3 &&
    ((b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) ||
        (b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47));

/// "Upload Home Photo": empty tile -> gallery / camera sheet; with a photo -> preview plus
/// Replace and Remove. [url] is the photo already saved with the address.
class HomePhotoField extends StatefulWidget {
  const HomePhotoField({
    required this.photo,
    required this.url,
    required this.enabled,
    required this.onPicked,
    required this.onRemoved,
    this.showRequired = false,
    super.key,
  });

  final PickedPhoto? photo;
  final String? url;
  final bool enabled;
  final ValueChanged<PickedPhoto> onPicked;
  final VoidCallback onRemoved;

  /// The photo is mandatory: show why Save is still disabled while none is chosen.
  final bool showRequired;

  @override
  State<HomePhotoField> createState() => _HomePhotoFieldState();
}

class _HomePhotoFieldState extends State<HomePhotoField> {
  String? _error;

  Future<void> _choose() async {
    final l10n = AppLocalizations.of(context);
    final picker = ImagePicker();
    var camera = false;
    try {
      camera = picker.supportsImageSource(ImageSource.camera);
    } on Object {
      // no camera on this platform
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('home_photo_gallery_option'),
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.homePhotoGallery),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            if (camera)
              ListTile(
                key: const Key('home_photo_camera_option'),
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.homePhotoCamera),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    String? error;
    try {
      final file =
          await debugPickHomePhoto?.call(source) ??
          await picker.pickImage(
            source: source,
            maxWidth: 1600,
            maxHeight: 1600,
            imageQuality: 85,
          );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!isSupportedPhoto(bytes)) {
        error = l10n.homePhotoBadFormat;
      } else if (bytes.length > maxHomePhotoBytes) {
        error = l10n.homePhotoTooBig;
      } else {
        if (mounted) setState(() => _error = null);
        widget.onPicked(PickedPhoto.fromBytes(bytes));
        return;
      }
    } on Object {
      // Denied camera / photo permission surfaces as a platform exception.
      error = l10n.homePhotoPermission;
    }
    if (mounted) setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bytes = widget.photo?.bytes;
    final url = widget.url;
    final hasPhoto = bytes != null || (url != null && url.isNotEmpty);
    final Widget image = bytes != null
        ? Image.memory(bytes, fit: BoxFit.cover)
        : hasPhoto
        ? Image.network(
            url!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Center(
              child: Icon(Icons.broken_image_outlined, color: AppColors.slate),
            ),
          )
        : const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: l10n.homePhotoLabel,
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.danger),
              ),
            ],
          ),
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: _navy,
          ),
        ),
        const SizedBox(height: 7),
        if (!hasPhoto)
          Semantics(
            button: true,
            label: l10n.homePhotoUpload,
            excludeSemantics: true,
            child: InkWell(
              key: const Key('home_photo_add'),
              borderRadius: BorderRadius.circular(18),
              onTap: widget.enabled ? _choose : null,
              child: CustomPaint(
                foregroundPainter: const _DashedBorder(),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 84),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.pillActive,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.photo_camera_outlined,
                          color: AppColors.teal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.homePhotoUpload,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.teal,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.homePhotoHelp,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: AppColors.slate700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            height: 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.surface, width: 2),
              boxShadow: [
                BoxShadow(
                  color: _navy.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    key: const Key('home_photo_preview'),
                    color: AppColors.tileWell,
                    child: image,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(0, -0.1),
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.blue0F2340A0,
                          AppColors.blue0F2340A60,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 8,
                    child: Row(
                      children: [
                        _GlassAction(
                          key: const Key('home_photo_replace'),
                          label: l10n.homePhotoReplace,
                          color: _navy,
                          onTap: widget.enabled ? _choose : null,
                        ),
                        const SizedBox(width: 8),
                        _GlassAction(
                          key: const Key('home_photo_remove'),
                          label: l10n.homePhotoRemove,
                          color: AppColors.red700,
                          onTap: widget.enabled
                              ? () {
                                  setState(() => _error = null);
                                  widget.onRemoved();
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (widget.showRequired && !hasPhoto && _error == null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              l10n.homePhotoRequired,
              key: const Key('home_photo_required'),
              style: const TextStyle(fontSize: 13, color: AppColors.red700),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              _error!,
              key: const Key('home_photo_error'),
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
      ],
    );
  }
}

const _navy = AppColors.navyDeep;

/// Frosted pill button laid over the photo (Replace / Remove).
class _GlassAction extends StatelessWidget {
  const _GlassAction({
    required this.label,
    required this.color,
    required this.onTap,
    super.key,
  });
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface.withValues(alpha: 0.72),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.whiteA90xE6),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    ),
  );
}

/// 2 px dashed teal outline around the upload tile.
class _DashedBorder extends CustomPainter {
  const _DashedBorder();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(18),
        ).deflate(1),
      );
    final paint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 10) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => false;
}
