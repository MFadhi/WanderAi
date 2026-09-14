import 'package:flutter/material.dart';

/// WanderAI Color Palette
/// Deep midnight navy + amber gold + sky blue
sealed class AppColors {
  AppColors._();

  // ─────────────────────────────────────────────
  // Backgrounds
  // ─────────────────────────────────────────────
  static const Color background = Color(0xFF080F1A);
  static const Color surface = Color(0xFF111827);
  static const Color card = Color(0xFF1A2535);
  static const Color cardElevated = Color(0xFF1E2D42);
  static const Color inputFill = Color(0xFF152030);

  // ─────────────────────────────────────────────
  // Primary — Amber Gold
  // ─────────────────────────────────────────────
  static const Color primary = Color(0xFFF4A228);
  static const Color primaryLight = Color(0xFFFFBF4D);
  static const Color primaryDark = Color(0xFFD4831A);
  static const Color primaryContainer = Color(0xFF3A2800);

  // ─────────────────────────────────────────────
  // Secondary — Sky Blue
  // ─────────────────────────────────────────────
  static const Color secondary = Color(0xFF4CC9F0);
  static const Color secondaryDark = Color(0xFF2A9DC7);

  // ─────────────────────────────────────────────
  // Accent — Purple
  // ─────────────────────────────────────────────
  static const Color accent = Color(0xFF7B2FBE);
  static const Color accentLight = Color(0xFF9B59E6);

  // ─────────────────────────────────────────────
  // Text
  // ─────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF8F9FA);
  static const Color textSecondary = Color(0xFFADB5BD);
  static const Color textMuted = Color(0xFF6C757D);
  static const Color textInverse = Color(0xFF080F1A);

  // ─────────────────────────────────────────────
  // Semantic Status
  // ─────────────────────────────────────────────
  static const Color success = Color(0xFF06D6A0);
  static const Color successBg = Color(0xFF0A2E25);
  static const Color warning = Color(0xFFFFB703);
  static const Color warningBg = Color(0xFF2E2100);
  static const Color error = Color(0xFFE63946);
  static const Color errorBg = Color(0xFF2E0A0D);

  // ─────────────────────────────────────────────
  // Borders & Dividers
  // ─────────────────────────────────────────────
  static const Color border = Color(0xFF1E2D42);
  static const Color divider = Color(0xFF1A2535);

  // ─────────────────────────────────────────────
  // Shimmer
  // ─────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFF1A2535);
  static const Color shimmerHighlight = Color(0xFF243047);

  // ─────────────────────────────────────────────
  // Overlays
  // ─────────────────────────────────────────────
  static const Color overlay = Color(0xCC000000);
  static const Color overlayLight = Color(0x66000000);

  // ─────────────────────────────────────────────
  // Gradients
  // ─────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFF4A228), Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGold = LinearGradient(
    colors: [Color(0xFFF4A228), Color(0xFFD4831A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coolBlue = LinearGradient(
    colors: [Color(0xFF4CC9F0), Color(0xFF7B2FBE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF080F1A), Color(0xFF111827)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E2D42), Color(0xFF1A2535)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroOverlay = LinearGradient(
    colors: [Color(0x00000000), Color(0xE6000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
