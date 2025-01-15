import 'package:advanced_dictionary/quiz_controller.dart';
import 'package:advanced_dictionary/quiz_page.dart';
import 'package:advanced_dictionary/response_model.dart';
import 'package:advanced_dictionary/theme_manager.dart';
import 'package:flutter/material.dart';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api.dart';
import 'history_manager.dart';
import 'notification_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool inProgress = false;
  ResponseModel? responseModel;
  String noDataText = "Welcome, Start searching";
  final FlutterTts flutterTts = FlutterTts();
  List<String> searchHistory = [];
  List<String> favorites = [];
  final TextEditingController _searchController = TextEditingController();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool isDarkMode = false;
  String currentLanguage = 'en';
  String wordOfTheDay = '';
  String wordOfTheDayDefinition = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  NotificationManager notificationManager = NotificationManager();
  HistoryManager historyManager = Get.find<HistoryManager>();
  ThemeManager themeManager = Get.find<ThemeManager>();

  @override
  void initState() {
    super.initState();
    notificationManager.initializeNotifications();
    _fetchWordOfTheDay();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  Widget build(BuildContext context) {

    return  Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [Colors.grey[900]!, Colors.grey[800]!]
                : [Colors.blue[50]!, Colors.blue[100]!],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 375),
                childAnimationBuilder: (widget) => SlideAnimation(
                  horizontalOffset: 50.0,
                  child: FadeInAnimation(
                    child: widget,
                  ),
                ),
                children: [
                  _buildWordOfTheDayWidget(),
                  SizedBox(height: 20),
                  _buildLanguageDropdown(),
                  const SizedBox(height: 12),
                  _buildSearchWidget(),
                  const SizedBox(height: 12),
                  if (inProgress)
                    const LinearProgressIndicator()
                  else if (responseModel != null)
                    _buildResponseWidget()
                  else
                    _noDataWidget(),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.blue[700] : Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_stories,
              color: isDarkMode ? Colors.white : Colors.blue[700],
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'VocabVault',
            style: GoogleFonts.poppins(
              textStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 22,
              ),
            ),
          ),
        ],
      ),
      actions: [
        _buildActionButton(
          icon: Icons.history,
          onPressed: _showSearchHistory,
          tooltip: 'Search History',
        ),
        _buildActionButton(
          icon: Icons.favorite,
          onPressed: _showFavorites,
          tooltip: 'Favorites',
        ),
        _buildActionButton(
          icon: Icons.quiz,
          onPressed: _startQuiz,
          tooltip: 'Start Quiz',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        tooltip: tooltip,
        color: isDarkMode ? Colors.white : Colors.black87,
        iconSize: 22,
      ),
    );
  }

  Widget _buildWordOfTheDayWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode 
            ? [Colors.grey[800]!, Colors.grey[900]!]
            : [Colors.blue[50]!, Colors.blue[100]!],
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: isDarkMode ? Colors.amber[300] : Colors.amber[700],
              ),
              const SizedBox(width: 8),
              Text(
                'Word of the Day',
                style: GoogleFonts.lora(
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            wordOfTheDay,
            style: GoogleFonts.merriweather(
              textStyle: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.blue[200] : Colors.blue[700],
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            wordOfTheDayDefinition,
            style: GoogleFonts.lato(
              textStyle: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black87,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: Icon(Icons.volume_up),
                label: Text('Pronounce'),
                onPressed: () => _speak(wordOfTheDay),
                style: TextButton.styleFrom(
                  foregroundColor: isDarkMode ? Colors.blue[200] : Colors.blue[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[700] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: currentLanguage,
        items: [
          DropdownMenuItem(value: 'en', child: Text('English')),
          DropdownMenuItem(value: 'es', child: Text('Español')),
          DropdownMenuItem(value: 'fr', child: Text('Français')),
        ],
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              currentLanguage = newValue;
            });

            themeManager.obs.value.saveLanguagePreference(newValue);
          }
        },
        style: GoogleFonts.lato(
          textStyle: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
        icon: Icon(
          Icons.arrow_drop_down,
          color: isDarkMode ? Colors.white70 : Colors.black54,
        ),
        underline: const SizedBox(),
        dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
      ),
    );
  }

  Widget _buildSearchWidget() {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.lato(
          textStyle: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
        decoration: InputDecoration(
          hintText: "Search word here",
          hintStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
          prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.white70 : Colors.black54),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear, color: isDarkMode ? Colors.white70 : Colors.black54),
            onPressed: () {
              _searchController.clear();
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted:(value)=> _getMeaningFromApi(value)


      ),
    );
  }

  Widget _buildResponseWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(  // Changed from Expanded to Flexible
              child: Text(
                responseModel!.word!,
                style: GoogleFonts.playfairDisplay(
                  textStyle: TextStyle(
                    color: isDarkMode ? Colors.purple.shade300 : Colors.purple.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
              ),
            ),
            Row(
              children: [
               Obx(()=> IconButton(
                  icon: Icon(
                    historyManager.favorites.contains(responseModel!.word)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: () =>historyManager.toggleFavorite(responseModel!.word!),
                )),
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () => _speak(responseModel!.word!),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareWord(responseModel!.word!),
                ),
              ],
            ),
          ],
        ),
        if (responseModel!.phonetic != null)
          Text(
            responseModel!.phonetic!,
            style: GoogleFonts.lato(
              textStyle: TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
        const SizedBox(height: 24),
        ...responseModel!.meanings!.map((meaning) => _buildMeaningWidget(meaning)).toList(),
      ],
    );
  }

  Widget _buildMeaningWidget(Meanings meanings) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meanings.partOfSpeech!,
              style: GoogleFonts.lora(
                textStyle: TextStyle(
                  color: isDarkMode ? Colors.orange.shade300 : Colors.orange.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Definitions:",
              style: GoogleFonts.lato(
                textStyle: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return _buildDefinitionItem(
                    meanings.definitions![index], index + 1);
              },
              itemCount: meanings.definitions!.length,
            ),
            _buildSet("Synonyms", meanings.synonyms),
            _buildSet("Antonyms", meanings.antonyms),
          ],
        ),
      ),
    );
  }

  Widget _buildDefinitionItem(Definitions definition, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$index. ${definition.definition}",
            style: GoogleFonts.lato(
              textStyle: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
          ),
          if (definition.example != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 16),
              child: Text(
                "Example: ${definition.example}",
                style: GoogleFonts.lato(
                  textStyle: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSet(String title, List<String>? setList) {
    if (setList?.isNotEmpty ?? false) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            "$title:",
            style: GoogleFonts.lato(
              textStyle: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: setList!.map((item) => InkWell(
              onTap: () => _getMeaningFromApi(item),
              child: Chip(
                label: Text(item),
                backgroundColor: isDarkMode ? Colors.blue[900] : Colors.blue[100],
                labelStyle: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  decoration: TextDecoration.underline,
                ),
              ),
            )).toList(),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _noDataWidget() {
    return SizedBox(
      height: 100,
      child: Center(
        child: Text(
          noDataText,
          style: GoogleFonts.lato(
            textStyle: TextStyle(
              fontSize: 20,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showWordOfTheDay,
      child: const Icon(Icons.auto_awesome),
      backgroundColor: isDarkMode ? Colors.blue[700] : Colors.blue[500],
    );
  }

  Future<void> _getMeaningFromApi(String word) async {
    print(word);
    setState(() {
      inProgress = true;
      _searchController.text = word;
    });
    try {

      responseModel = await API.fetchMeaning(word);
      historyManager.addToSearchHistory(word);
      setState(() {});
      _animationController.forward();
    } catch (e) {
      responseModel = null;
      noDataText = "Meaning cannot be fetched. Please check your internet connection and try again.";
    } finally {
      setState(() {
        inProgress = false;
      });
    }
  }

  Future<void> _speak(String word) async {
    await flutterTts.setLanguage(currentLanguage);
    await flutterTts.setPitch(1);
    await flutterTts.speak(word);
  }

  void _showSearchHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Obx(() =>ListView.builder(
          itemCount: historyManager.searchHistory.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(
                historyManager.searchHistory[index],
                style: GoogleFonts.lato(
                  textStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _searchController.text = historyManager.searchHistory[index];
                _getMeaningFromApi(historyManager.searchHistory[index]);
              },
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  historyManager.removeFromSearchHistory(index);
                  Navigator.pop(context);
                },
              ),
            );
          },
        ));
      },
    );
  }

  void _showFavorites() {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Obx(()=> ListView.builder(
          itemCount: historyManager.favorites.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(
                historyManager.favorites[index],
                style: GoogleFonts.lato(
                  textStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _searchController.text = historyManager.favorites[index];
                _getMeaningFromApi(historyManager.favorites[index]);
              },
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  historyManager.removeFromFavorites(index);

                  Navigator.pop(context);
                },
              ),
            );
          },
        ));
      },
    );
  }





  Future<void> _showWordOfTheDay() async {
    final randomWord = await API.fetchRandomWord();
    _getMeaningFromApi(randomWord);
    notificationManager.scheduleNotification(randomWord);
  }



  void _shareWord(String word) {
    Share.share('Check out this word: $word\n\nDefinition: ${responseModel?.meanings?[0].definitions?[0].definition ?? ""}');
  }




  Future<void> _fetchWordOfTheDay() async {
    try {
      final word = await API.fetchRandomWord();
      final meaning = await API.fetchMeaning(word);
      setState(() {
        wordOfTheDay = word;
        wordOfTheDayDefinition = meaning.meanings![0].definitions![0].definition!;
      });
    } catch (e) {
      for (int i=0; i<3;i++){
        _fetchWordOfTheDay();
      }
      print('Error fetching word of the day: $e');
    }
  }

  void _startQuiz() {
    Get.put(QuizController());
    QuizController quizController = Get.find();
    quizController.startQuiz(
      QuizType.random,
      favorites: historyManager.favorites,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdvancedQuizPage()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

