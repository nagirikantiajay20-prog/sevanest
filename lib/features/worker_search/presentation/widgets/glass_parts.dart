import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart'
    show avatarGradientFor, workerInitials;
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// Pieces shared by the glass list / status screens (Favourites, Interviews): avatar, empty state
/// and the bottom confirmation sheet.

/// Round initials (or photo) avatar on a gradient, with the white ring of the design.
class GlassAvatar extends StatelessWidget {
  const GlassAvatar({
    required this.title,
    required this.gradient,
    this.initials,
    this.photoUrl,
    this.size = 52,
    this.fontSize = 17,
    super.key,
  });

  final String title;
  final String? initials;
  final String? photoUrl;
  final List<Color> gradient;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        image: photoUrl == null
            ? null
            : DecorationImage(
                image: ResizeImage(NetworkImage(photoUrl!), width: 240),
                fit: BoxFit.cover,
                onError: (_, _) {},
              ),
        boxShadow: [
          BoxShadow(
            color: dsNavy.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: photoUrl != null
          ? null
          : Text(
              workerInitials(initials, title),
              style: AppText.body.copyWith(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: AppColors.surface,
              ),
            ),
    ),
  );
}

/// Centred empty state: a floating icon disc, serif title, body and a navy call to action.
class GlassEmpty extends StatelessWidget {
  const GlassEmpty({
    required this.icon,
    required this.iconColor,
    required this.discColors,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.actionKey,
    required this.onAction,
    this.actionIcon,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final List<Color> discColors;
  final String title;
  final String body;
  final String actionLabel;
  final Key actionKey;
  final VoidCallback onAction;

  /// Icon after the button label (none by default).
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    final clock = DiscoverClock.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 48),
        child: DiscoverRise(
          delayMs: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<double>(
                valueListenable: clock,
                builder: (context, t, child) => Transform.translate(
                  offset: Offset(0, -5 * math.sin(t / 4000 * math.pi).abs()),
                  child: child,
                ),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: discColors,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: dsNavy.withValues(alpha: 0.14),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 46, color: iconColor),
                ),
              ),
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: authSerif(26, 1.2),
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 290),
                child: Text(
                  body,
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(
                    fontSize: 15.5,
                    height: 1.5,
                    color: dsText,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 220,
                child: AuthCta(
                  key: actionKey,
                  clock: clock,
                  label: actionLabel,
                  loadingLabel: actionLabel,
                  loading: false,
                  breathe: true,
                  showArrow: false,
                  radius: 18,
                  height: 54,
                  onPressed: onAction,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cream bottom sheet of the glass screens: rounded top, grab handle, then [builder]'s content.
Future<T?> showGlassSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  barrierColor: AppColors.sky1B3354A38,
  builder: (ctx) => Container(
    padding: EdgeInsets.fromLTRB(
      20,
      12,
      20,
      24 + MediaQuery.paddingOf(ctx).bottom,
    ),
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.whiteA97xF7, AppColors.whiteFAF8F5A97],
      ),
      boxShadow: [
        BoxShadow(
          color: dsNavy.withValues(alpha: 0.25),
          blurRadius: 40,
          offset: const Offset(0, -16),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: dsNavy.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(height: 16),
        builder(ctx),
      ],
    ),
  ),
);

/// Bottom sheet that asks "are you sure?": serif title, body, a big confirm button and a plain
/// "keep" text button. True only when confirm is tapped.
Future<bool> showGlassConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required String keepLabel,
  required Key confirmKey,
  Key keepKey = const Key('dialog_cancel_btn'),
  bool destructive = false,
}) async {
  final yes = await showGlassSheet<bool>(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: authSerif(24, 1.15)),
        const SizedBox(height: 12),
        Text(
          body,
          style: AppText.body.copyWith(
            fontSize: 15.5,
            height: 1.55,
            color: dsText,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 58,
          child: FilledButton(
            key: confirmKey,
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: destructive ? AppColors.rose700 : dsNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: AppText.body.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(confirmLabel),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: TextButton(
            key: keepKey,
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: dsMuted,
              textStyle: AppText.body.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(keepLabel),
          ),
        ),
      ],
    ),
  );
  return yes ?? false;
}

/// Name of the worker on [b] (the backend sends it from the interview stage on), else null.
String? bookingWorkerName(Booking b) =>
    b.identity?.displayName ?? b.worker?.name;

/// Avatar of the worker on [b]: photo or initials on that worker's own gradient.
Widget bookingAvatar(Booking b, {double size = 48, double fontSize = 16}) =>
    GlassAvatar(
      title: bookingWorkerName(b) ?? b.categoryName ?? '',
      initials: b.identity?.initials ?? b.worker?.initials,
      photoUrl: b.identity?.photoUrl ?? b.worker?.photoUrl,
      gradient: avatarGradientFor(b.workerId ?? b.id),
      size: size,
      fontSize: fontSize,
    );

/// `AsyncValueView` for the glass pages: frosted placeholders while it loads, a frosted card with
/// Retry when it fails (no connection reads differently from a server problem).
class GlassAsyncView<T> extends StatelessWidget {
  const GlassAsyncView({
    required this.value,
    required this.data,
    this.onRetry,
    super.key,
  });
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (value.hasValue) return data(value.requireValue);
    final l10n = AppLocalizations.of(context);
    if (!value.hasError) {
      return Semantics(
        label: l10n.loading,
        container: true,
        child: ListView(
          key: const Key('glass_loading'),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                height: 92,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.whiteA60x99,
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
          ],
        ),
      );
    }
    final offline = isOffline(value.error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DiscoverGlass(
          radius: 26,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  offline
                      ? Icons.wifi_off_rounded
                      : Icons.error_outline_rounded,
                  size: 36,
                  color: AppColors.rose700,
                ),
                const SizedBox(height: 10),
                Text(
                  failureMessage(l10n, value.error!),
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(fontSize: 15, color: dsText),
                ),
                if (onRetry != null)
                  TextButton(
                    key: const Key('error_retry_btn'),
                    onPressed: onRetry,
                    child: Text(l10n.retry),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The design's `.note` text area: white, rounded, navy hairline, no counter.
class GlassNoteField extends StatelessWidget {
  const GlassNoteField({
    required this.controller,
    required this.hint,
    required this.maxLength,
    this.enabled = true,
    this.minLines = 4,
    this.errorText,
    this.onChanged,
    super.key,
  });
  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final bool enabled;
  final int minLines;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder line(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c),
    );
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLength: maxLength,
      minLines: minLines,
      maxLines: minLines + 2,
      onChanged: onChanged,
      style: AppText.body.copyWith(fontSize: 15, height: 1.45, color: dsNavy),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.body.copyWith(fontSize: 15, color: dsMuted),
        errorText: errorText,
        counterText: '',
        filled: true,
        fillColor: AppColors.whiteA85xD9,
        contentPadding: const EdgeInsets.all(12),
        enabledBorder: line(AppColors.sky1B3354A18),
        disabledBorder: line(AppColors.sky1B3354A18),
        focusedBorder: line(dsNavy),
        errorBorder: line(AppColors.rose700),
        focusedErrorBorder: line(AppColors.rose700),
      ),
    );
  }
}
