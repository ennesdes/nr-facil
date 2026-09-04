import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Cores semânticas fora do [ColorScheme] padrão do Material 3.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.warningContainer,
    required this.info,
    required this.infoContainer,
    required this.revoked,
  });

  final Color success;
  final Color warning;
  final Color warningContainer;
  final Color info;
  final Color infoContainer;
  final Color revoked;

  static const light = AppSemanticColors(
    success: AppColors.success,
    warning: AppColors.warning,
    warningContainer: AppColors.warningContainer,
    info: AppColors.info,
    infoContainer: AppColors.infoContainer,
    revoked: AppColors.revoked,
  );

  static const dark = AppSemanticColors(
    success: AppColors.successDark,
    warning: AppColors.warningDark,
    warningContainer: AppColors.warningContainerDark,
    info: AppColors.infoDark,
    infoContainer: AppColors.infoContainerDark,
    revoked: AppColors.revokedDark,
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? warningContainer,
    Color? info,
    Color? infoContainer,
    Color? revoked,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      revoked: revoked ?? this.revoked,
    );
  }

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      revoked: Color.lerp(revoked, other.revoked, t)!,
    );
  }
}
