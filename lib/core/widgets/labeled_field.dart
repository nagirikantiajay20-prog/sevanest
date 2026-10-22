import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';

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
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

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
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: c, width: 1.5),
    );
    final idle = hasError ? AppColors.danger : AppColors.slate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.slate),
            counterText: '',
            suffixIcon: suffixIcon,
            filled: !enabled || readOnly && onTap == null,
            fillColor: AppColors.fieldBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            border: border(idle),
            enabledBorder: border(idle),
            disabledBorder: border(AppColors.hairline),
            focusedBorder: border(hasError ? AppColors.danger : AppColors.teal),
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
        TextButton(
          key: confirmKey,
          style: destructive
              ? TextButton.styleFrom(foregroundColor: AppColors.danger)
              : null,
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
