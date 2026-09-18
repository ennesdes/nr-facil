import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:nrfacil/core/constants/storage_keys.dart';
import 'package:nrfacil/features/home/views/home_page.dart';
import 'package:nrfacil/features/reader/views/nr_reader_page.dart';
import 'package:nrfacil/features/search/views/search_page.dart';
import 'package:nrfacil/features/settings/views/settings_page.dart';
import 'package:nrfacil/features/updates/views/updates_page.dart';

const _storagePresetValues = ['fresh', 'withFavorite'];

const _navigateScreenValues = [
  'home',
  'reader_nr25',
  'search',
  'settings',
  'updates',
];

/// Presets de storage para Marionette (checkpoints).
///
/// Cada preset restaura o app para um estado conhecido.
/// 'fresh' é o baseline inicial; 'withFavorite' tem uma NR favoritada.
sealed class _StoragePreset {
  const _StoragePreset();

  static const fresh = _FreshPreset();
  static const withFavorite = _WithFavoritePreset();

  static _StoragePreset? fromName(String name) {
    switch (name) {
      case 'fresh':
        return fresh;
      case 'withFavorite':
        return withFavorite;
      default:
        return null;
    }
  }

  Map<String, dynamic> toMap();
}

class _FreshPreset extends _StoragePreset {
  const _FreshPreset();

  @override
  Map<String, dynamic> toMap() => {'preset': 'fresh', 'cleared': true};
}

class _WithFavoritePreset extends _StoragePreset {
  const _WithFavoritePreset();

  @override
  Map<String, dynamic> toMap() => {
    'preset': 'withFavorite',
    'favorites': ['nr-25'],
  };
}

/// Aplica preset de storage para Marionette.
///
/// Sempre requer hot_restart após para que o app recarregue os dados.
Future<Map<String, dynamic>> _applyStoragePreset(
  _StoragePreset preset,
  GetStorage storage,
) async {
  if (preset is _FreshPreset) {
    // Limpar todos os dados
    await storage.erase();
    return preset.toMap();
  }

  if (preset is _WithFavoritePreset) {
    await storage.erase();
    // Seed uma NR como favorita
    await storage.write(StorageKeys.favoriteNrs, ['nr-25']);
    await storage.write(StorageKeys.appThemeMode, 'system');
    return preset.toMap();
  }

  return {'error': 'Unknown preset'};
}

/// Registra extensions Marionette de debug — chamar só em [kDebugMode].
void registerMarionetteDebugExtensions() {
  assert(kDebugMode);

  registerMarionetteExtension(
    name: 'debug.resetStorage',
    description: 'Aplica preset de storage (checkpoint Marionette). Requer hot_restart depois.',
    inputSchema: const ExtensionInputSchema(
      properties: {
        'preset': ExtensionParam.string(
          description: 'Checkpoint de storage.',
          enumValues: _storagePresetValues,
        ),
      },
      required: ['preset'],
    ),
    callback: (params) async {
      final presetName = params['preset'];
      if (presetName == null || presetName.isEmpty) {
        return const MarionetteExtensionResult.invalidParams('Missing preset');
      }

      final preset = _StoragePreset.fromName(presetName);
      if (preset == null) {
        return MarionetteExtensionResult.invalidParams(
          'Invalid preset: $presetName',
        );
      }

      try {
        final result = await _applyStoragePreset(preset, GetStorage());
        return MarionetteExtensionResult.success(result);
      } catch (e) {
        return MarionetteExtensionResult.error(0, 'Storage preset failed: $e');
      }
    },
  );

  registerMarionetteExtension(
    name: 'debug.navigateTo',
    description:
        'Navega para tela (offAll). Opcionalmente aplica preset antes.',
    inputSchema: const ExtensionInputSchema(
      properties: {
        'screen': ExtensionParam.string(
          description: 'Tela para navegar (home | reader_nr25 | search | settings | updates).',
          enumValues: _navigateScreenValues,
        ),
        'preset': ExtensionParam.string(
          description: 'Preset de storage opcional antes de navegar.',
          enumValues: _storagePresetValues,
        ),
      },
      required: ['screen'],
    ),
    callback: (params) async {
      final screen = params['screen'];
      if (screen == null || screen.isEmpty) {
        return const MarionetteExtensionResult.invalidParams('Missing screen');
      }

      if (!_navigateScreenValues.contains(screen)) {
        return MarionetteExtensionResult.invalidParams(
          'Invalid screen: $screen',
        );
      }

      // Aplicar preset se fornecido
      Map<String, dynamic>? storageResult;
      final presetName = params['preset'];
      if (presetName != null && presetName.isNotEmpty) {
        final preset = _StoragePreset.fromName(presetName);
        if (preset == null) {
          return MarionetteExtensionResult.invalidParams(
            'Invalid preset: $presetName',
          );
        }
        storageResult = await _applyStoragePreset(preset, GetStorage());
      }

      // Navegar
      try {
        switch (screen) {
          case 'home':
            Get.offAll(() => const HomePage());
          case 'reader_nr25':
            Get.offAll(() => const NRReaderPage(nrId: 'nr-25'));
          case 'search':
            Get.offAll(() => const SearchPage());
          case 'settings':
            Get.offAll(() => const SettingsPage());
          case 'updates':
            Get.offAll(() => const UpdatesPage());
          default:
            return MarionetteExtensionResult.invalidParams(
              'Unknown screen: $screen',
            );
        }

        final response = <String, dynamic>{'screen': screen};
        if (storageResult case final result?) {
          response['storage'] = result;
        }
        return MarionetteExtensionResult.success(response);
      } catch (e) {
        return MarionetteExtensionResult.error(0, 'Navigation failed: $e');
      }
    },
  );
}
