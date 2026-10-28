import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_photo.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_photo_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

String profileInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}

/// Lets the user choose a photo from the gallery; null when they back out. Resized on the device
/// so the upload stays small (the backend rejects files over its size limit).
Future<PickedPhoto?> pickProfilePhoto() async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
  );
  if (file == null) return null;
  return PickedPhoto.fromBytes(await file.readAsBytes());
}

/// Round profile photo with a camera badge; tapping it picks and uploads a new one.
///
/// Normal mode shows `GET /customers/me/photo` and uploads on pick. With [onPicked] it is a pure
/// picker (profile setup, where the profile must exist before a photo can be sent): it shows
/// [localBytes] and hands the choice to the parent.
class ProfilePhotoAvatar extends ConsumerStatefulWidget {
  const ProfilePhotoAvatar({
    required this.initials,
    this.radius = 28,
    this.onPicked,
    this.localBytes,
    super.key,
  });

  final String initials;
  final double radius;
  final ValueChanged<PickedPhoto>? onPicked;
  final Uint8List? localBytes;

  @override
  ConsumerState<ProfilePhotoAvatar> createState() => _ProfilePhotoAvatarState();
}

class _ProfilePhotoAvatarState extends ConsumerState<ProfilePhotoAvatar> {
  bool _busy = false;

  Future<void> _tap() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final PickedPhoto? picked;
    try {
      picked = await pickProfilePhoto();
    } on Object {
      return;
    }
    if (picked == null || !mounted) return;
    final onPicked = widget.onPicked;
    if (onPicked != null) {
      onPicked(picked);
      return;
    }
    setState(() => _busy = true);
    String message;
    try {
      await ref.read(profilePhotoProvider.notifier).upload(picked);
      message = l10n.profilePhotoUpdated;
    } on AppFailure catch (f) {
      message = failureMessage(l10n, f);
    }
    if (mounted) setState(() => _busy = false);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  ImageProvider? _image() {
    if (widget.onPicked != null) {
      final b = widget.localBytes;
      return b == null ? null : MemoryImage(b);
    }
    final p = ref.watch(profilePhotoProvider).value;
    if (p?.bytes != null) return MemoryImage(p!.bytes!);
    if (p?.url != null) return NetworkImage(p!.url!);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = widget.radius;
    final image = _image();
    return Semantics(
      button: true,
      label: image == null ? l10n.profilePhotoAdd : l10n.profilePhotoChange,
      excludeSemantics: true,
      child: InkResponse(
        key: const Key('profile_photo_btn'),
        onTap: _busy ? null : _tap,
        radius: r + 8,
        child: SizedBox(
          width: r * 2 + 6,
          height: r * 2 + 6,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: r,
                backgroundColor: AppColors.tileWell,
                foregroundColor: AppColors.teal,
                foregroundImage: image,
                // An expired link just leaves the initials showing.
                onForegroundImageError: image == null ? null : (_, _) {},
                child: Text(
                  widget.initials,
                  style: TextStyle(
                    fontSize: r * 0.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_busy)
                SizedBox(
                  width: r * 2,
                  height: r * 2,
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.teal,
                  ),
                ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: Icon(
                    Icons.photo_camera_outlined,
                    size: (r * 0.5).clamp(14, 20),
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
