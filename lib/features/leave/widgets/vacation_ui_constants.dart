/// Vacation Recommendation Popup UI 상수 및 스타일
///
/// GPT 스타일의 모던한 UI를 위한 색상, 크기, 그림자 등 디자인 상수

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 반응형 스케일링 유틸리티
/// 화면 크기에 따라 UI 요소들의 크기를 비례적으로 조절
class ResponsiveScale {
  // 기준 화면 크기 (1920x1080 기준)
  static const double baseWidth = 1920.0;
  static const double baseHeight = 1080.0;

  // 스케일 범위 제한 (너무 작거나 크지 않도록)
  static const double minScale = 0.85;  // 작은 화면에서도 더 큰 크기 유지
  static const double maxScale = 1.4;

  // 폰트 크기 보정값 (전체적으로 글자 크기 증가)
  static const double fontSizeBoost = 2.0;

  /// 화면 크기에 따른 scale factor 계산
  /// [context] BuildContext
  /// [useWidth] true면 너비 기준, false면 높이 기준, null이면 둘 중 작은 값
  static double getScaleFactor(BuildContext context, {bool? useWidth}) {
    final size = MediaQuery.of(context).size;

    double scale;
    if (useWidth == true) {
      scale = size.width / baseWidth;
    } else if (useWidth == false) {
      scale = size.height / baseHeight;
    } else {
      // 둘 중 작은 값 사용 (비율 유지)
      final widthScale = size.width / baseWidth;
      final heightScale = size.height / baseHeight;
      scale = math.min(widthScale, heightScale);
    }

    // 범위 제한
    return scale.clamp(minScale, maxScale);
  }

  /// 스케일된 값 반환 (fontSize, padding 등에 사용)
  static double scaled(BuildContext context, double value, {bool? useWidth}) {
    return value * getScaleFactor(context, useWidth: useWidth);
  }

  /// 스케일된 폰트 크기 (기본 +2 보정, 최소 12)
  static double fontSize(BuildContext context, double baseSize) {
    final boostedSize = baseSize + fontSizeBoost;  // 기본 크기에 2 추가
    final scaledSize = scaled(context, boostedSize);
    return math.max(12.0, scaledSize); // 최소 12px
  }

  /// 스케일된 아이콘 크기 (기본 +1 보정, 최소 14)
  static double iconSize(BuildContext context, double baseSize) {
    final boostedSize = baseSize + 1.0;  // 아이콘도 약간 키움
    final scaledSize = scaled(context, boostedSize);
    return math.max(14.0, scaledSize); // 최소 14px
  }

  /// 스케일된 패딩
  static EdgeInsets padding(
    BuildContext context, {
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) {
    final scale = getScaleFactor(context);

    if (all != null) {
      return EdgeInsets.all(all * scale);
    }

    return EdgeInsets.only(
      left: (left ?? horizontal ?? 0) * scale,
      right: (right ?? horizontal ?? 0) * scale,
      top: (top ?? vertical ?? 0) * scale,
      bottom: (bottom ?? vertical ?? 0) * scale,
    );
  }

  /// 스케일된 대칭 패딩
  static EdgeInsets symmetricPadding(
    BuildContext context, {
    double horizontal = 0,
    double vertical = 0,
  }) {
    final scale = getScaleFactor(context);
    return EdgeInsets.symmetric(
      horizontal: horizontal * scale,
      vertical: vertical * scale,
    );
  }

  /// 스케일된 BorderRadius
  static BorderRadius borderRadius(BuildContext context, double radius) {
    return BorderRadius.circular(scaled(context, radius));
  }

  /// 스케일된 SizedBox (width)
  static SizedBox width(BuildContext context, double value) {
    return SizedBox(width: scaled(context, value));
  }

  /// 스케일된 SizedBox (height)
  static SizedBox height(BuildContext context, double value) {
    return SizedBox(height: scaled(context, value));
  }

  /// 스케일된 BoxConstraints
  static BoxConstraints constraints(
    BuildContext context, {
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
  }) {
    final scale = getScaleFactor(context);
    return BoxConstraints(
      minWidth: (minWidth ?? 0) * scale,
      maxWidth: (maxWidth ?? double.infinity) * scale,
      minHeight: (minHeight ?? 0) * scale,
      maxHeight: (maxHeight ?? double.infinity) * scale,
    );
  }
}

/// Extension을 통한 간편한 사용
extension ResponsiveContext on BuildContext {
  /// 스케일 팩터 가져오기
  double get scaleFactor => ResponsiveScale.getScaleFactor(this);

