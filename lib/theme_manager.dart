import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends GetxController {
  static ThemeManager get to => Get.find();

  final _isDarkMode = false.obs;
  final _currentLanguage = 'en'.obs;

  bool get isDarkMode => _isDarkMode.value;
  String get currentLanguage => _currentLanguage.value;

  @override
  void onInit() {
    super.onInit();
    loadThemePreference();
    loadLanguagePreference();
  }

  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode.value = prefs.getBool('isDarkMode') ?? false;
  }

  Future<void> toggleTheme() async {
    _isDarkMode.toggle();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode.value);
  }

  Future<void> loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage.value = prefs.getString('language') ?? 'en';
  }

  Future<void> saveLanguagePreference(String language) async {
    _currentLanguage.value = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
  }
}