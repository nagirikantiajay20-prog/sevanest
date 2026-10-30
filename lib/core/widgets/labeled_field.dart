import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';

/// Bold label above a bordered field, with a helper line that turns into a red error (design: screens 04, 08).
/// The field is keyed [name]; its error text is keyed `${name}_error`.
class LabeledField extends StatelessWidget {
  const LabeledField({
    required this.name,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.error,
    this.optionalTag,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.suffixIcon,
    this.prefixIcon,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.fill,
    this.requiredMark = false,
    this.optionalInline,
    super.key,
  });

  /// Fill colour for screens that sit on a photo: also switches to the glass look (15 px corners,
  /// 1.5 px slate border, 16 px text).
  final Color? fill;

  /// Red asterisk after the label.
  final bool requiredMark;

  /// Plain "(optional)"-style note after the label (the [optionalTag] pill is the older look).
  final String? optionalInline;
  final String name;
  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final String? error;

  /// Small pill after the label, e.g. "Optional".
  final String? optionalTag;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final Widget? suffixIcon;
  final IconData? prefixIcon;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    final glass = fill != null;
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(glass ? 15 : AppRadius.field),
      borderSide: BorderSide(color: c, width: glass ? 1.5 : w),
    );
    final edge = glass ? const Color(0xFFCBD5E1) : AppColors.hairline;
    final idle = hasError ? AppColors.danger : edge;
    final labelStyle = AppText.label.copyWith(fontSize: glass ? 14.5 : 15);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: requiredMark || optionalInline != null
                  ? Text.rich(
                      TextSpan(
                        text: label,
                        children: [
                          if (requiredMark)
                            const TextSpan(
                              text: ' *',
                              style: TextStyle(color: AppColors.danger),
                            ),
                          if (optionalInline != null)
                            TextSpan(
                              text: ' ($optionalInline)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppColors.slate700,
                              ),
                            ),
                        ],
                      ),
                      style: labelStyle,
                    )
                  : Text(label, style: labelStyle),
            ),
            if (optionalTag != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Text(
                  optionalTag!,
                  style: const TextStyle(color: AppColors.slate, fontSize: 14),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          key: Key(name),
          controller: controller,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          autofillHints: autofillHints,
          maxLength: maxLength,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: AppText.card.copyWith(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.card.copyWith(
              fontWeight: FontWeight.w400,
              color: glass ? const Color(0xFF64748B) : AppColors.slate400,
            ),
            counterText: '',
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, color: AppColors.slate),
            suffixIcon: suffixIcon,
            filled: fill != null || !enabled || readOnly && onTap == null,
            fillColor: fill ?? AppColors.fieldBg,
            contentPadding: EdgeInsets.symmetric(
              horizontal: glass ? 14 : AppSpacing.md,
              vertical: glass ? 15 : AppSpacing.md,
            ),
            border: border(idle),
            enabledBorder: border(idle),
            disabledBorder: border(edge),
            focusedBorder: border(
              hasError ? AppColors.danger : AppColors.teal,
              1.5,
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.danger,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      error!,
                      key: Key('${name}_error'),
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              helper!,
              style: const TextStyle(color: AppColors.slate, fontSize: 15),
            ),
          ),
      ],
    );
  }
}

/// Red inline banner for a failure that belongs to no single field (network, server, conflict).
class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.dangerBgSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.danger, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-button confirmation. Resolves true only when the confirm button is tapped.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required String cancelLabel,
  required Key confirmKey,
  Key cancelKey = const Key('dialog_cancel_btn'),
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          key: cancelKey,
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          key: confirmKey,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, kMinTapTarget),
            backgroundColor: destructive ? AppColors.danger : null,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Single-button information dialog.
Future<void> infoDialog(
  BuildContext context, {
  required String body,
  required String okLabel,
}) => showDialog<void>(
  context: context,
  builder: (ctx) => AlertDialog(
    content: Text(body),
    actions: [
      TextButton(
        key: const Key('dialog_ok_btn'),
        onPressed: () => Navigator.of(ctx).pop(),
        child: Text(okLabel),
      ),
    ],
  ),
);
