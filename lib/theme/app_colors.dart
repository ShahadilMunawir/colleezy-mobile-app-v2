import 'package:flutter/material.dart';

/// App color palette
/// Contains all color constants used throughout the application
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary Colors
  static const Color primary = Color(0xFF2D7A4F);

  // Background Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEFEEEC);

  // Text Colors
  static const Color textPrimary = Color(0xFF2D3142);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Border & Divider Colors
  static const Color divider = Color(0xFFE5E7EB);

  // Shadow Colors
  static const Color shadow = Color(0x0A000000); // 4% opacity (Colors.black.withOpacity(0.04))
}

