import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: _lightColorScheme,
        textTheme: AppTypography.textTheme,
        scaffoldBackgroundColor: AppColors.background,
        cardTheme: _cardTheme(AppColors.cardLight),
        appBarTheme: _appBarThemeLight,
        navigationBarTheme: _navBarThemeLight,
        floatingActionButtonTheme: _fabTheme(AppColors.primary),
        elevatedButtonTheme: _elevatedButtonTheme(AppColors.primary),
        outlinedButtonTheme: _outlinedButtonTheme(AppColors.primary),
        textButtonTheme: _textButtonTheme(AppColors.primary),
        inputDecorationTheme: _inputDecorationTheme(),
        chipTheme: _chipTheme(),
        dividerTheme: const DividerThemeData(
          color: AppColors.outline,
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: _snackBarTheme(),
        dialogTheme: _dialogTheme(),
        listTileTheme: _listTileTheme(),
        switchTheme: _switchTheme(AppColors.primary),
        checkboxTheme: _checkboxTheme(AppColors.primary),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: _darkColorScheme,
        textTheme: AppTypography.textTheme,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        cardTheme: _cardTheme(AppColors.cardDark),
        appBarTheme: _appBarThemeDark,
        navigationBarTheme: _navBarThemeDark,
        floatingActionButtonTheme: _fabTheme(AppColors.primaryDark),
        elevatedButtonTheme: _elevatedButtonTheme(AppColors.primaryDark),
        outlinedButtonTheme: _outlinedButtonTheme(AppColors.primaryDark),
        textButtonTheme: _textButtonTheme(AppColors.primaryDark),
        inputDecorationTheme: _inputDecorationTheme(dark: true),
        chipTheme: _chipTheme(dark: true),
        dividerTheme: const DividerThemeData(
          color: AppColors.outlineDark,
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: _snackBarTheme(dark: true),
        dialogTheme: _dialogTheme(dark: true),
        listTileTheme: _listTileTheme(dark: true),
        switchTheme: _switchTheme(AppColors.primaryDark),
        checkboxTheme: _checkboxTheme(AppColors.primaryDark),
      );

  static const _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.primaryLight,
    onSecondary: AppColors.onPrimary,
    secondaryContainer: AppColors.primaryContainer,
    onSecondaryContainer: AppColors.onPrimaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorLight,
    onErrorContainer: AppColors.error,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerHighest: AppColors.surfaceVariant,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.onSurface,
    onInverseSurface: AppColors.surface,
    inversePrimary: AppColors.primaryDark,
  );

  static const _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primaryDark,
    onPrimary: AppColors.onPrimaryDark,
    primaryContainer: AppColors.primaryDarkContainer,
    onPrimaryContainer: AppColors.onPrimaryDarkContainer,
    secondary: AppColors.successDark,
    onSecondary: AppColors.onPrimaryDark,
    secondaryContainer: AppColors.successDarkContainer,
    onSecondaryContainer: AppColors.onPrimaryDarkContainer,
    tertiary: AppColors.tertiaryDark,
    onTertiary: AppColors.onTertiaryDark,
    tertiaryContainer: AppColors.tertiaryDarkContainer,
    onTertiaryContainer: AppColors.onTertiaryDarkContainer,
    error: AppColors.errorDark,
    onError: AppColors.onPrimary,
    errorContainer: AppColors.errorDarkContainer,
    onErrorContainer: AppColors.errorDark,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.onSurfaceDark,
    surfaceContainerHighest: AppColors.surfaceDarkVariant,
    onSurfaceVariant: AppColors.onSurfaceDarkVariant,
    outline: AppColors.outlineDark,
    outlineVariant: AppColors.outlineDark,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.onSurfaceDark,
    onInverseSurface: AppColors.surfaceDark,
    inversePrimary: AppColors.primary,
  );

  static CardThemeData _cardTheme(Color color) => CardThemeData(
        color: color,
        elevation: AppSpacing.elevationCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      );

  static const _appBarThemeLight = AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 1,
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.onSurface,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      color: AppColors.onSurface,
    ),
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  static const _appBarThemeDark = AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 1,
    backgroundColor: AppColors.surfaceDark,
    foregroundColor: AppColors.onSurfaceDark,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      color: AppColors.onSurfaceDark,
    ),
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  static NavigationBarThemeData get _navBarThemeLight => NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(AppTypography.labelSmall),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.onSurfaceVariant,
          ),
        ),
      );

  static NavigationBarThemeData get _navBarThemeDark => NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        indicatorColor: AppColors.primaryDarkContainer,
        labelTextStyle: WidgetStateProperty.all(AppTypography.labelSmall),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primaryDark
                : AppColors.onSurfaceDarkVariant,
          ),
        ),
      );

  static FloatingActionButtonThemeData _fabTheme(Color color) =>
      FloatingActionButtonThemeData(
        backgroundColor: color,
        foregroundColor: AppColors.onPrimary,
        elevation: AppSpacing.elevationFab,
        focusElevation: AppSpacing.elevationFab,
        hoverElevation: AppSpacing.elevationFab,
        highlightElevation: AppSpacing.elevationFab,
        shape: const StadiumBorder(),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 22),
        extendedIconLabelSpacing: AppSpacing.sm,
        extendedTextStyle: AppTypography.labelLarge.copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      );

  static ElevatedButtonThemeData _elevatedButtonTheme(Color color) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(
            double.infinity,
            AppSpacing.minTouchTarget,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme(Color color) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(
            double.infinity,
            AppSpacing.minTouchTarget,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          side: BorderSide(color: color),
          textStyle: AppTypography.labelLarge,
        ),
      );

  static TextButtonThemeData _textButtonTheme(Color color) =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(0, AppSpacing.minTouchTarget),
          textStyle: AppTypography.labelLarge,
        ),
      );

  static InputDecorationTheme _inputDecorationTheme({bool dark = false}) =>
      InputDecorationTheme(
        filled: true,
        fillColor: dark ? AppColors.surfaceDarkVariant : AppColors.cardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(
            color: dark ? AppColors.outlineDark : AppColors.outlineVariant,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(
            color: dark ? AppColors.outlineDark : AppColors.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(
            color: dark ? AppColors.primaryDark : AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(
            color: dark ? AppColors.errorDark : AppColors.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(
            color: dark ? AppColors.errorDark : AppColors.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        labelStyle: AppTypography.bodyMedium,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: dark
              ? AppColors.onSurfaceDarkVariant
              : AppColors.onSurfaceVariant,
        ),
      );

  static ChipThemeData _chipTheme({bool dark = false}) => ChipThemeData(
        backgroundColor:
            dark ? AppColors.surfaceDarkVariant : AppColors.surfaceVariant,
        labelStyle: AppTypography.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        side: BorderSide.none,
      );

  static SnackBarThemeData _snackBarTheme({bool dark = false}) =>
      SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: Colors.white,
        ),
      );

  static DialogThemeData _dialogTheme({bool dark = false}) => DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        titleTextStyle: AppTypography.headlineSmall,
        contentTextStyle: AppTypography.bodyMedium,
      );

  static ListTileThemeData _listTileTheme({bool dark = false}) =>
      const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        minVerticalPadding: AppSpacing.sm,
        minLeadingWidth: 24,
      );

  static SwitchThemeData _switchTheme(Color color) => SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? color : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? color.withValues(alpha: 0.5)
              : Colors.grey.shade300,
        ),
      );

  static CheckboxThemeData _checkboxTheme(Color color) => CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? color
              : Colors.transparent,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      );
}
