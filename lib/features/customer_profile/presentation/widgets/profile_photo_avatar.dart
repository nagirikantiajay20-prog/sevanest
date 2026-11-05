import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/sn_bottom_sheet.dart';
import 'package:sevanest_customer/features/addresses/presentation/widgets/home_photo_field.dart'
    show isSupportedPhoto;
import 'package:sevanest_customer/features/customer_profile/domain/customer_photo.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_photo_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

String profileInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}

/// Asks Camera or Gallery, then returns the chosen photo (resized on the device so the upload
/// stays small); null when they back out. Throws when the camera or photo access is denied.
Future<PickedPhoto?> pickProfilePhoto(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final picker = ImagePicker();
  var camera = false;
  try {
    camera = picker.supportsImageSource(ImageSource.camera);
  } on Object {
    // no camera on this platform
  }
  final source = await showSnBottomSheet<ImageSource>(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (camera)
          ListTile(
            key: const Key('profile_photo_camera_option'),
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.homePhotoCamera),
            onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
          ),
        ListTile(
          key: const Key('profile_photo_gallery_option'),
          leading: const Icon(Icons.photo_library_outlined),
          title: Text(l10n.homePhotoGallery),
          onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
        ),
      ],
    ),
  );
  if (source == null) return null;
  final file = await picker.pickImage(
    source: source,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
  );
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  if (!isSupportedPhoto(bytes)) throw const FormatException('photo format');
  return PickedPhoto.fromBytes(bytes);
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
    this.gradient,
    super.key,
  });

  final String initials;
  final double radius;

  /// Design look of My profile: initials in white on this gradient, white ring, small badge.
  final List<Color>? gradient;
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
      picked = await pickProfilePhoto(context);
    } on FormatException {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.homePhotoBadFormat)));
      return;
    } on Object {
      // Denied camera / photo permission surfaces as a platform exception.
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.homePhotoPermission)));
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
    final gradient = widget.gradient;
    // The large badge belongs to profile setup; the gradient avatar keeps it compact.
    final big = r > 40 && gradient == null;
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
              Container(
                decoration: gradient == null
                    ? null
                    : BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradient,
                        ),
                        border: Border.all(color: AppColors.surface, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.sky1B3354A28,
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                child: CircleAvatar(
                  radius: gradient == null ? r : r - 3,
                  backgroundColor: gradient != null
                      ? Colors.transparent
                      : r > 40
                      ? AppColors.pillActive
                      : AppColors.tealWash,
                  foregroundColor: gradient == null
                      ? AppColors.teal
                      : AppColors.surface,
                  foregroundImage: image,
                  // An expired link just leaves the initials showing.
                  onForegroundImageError: image == null ? null : (_, _) {},
                  child: widget.initials.isEmpty
                      ? Icon(Icons.person_outline, size: r > 40 ? 52 : r * 1.1)
                      : Text(
                          widget.initials,
                          style: TextStyle(
                            fontSize: gradient == null ? r * 0.6 : r * 0.66,
                            fontWeight: gradient == null
                                ? FontWeight.w700
                                : FontWeight.w800,
                          ),
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
                right: big ? -4 : 0,
                bottom: big ? 0 : 0,
                child: Container(
                  width: big ? 44 : null,
                  height: big ? 44 : null,
                  alignment: Alignment.center,
                  padding: big ? null : const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: big ? AppColors.surface : AppColors.surface,
                      width: big ? 3 : 2,
                    ),
                    boxShadow: big
                        ? [
                            BoxShadow(
                              color: AppColors.teal.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.photo_camera_outlined,
                    size: big ? 19 : (r * 0.5).clamp(14, 20),
                    color: AppColors.surface,
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
