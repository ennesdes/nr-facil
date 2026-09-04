import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/widgets/app_safe_area.dart';
import 'package:nrfacil/features/search/controllers/search_screen_controller.dart';
import 'package:nrfacil/features/search/views/search_tab.dart';

/// Wrapper com Scaffold para uso fora da HomePage (ex.: testes).
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar'),
        elevation: 1,
      ),
      body: AppScaffoldBody(
        child: SearchTab(
          isActive: true,
          key: ValueKey(Get.find<SearchScreenController>().hashCode),
        ),
      ),
    );
  }
}
