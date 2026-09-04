import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Configuração global dos testes Flutter.
Future<void> testExecutable(Future<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
