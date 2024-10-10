import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryManager extends GetxController {
  static HistoryManager get to => Get.find();

  final _searchHistory = <String>[].obs;
  final _favorites = <String>[].obs;

  List<String> get searchHistory => _searchHistory;
  List<String> get favorites => _favorites;

  @override
  void onInit() {
    super.onInit();
    loadSearchHistory();
    loadFavorites();
  }

  Future<void> loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('searchHistory') ?? [];
    _searchHistory.assignAll(history);
  }

  Future<void> addToSearchHistory(String word) async {
    if (!_searchHistory.contains(word)) {
      _searchHistory.insert(0, word);
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('searchHistory', _searchHistory);
    }
  }

  Future<void> removeFromSearchHistory(int index) async {
    _searchHistory.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('searchHistory', _searchHistory.toList());
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('favorites') ?? [];
    _favorites.assignAll(favs);
  }

  Future<void> toggleFavorite(String word) async {
    if (_favorites.contains(word)) {
      _favorites.remove(word);
    } else {
      _favorites.add(word);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites.toList());
  }

  Future<void> removeFromFavorites(int index) async {
    _favorites.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites.toList());
  }
}