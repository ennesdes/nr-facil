import 'package:flutter/material.dart';

import 'app_safe_area.dart';

/// Exibe um bottom sheet respeitando a barra de navegação do sistema.
Future<T?> showAppModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool respondToKeyboard = false,
  Color? backgroundColor,
  ShapeBorder? shape,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: backgroundColor,
    shape: shape,
    useSafeArea: false,
    builder: (sheetContext) => AppBottomSheetBody(
      respondToKeyboard: respondToKeyboard,
      child: builder(sheetContext),
    ),
  );
}
