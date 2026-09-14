import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// WanderAI Typography
/// Display / Headline / Title: Outfit (bold, expressive)
/// Body / Label: Inter (clean, readable)
sealed class AppTextStyles {
  AppTextStyles._();

  // ─────────────────────────────────────────────
  // Display — Outfit
  // ─────────────────────────────────────────────

  static TextStyle displayLarge = GoogleFonts.outfit(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.1,
  );

  static TextStyle displayMedium = GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.15,
  );

  static TextStyle displaySmall = GoogleFonts.outfit(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.2,
  );

  // ─────────────────────────────────────────────
  // Headlines — Outfit
  // ─────────────────────────────────────────────

  static TextStyle headlineLarge = GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static TextStyle headlineMedium = GoogleFonts.outfit(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle headlineSmall = GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  // ─────────────────────────────────────────────
  // Titles — Outfit
  // ─────────────────────────────────────────────

  static TextStyle titleLarge = GoogleFonts.outfit(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle titleMedium = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle titleSmall = GoogleFonts.outfit(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // ─────────────────────────────────────────────
  // Body — Inter
  // ─────────────────────────────────────────────

  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.5,
  );

  // ─────────────────────────────────────────────
  // Labels — Inter
  // ─────────────────────────────────────────────

  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
    height: 1.4,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
    height: 1.4,
  );

  // ─────────────────────────────────────────────
  // Specialised
  // ─────────────────────────────────────────────

  /// Large match score percentage
  static TextStyle scoreDisplay = GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
    height: 1.0,
  );

  /// Rating chip
  static TextStyle rating = GoogleFonts.outfit(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  /// Emoji / icon label
  static TextStyle chip = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  /// Button text
  static TextStyle button = GoogleFonts.outfit(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textInverse,
    letterSpacing: 0.2,
    height: 1.2,
  );

  /// Code / monospace
  static TextStyle mono = GoogleFonts.sourceCodePro(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );
}
