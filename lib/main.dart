import 'package:advanced_dictionary/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import 'history_manager.dart';
import 'home_page.dart';

void main() {
  Get.put(HistoryManager());
  Get.put(ThemeManager());
  runApp(const VocabVault());
}

class VocabVault extends StatelessWidget {
  const VocabVault({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'VocabVault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: HomePage(),
    );
  }
}
