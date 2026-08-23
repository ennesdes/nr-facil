import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum _AppSnackbarVariant { success, info, warning, error }

/// Snackbar único do app — nunca `Get.snackbar` / `SnackBar` inline, sempre
/// este wrapper.
///
/// Não depende de `ScaffoldMessenger`: exibe via `Overlay` raiz do
/// `GetMaterialApp`, então funciona em qualquer tela sem precisar de um
/// `Scaffold` local.
class AppSnackbar {
  AppSnackbar._();

  static const Duration _durationSimple = Duration(seconds: 3);
  static const Duration _durationImportant = Duration(seconds: 4);
  static const Duration _animationDuration = Duration(milliseconds: 250);

  static OverlayEntry? _entry;
  static Timer? _dismissTimer;
  static _AppSnackbarOverlayState? _activeState;

  static void showSuccess({required String title, String? message, Duration? duration}) =>
      _present(
        variant: _AppSnackbarVariant.success,
        title: title,
        message: message,
        duration: duration ?? _durationSimple,
      );

  static void showInfo({required String title, String? message, Duration? duration}) =>
      _present(
        variant: _AppSnackbarVariant.info,
        title: title,
        message: message,
        duration: duration ?? _durationSimple,
      );

  static void showWarning({required String title, String? message, Duration? duration}) =>
      _present(
        variant: _AppSnackbarVariant.warning,
        title: title,
        message: message,
        duration: duration ?? _durationImportant,
      );

  static void showError({required String title, String? message, Duration? duration}) =>
      _present(
        variant: _AppSnackbarVariant.error,
        title: title,
        message: message,
        duration: duration ?? _durationImportant,
      );

  static void _present({
    required _AppSnackbarVariant variant,
    required String title,
    String? message,
    required Duration duration,
  }) {
    final overlay = _resolveOverlay();
    if (overlay == null) return;

    unawaited(_dismiss());

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _AppSnackbarOverlay(
        variant: variant,
        title: title,
        message: message,
        onDismissed: () {
          entry.remove();
          if (_entry == entry) {
            _entry = null;
            _activeState = null;
          }
        },
        onStateCreated: (state) => _activeState = state,
      ),
    );

    _entry = entry;
    overlay.insert(entry);

    _dismissTimer?.cancel();
    _dismissTimer = Timer(duration, () => unawaited(_dismiss()));
  }

  /// Overlay raiz do `GetMaterialApp` — não depende de um `Scaffold` local.
  static OverlayState? _resolveOverlay() {
    final rootOverlay = Get.key.currentState?.overlay;
    if (rootOverlay != null) return rootOverlay;

    final context = Get.context ?? Get.overlayContext;
    if (context == null) return null;

    try {
      return Overlay.of(context, rootOverlay: true);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _dismiss() async {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    final state = _activeState;
    if (state != null) {
      await state.animateOut();
      return;
    }

    _entry?.remove();
    _entry = null;
    _activeState = null;
  }

  static void _clearState(_AppSnackbarOverlayState state) {
    if (_activeState == state) _activeState = null;
  }
}

class _AppSnackbarOverlay extends StatefulWidget {
  const _AppSnackbarOverlay({
    required this.variant,
    required this.title,
    required this.message,
    required this.onDismissed,
    required this.onStateCreated,
  });

  final _AppSnackbarVariant variant;
  final String title;
  final String? message;
  final VoidCallback onDismissed;
  final ValueChanged<_AppSnackbarOverlayState> onStateCreated;

  @override
  State<_AppSnackbarOverlay> createState() => _AppSnackbarOverlayState();
}

class _AppSnackbarOverlayState extends State<_AppSnackbarOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppSnackbar._animationDuration,
      reverseDuration: const Duration(milliseconds: 150),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    widget.onStateCreated(this);
    unawaited(_controller.forward());
  }

  Future<void> animateOut() async {
    if (!mounted) return;
    await _controller.reverse();
    if (!mounted) return;
    widget.onDismissed();
    AppSnackbar._clearState(this);
  }

  @override
  void dispose() {
    _controller.dispose();
    AppSnackbar._clearState(this);
    super.dispose();
  }

  ({IconData icon, Color color}) _semantics(ColorScheme scheme) => switch (widget.variant) {
        _AppSnackbarVariant.success => (icon: Icons.check_circle_rounded, color: Colors.green.shade600),
        _AppSnackbarVariant.warning => (icon: Icons.warning_amber_rounded, color: Colors.orange.shade700),
        _AppSnackbarVariant.error => (icon: Icons.error_rounded, color: scheme.error),
        _AppSnackbarVariant.info => (icon: Icons.info_rounded, color: scheme.primary),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = _semantics(theme.colorScheme);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomInset + 12,
            child: SlideTransition(
              position: _slide,
              child: FadeTransition(
                opacity: _fade,
                child: GestureDetector(
                  onVerticalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity > 120) unawaited(animateOut());
                  },
                  child: Material(
                    color: theme.colorScheme.surfaceContainerHigh,
                    elevation: 6,
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(semantics.icon, size: 20, color: semantics.color),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(widget.title, style: theme.textTheme.titleSmall),
                                  if (widget.message != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.message!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