  /// 스케일된 값
  double rs(double value) => ResponsiveScale.scaled(this, value);

  /// 스케일된 폰트 크기
  double rfs(double baseSize) => ResponsiveScale.fontSize(this, baseSize);

  /// 스케일된 아이콘 크기
  double ris(double baseSize) => ResponsiveScale.iconSize(this, baseSize);

  /// 스케일된 패딩
  EdgeInsets rp({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) =>
      ResponsiveScale.padding(
        this,
        all: all,
        horizontal: horizontal,
        vertical: vertical,
        left: left,
        right: right,
        top: top,
        bottom: bottom,
      );

  /// 스케일된 대칭 패딩
  EdgeInsets rsp({double horizontal = 0, double vertical = 0}) =>
      ResponsiveScale.symmetricPadding(this,
          horizontal: horizontal, vertical: vertical);

  /// 스케일된 BorderRadius
  BorderRadius rbr(double radius) =>
      ResponsiveScale.borderRadius(this, radius);

  /// 스케일된 SizedBox (width)
  SizedBox rsw(double value) => ResponsiveScale.width(this, value);

  /// 스케일된 SizedBox (height)
  SizedBox rsh(double value) => ResponsiveScale.height(this, value);
}

/// 색상 팔레트
class VacationUIColors {
  // 메인 그라데이션 (보라-분홍)
  static const primaryGradient = [Color(0xFF667EEA), Color(0xFF764BA2)];

  // 액센트 그라데이션 (진행률바용 - 3색상)
  static const accentGradient = [
    Color(0xFF667EEA),
    Color(0xFF764BA2),
    Color(0xFFFA8BFF)
  ];

  // Light 배경 그라데이션
  static const lightBackgroundGradient = [
    Color(0xFFFAFAFA),
    Color(0xFFFFFFFF),
    Color(0xFFF5F5F7)
  ];

  // Dark 배경 그라데이션
  static const darkBackgroundGradient = [
    Color(0xFF1A1A1A),
    Color(0xFF2D2D2D),
    Color(0xFF242424)
  ];

  // 카드 배경 (Light)
  static const lightCardGradient = [Color(0xFFFFFFFF), Color(0xFFFAFAFA)];

  // 카드 배경 (Dark)
  static const darkCardGradient = [Color(0xFF3A3A3A), Color(0xFF323232)];
}

/// Border Radius 시스템
class VacationUIRadius {
  static const small = 12.0;
  static const medium = 16.0;
  static const large = 20.0;
  static const xLarge = 24.0;
}

/// Spacing 시스템
class VacationUISpacing {
  static const paddingXL = 24.0;
  static const paddingXXL = 32.0;
  static const marginXL = 28.0;
  static const marginXXL = 32.0;
}

/// BoxShadow 프리셋
class VacationUIShadows {
  /// 모달 그림자 (플로팅 효과)
  static List<BoxShadow> modalShadow(bool isDark) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.08),
          blurRadius: 40,
          spreadRadius: 0,
          offset: const Offset(0, 20),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.04),
          blurRadius: 20,
          spreadRadius: -5,
          offset: const Offset(0, 10),
        ),
      ];

  /// 카드 그림자 (elevated card)
  static List<BoxShadow> cardShadow(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.3)
              : const Color(0xFF667EEA).withValues(alpha: 0.08),
          blurRadius: 24,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ];

  /// 아이콘 글로우 효과
  static List<BoxShadow> iconGlowShadow() => [
        BoxShadow(
          color: const Color(0xFF667EEA).withValues(alpha: 0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}
