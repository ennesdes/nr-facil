import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Cores semânticas fora do [ColorScheme] padrão do Material 3.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.revoked,
    required this.searchHighlight,
    required this.onSearchHighlight,
    required this.muted,
  });

  final Color success;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color revoked;
  final Color searchHighlight;
  final Color onSearchHighlight;
  final Color muted;

  static const light = AppSemanticColors(
    success: AppColors.success,
    warning: AppColors.warning,
    warningContainer: AppColors.warningContainer,
    onWarningContainer: AppColors.onWarningContainer,
    info: AppColors.info,
    infoContainer: AppColors.infoContainer,
    onInfoContainer: AppColors.onInfoContainer,
    revoked: AppColors.revoked,
    searchHighlight: AppColors.searchHighlight,
    onSearchHighlight: AppColors.onSearchHighlight,
    muted: AppColors.muted,
  );

  static const dark = AppSemanticColors(
    success: AppColors.successDark,
    warning: AppColors.warningDark,
    warningContainer: AppColors.warningContainerDark,
    onWarningContainer: AppColors.onWarningContainerDark,
    info: AppColors.infoDark,
    infoContainer: AppColors.infoContainerDark,
    onInfoContainer: AppColors.onInfoContainerDark,
    revoked: AppColors.revokedDark,
    searchHighlight: AppColors.searchHighlightDark,
    onSearchHighlight: AppColors.onSearchHighlightDark,
    muted: AppColors.mutedDark,
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? revoked,
    Color? searchHighlight,
    Color? onSearchHighlight,
    Color? muted,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      revoked: revoked ?? this.revoked,
      searchHighlight: searchHighlight ?? this.searchHighlight,
      onSearchHighlight: onSearchHighlight ?? this.onSearchHighlight,
      muted: muted ?? this.muted,
    );
  }

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      revoked: Color.lerp(revoked, other.revoked, t)!,
      searchHighlight: Color.lerp(searchHighlight, other.searchHighlight, t)!,
      onSearchHighlight:
          Color.lerp(onSearchHighlight, other.onSearchHighlight, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
    );
  }
}
