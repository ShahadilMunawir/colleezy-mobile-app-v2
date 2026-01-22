import 'package:flutter/material.dart';

/// Responsive utility class for scaling UI elements based on screen size
/// Uses a base design width of 375dp (iPhone X standard)
class Responsive {
  final BuildContext context;
  final double baseWidth = 375.0; // Base design width (iPhone X)
  final double minScale = 0.85; // Minimum scale factor for very small screens
  final double maxScale = 1.2; // Maximum scale factor for very large screens

  Responsive(this.context);

  /// Get the current screen width
  double get screenWidth => MediaQuery.of(context).size.width;

  /// Get the current screen height
  double get screenHeight => MediaQuery.of(context).size.height;

  /// Calculate scale factor based on screen width
  double get _scaleFactor {
    double factor = screenWidth / baseWidth;
    // Clamp the scale factor between min and max
    return factor.clamp(minScale, maxScale);
  }

  /// Scale width values based on screen size
  double width(double value) => value * _scaleFactor;

  /// Scale height values based on screen size
  double height(double value) => value * _scaleFactor;

  /// Scale font sizes based on screen size
  double fontSize(double value) => value * _scaleFactor;

  /// Scale padding values based on screen size
  double padding(double value) => value * _scaleFactor;

  /// Scale border radius values based on screen size
  double radius(double value) => value * _scaleFactor;

  /// Scale spacing values (SizedBox height/width) based on screen size
  double spacing(double value) => value * _scaleFactor;

  /// Get responsive padding EdgeInsets
  EdgeInsets paddingAll(double value) => EdgeInsets.all(padding(value));

  /// Get responsive padding EdgeInsets symmetric
  EdgeInsets paddingSymmetric({double? horizontal, double? vertical}) {
    return EdgeInsets.symmetric(
      horizontal: horizontal != null ? padding(horizontal) : 0,
      vertical: vertical != null ? padding(vertical) : 0,
    );
  }

  /// Get responsive padding EdgeInsets only
  EdgeInsets paddingOnly({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return EdgeInsets.only(
      left: left != null ? padding(left) : 0,
      top: top != null ? padding(top) : 0,
      right: right != null ? padding(right) : 0,
      bottom: bottom != null ? padding(bottom) : 0,
    );
  }

  /// Get responsive padding EdgeInsets fromLTRB
  EdgeInsets paddingFromLTRB(double left, double top, double right, double bottom) {
    return EdgeInsets.fromLTRB(
      padding(left),
      padding(top),
      padding(right),
      padding(bottom),
    );
  }

  /// Check if screen is small (< 360dp)
  bool get isSmallScreen => screenWidth < 360;

  /// Check if screen is regular (360-420dp)
  bool get isRegularScreen => screenWidth >= 360 && screenWidth < 420;

  /// Check if screen is large (>= 420dp)
  bool get isLargeScreen => screenWidth >= 420;

  /// Get percentage of screen width
  double widthPercent(double percent) => screenWidth * (percent / 100);

  /// Get percentage of screen height
  double heightPercent(double percent) => screenHeight * (percent / 100);
}

/// Extension to easily access Responsive from BuildContext
extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive(this);
}
