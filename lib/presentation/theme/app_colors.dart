import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Paleta primária — verde fintech premium ─────────────────────────────
  static const primary = Color(0xFF1B4332);
  static const primaryLight = Color(0xFF2D6A4F);
  static const primaryContainer = Color(0xFFD8F3DC);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF081C15);

  // ── Paleta primária — modo escuro ────────────────────────────────────────
  static const primaryDark = Color(0xFF52B788);
  static const primaryDarkContainer = Color(0xFF1B4332);
  static const onPrimaryDark = Color(0xFF081C15);
  static const onPrimaryDarkContainer = Color(0xFFB7E4C7);

  // ── Terciária — acento âmbar premium ────────────────────────────────────
  static const tertiary = Color(0xFFB06000);
  static const tertiaryContainer = Color(0xFFFFDDB8);
  static const onTertiary = Color(0xFFFFFFFF);
  static const onTertiaryContainer = Color(0xFF361900);

  static const tertiaryDark = Color(0xFFFFB869);
  static const tertiaryDarkContainer = Color(0xFF7E4400);
  static const onTertiaryDark = Color(0xFF4A2000);
  static const onTertiaryDarkContainer = Color(0xFFFFDDB8);

  // ── Semântica financeira ─────────────────────────────────────────────────
  static const success = Color(0xFF2D6A4F);
  static const successLight = Color(0xFFD8F3DC);
  static const onSuccess = Color(0xFFFFFFFF);

  static const successDark = Color(0xFF74C69D);
  static const successDarkContainer = Color(0xFF1B4332);

  static const warning = Color(0xFFD4A017);
  static const warningLight = Color(0xFFFFF3CD);
  static const onWarning = Color(0xFF1A1200);

  static const warningDark = Color(0xFFF9C74F);
  static const warningDarkContainer = Color(0xFF3D2900);

  static const error = Color(0xFFC1121F);
  static const errorLight = Color(0xFFFFDAD6);
  static const onError = Color(0xFFFFFFFF);

  static const errorDark = Color(0xFFFF6B6B);
  static const errorDarkContainer = Color(0xFF410002);

  // ── Neutros — modo claro ─────────────────────────────────────────────────
  static const surface = Color(0xFFF8F9FA);
  static const surfaceVariant = Color(0xFFEFEFF4);
  static const onSurface = Color(0xFF1C1C1E);
  static const onSurfaceVariant = Color(0xFF49454F);
  static const outline = Color(0xFFCAC4D0);
  static const outlineVariant = Color(0xFFE7E0EC);
  static const background = Color(0xFFF2F2F7);
  static const onBackground = Color(0xFF1C1C1E);

  // ── Neutros — modo escuro ────────────────────────────────────────────────
  static const surfaceDark = Color(0xFF1A1A2E);
  static const surfaceDarkVariant = Color(0xFF252538);
  static const onSurfaceDark = Color(0xFFF5F5F5);
  static const onSurfaceDarkVariant = Color(0xFFCAC4D0);
  static const outlineDark = Color(0xFF49454F);
  static const backgroundDark = Color(0xFF121212);
  static const onBackgroundDark = Color(0xFFF5F5F5);

  // ── Cards e elevações ────────────────────────────────────────────────────
  static const cardLight = Color(0xFFFFFFFF);
  static const cardDark = Color(0xFF1E1E30);

  // ── Tokens de superfície elevada (glassmorphism-light) ───────────────────
  /// Branca com 72 % opacidade — uso em overlays claros (hero cards).
  static const glassLight = Color(0xB8FFFFFF);

  /// Escura com 60 % opacidade — uso em overlays escuros.
  static const glassDark = Color(0x99252538);

  // ── Mapa de status de boleto ─────────────────────────────────────────────
  static Color billStatusColor(String status, {bool dark = false}) =>
      switch (status) {
        'paid' => dark ? successDark : success,
        'pending' => dark ? warningDark : warning,
        'overdue' => dark ? errorDark : error,
        'cancelled' => dark ? onSurfaceDarkVariant : onSurfaceVariant,
        _ => dark ? onSurfaceDarkVariant : onSurfaceVariant,
      };
}

// ---------------------------------------------------------------------------
// Gradient tokens  — T121
// ---------------------------------------------------------------------------

/// Predefined gradients for the premium fintech look.
///
/// All gradients are declared as `static const` for zero allocation on reuse.
abstract final class AppGradients {
  // ── Primary (green) ──────────────────────────────────────────────────────

  /// Vertical top-to-bottom dark-green to mid-green.
  static const primaryVertical = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
  );

  /// Dark mode equivalent.
  static const primaryVerticalDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D6A4F), Color(0xFF52B788)],
  );

  // ── Success / Income ─────────────────────────────────────────────────────
  static const success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D6A4F), Color(0xFF40916C)],
  );

  // ── Warning / Expense ────────────────────────────────────────────────────
  static const warning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB06000), Color(0xFFD4A017)],
  );

  // ── Error / Debt ─────────────────────────────────────────────────────────
  static const error = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC1121F), Color(0xFFE63946)],
  );

  // ── Neutral surface ──────────────────────────────────────────────────────
  static const surfaceLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8F9FA), Color(0xFFEFEFF4)],
  );

  static const surfaceDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A2E), Color(0xFF121212)],
  );

  // ── Hero / Balance card ──────────────────────────────────────────────────
  /// Used for the main balance / hero card in Dashboard.
  static const heroLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
    colors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF40916C)],
  );

  static const heroDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
    colors: [Color(0xFF0D2818), Color(0xFF1B4332), Color(0xFF2D6A4F)],
  );
}
