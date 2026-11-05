import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';

abstract final class AppTheme {
  static OutlineInputBorder _border(Color c, [double w = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: BorderSide(color: c, width: w),
      );

  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          error: AppColors.danger,
        ).copyWith(
          primary: AppColors.teal,
          onPrimary: AppColors.surface,
          surface: AppColors.surface,
          onSurface: AppColors.brandInk,
          onSurfaceVariant: AppColors.slate,
          outline: AppColors.slate400,
          outlineVariant: AppColors.hairline,
          surfaceContainerHighest: AppColors.slateBg,
          primaryContainer: AppColors.tealWash,
          onPrimaryContainer: AppColors.actionDeepTeal,
          errorContainer: AppColors.dangerBg,
          onErrorContainer: AppColors.dangerText,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppFonts.body,
      textTheme: AppText.theme,
      scaffoldBackgroundColor: AppColors.surface,
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        space: 1,
        thickness: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.brandInk,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: AppText.screenTitle,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(kMinTapTarget + 4),
          textStyle: AppText.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          disabledBackgroundColor: AppColors.slateBg,
          disabledForegroundColor: AppColors.slate400,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandInk,
          textStyle: AppText.button,
          side: const BorderSide(color: AppColors.hairline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.teal,
          textStyle: AppText.button.copyWith(fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: AppText.bodyLarge.copyWith(color: AppColors.slate400),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.s12 + 2,
        ),
        border: _border(AppColors.hairline),
        enabledBorder: _border(AppColors.hairline),
        disabledBorder: _border(AppColors.hairline),
        focusedBorder: _border(AppColors.teal, 1.5),
        errorBorder: _border(AppColors.danger, 1.5),
        focusedErrorBorder: _border(AppColors.danger, 1.5),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.hairline),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.tealWash,
        side: BorderSide(color: AppColors.hairline),
        shape: StadiumBorder(),
        labelStyle: AppText.label,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.pillActive,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => AppText.micro.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: s.contains(WidgetState.selected)
                ? AppColors.teal
                : AppColors.slate,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? AppColors.teal
                : AppColors.slate,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: AppText.screenTitle,
        contentTextStyle: AppText.body,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        dragHandleColor: AppColors.slate300,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.brandInk,
        contentTextStyle: AppText.body.copyWith(color: AppColors.surface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.teal,
      ),
    );
  }
}
