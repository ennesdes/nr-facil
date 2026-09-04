import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../constants/storage_keys.dart';

/// Controla o tema global do app (system / light / dark).
class ThemeController extends GetxController {
  final _storage = GetStorage();

  final themeMode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    themeMode.value = _loadThemeMode();
  }

  bool get isDarkMode {
    switch (themeMode.value) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return Get.isPlatformDarkMode;
    }
  }

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    _storage.write(StorageKeys.appThemeMode, mode.name);
  }

  void toggleDarkMode() {
    setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  ThemeMode _loadThemeMode() {
    final stored = _storage.read<String>(StorageKeys.appThemeMode);
    if (stored != null) {
      return ThemeMode.values.firstWhere(
        (m) => m.name == stored,
        orElse: () => ThemeMode.system,
      );
    }

    // Migração: preferência antiga do leitor
    final legacyDark = _storage.read<bool>(StorageKeys.readerDarkMode);
    if (legacyDark != null) {
      final mode = legacyDark ? ThemeMode.dark : ThemeMode.light;
      _storage.write(StorageKeys.appThemeMode, mode.name);
      return mode;
    }

    return ThemeMode.system;
  }
}
