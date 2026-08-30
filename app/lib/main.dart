import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'core/bindings/app_binding.dart';
import 'features/home/views/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar GetStorage antes de criar o app
  await GetStorage.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NR Fácil',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialBinding: AppBinding(),
      home: const HomePage(),
    );
  }
}
