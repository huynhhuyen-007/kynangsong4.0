import 'package:flutter/material.dart';

/// Responsive helper — dùng trong toàn bộ app để layout
/// không bị vỡ trên các màn hình khác nhau.
///
/// Cách dùng:
///   final r = Responsive.of(context);
///   padding: EdgeInsets.all(r.md)
///   fontSize: r.textMd
class Responsive {
  final double screenWidth;
  final double screenHeight;
  final double pixelRatio;

  Responsive._({
    required this.screenWidth,
    required this.screenHeight,
    required this.pixelRatio,
  });

  factory Responsive.of(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Responsive._(
      screenWidth: mq.size.width,
      screenHeight: mq.size.height,
      pixelRatio: mq.devicePixelRatio,
    );
  }

  // ── Breakpoints ────────────────────────────────────────────
  bool get isSmall => screenWidth < 360;   // màn nhỏ (dưới 360px)
  bool get isMedium => screenWidth < 414;  // trung bình (360–414)
  bool get isLarge => screenWidth >= 414;  // lớn (iPhone Plus, nhiều Android)

  // ── Spacing ────────────────────────────────────────────────
  /// Khoảng cách nhỏ (4–6)
  double get xs => isSmall ? 4 : 6;

  /// Khoảng cách thường (8–12)
  double get sm => isSmall ? 8 : (isMedium ? 10 : 12);

  /// Khoảng cách vừa (14–18)
  double get md => isSmall ? 14 : (isMedium ? 16 : 18);

  /// Khoảng cách lớn (20–28)
  double get lg => isSmall ? 20 : (isMedium ? 24 : 28);

  /// Khoảng cách rất lớn (28–36)
  double get xl => isSmall ? 28 : (isMedium ? 32 : 36);

  // ── Font sizes ─────────────────────────────────────────────
  double get textXs => isSmall ? 10 : 11;
  double get textSm => isSmall ? 12 : 13;
  double get textMd => isSmall ? 13 : (isMedium ? 14 : 15);
  double get textLg => isSmall ? 16 : (isMedium ? 17 : 18);
  double get textXl => isSmall ? 20 : (isMedium ? 22 : 24);
  double get textH1 => isSmall ? 24 : (isMedium ? 26 : 28);

  // ── Layout ─────────────────────────────────────────────────
  /// Padding ngang của content chính
  double get hPad => isSmall ? 12 : (isMedium ? 16 : 20);

  /// Chiều cao card/button
  double get cardHeight => isSmall ? 48 : 56;

  /// Border radius thường
  double get radius => isSmall ? 12 : 16;

  /// Icon size thường
  double get iconMd => isSmall ? 20 : 24;
  double get iconLg => isSmall ? 28 : 32;

  // ── Safe area aware height ─────────────────────────────────
  double get safeHeight => screenHeight;
}

/// Extension tiện lợi để dùng trực tiếp từ context
extension ResponsiveContext on BuildContext {
  Responsive get r => Responsive.of(this);
}
