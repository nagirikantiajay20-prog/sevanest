import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';

/// The worker of a booking: photo (or initials) and name. The photo link expires, so the image is
/// cached under the backend's `cacheKey`.
class WorkerIdentityTile extends StatelessWidget {
  const WorkerIdentityTile({required this.identity, this.onTap, super.key});
  final WorkerIdentity identity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final i = identity;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.hairline,
          foregroundImage: i.photoUrl == null
              ? null
              : CachedNetworkImageProvider(i.photoUrl!, cacheKey: i.cacheKey),
          child: Text(
            i.initials ?? i.displayName.characters.first.toUpperCase(),
          ),
        ),
        title: Text(i.displayName),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      ),
    );
  }
}
