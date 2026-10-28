import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_photo.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

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
    super.key,
  });

  final PickedPhoto? photo;
  final String? url;
  final bool enabled;
  final ValueChanged<PickedPhoto> onPicked;
  final VoidCallback onRemoved;

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
      final file = await picker.pickImage(
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
    final theme = Theme.of(context).textTheme;
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
        Text(l10n.homePhotoLabel, style: theme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        if (!hasPhoto)
          Semantics(
            button: true,
            label: l10n.homePhotoUpload,
            excludeSemantics: true,
            child: InkWell(
              key: const Key('home_photo_add'),
              borderRadius: BorderRadius.circular(16),
              onTap: widget.enabled ? _choose : null,
              child: Container(
                constraints: const BoxConstraints(minHeight: 120),
                padding: const EdgeInsets.all(AppSpacing.md),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.tileWell,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.teal,
                      size: 28,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(l10n.homePhotoUpload),
                    Text(
                      l10n.homePhotoHelp,
                      textAlign: TextAlign.center,
                      style: theme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          )
        else ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ColoredBox(
                key: const Key('home_photo_preview'),
                color: AppColors.tileWell,
                child: image,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              TextButton.icon(
                key: const Key('home_photo_replace'),
                onPressed: widget.enabled ? _choose : null,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: Text(l10n.homePhotoReplace),
              ),
              TextButton.icon(
                key: const Key('home_photo_remove'),
                onPressed: widget.enabled
                    ? () {
                        setState(() => _error = null);
                        widget.onRemoved();
                      }
                    : null,
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                label: Text(
                  l10n.homePhotoRemove,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ),
        ],
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
