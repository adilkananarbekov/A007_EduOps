import 'package:flutter/material.dart';

/// Design tokens extracted from the EduOps Web design theme.css
class AppColors {
  AppColors._();

  // ─── Primary ─────────────────────────────────────────────
  static const Color primary = Color(0xFFDA0B25);
  static const Color primaryForeground = Color(0xFFFFFFFF);

  // ─── Foreground / Text ───────────────────────────────────
  static const Color foreground = Color(0xFF1A1A1A);
  static const Color mutedForeground = Color(0xFF666666);

  // ─── Accent ──────────────────────────────────────────────
  static const Color accent = Color(0xFF1E40AF);
  static const Color accentForeground = Color(0xFFFFFFFF);

  // ─── Surfaces ────────────────────────────────────────────
  static const Color background = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFFF5F5F5);
  static const Color border = Color(0xFFE5E5E5);

  // ─── Destructive (same hue as primary) ───────────────────
  static const Color destructive = Color(0xFFDA0B25);
  static const Color destructiveForeground = Color(0xFFFFFFFF);

  // ─── Semantic: Green ─────────────────────────────────────
  static const Color greenBg = Color(0xFFF0FDF4);
  static const Color greenText = Color(0xFF15803D);
  static const Color greenBorder = Color(0xFFBBF7D0);

  // ─── Semantic: Yellow ────────────────────────────────────
  static const Color yellowBg = Color(0xFFFEFCE8);
  static const Color yellowText = Color(0xFFA16207);
  static const Color yellowBorder = Color(0xFFFEF08A);

  // ─── Semantic: Red ───────────────────────────────────────
  static const Color redBg = Color(0xFFFEF2F2);
  static const Color redText = Color(0xFFDA0B25);
  static const Color redBorder = Color(0xFFFECACA);

  // ─── Sidebar ─────────────────────────────────────────────
  static const Color sidebar = Color(0xFFFFFFFF);
  static const Color sidebarForeground = Color(0xFF666666);
  static const Color sidebarBorder = Color(0xFFE5E5E5);
}
