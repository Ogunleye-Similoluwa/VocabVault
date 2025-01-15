import 'package:get/get.dart';

import 'api.dart';

enum QuizType { favorites, random }

class QuizController extends GetxController {
  final RxInt currentQuestionIndex = 0.obs;
  final RxInt score = 0.obs;
  final RxInt totalPoints = 0.obs;
  final RxList<Map<String, dynamic>> quizQuestions = <Map<String, dynamic>>[].obs;
  final RxList<String> userAnswers = <String>[].obs;
  final RxString currentAnswer = ''.obs;
  final RxBool isLoading = true.obs;
  final RxBool isQuizCompleted = false.obs;
  final RxInt streakCount = 0.obs;
  final RxDouble accuracy = 0.0.obs;

  void resetQuiz() {
    currentQuestionIndex.value = 0;
    score.value = 0;
    totalPoints.value = 0;
    userAnswers.clear();
    currentAnswer.value = '';
    isQuizCompleted.value = false;
    streakCount.value = 0;
    accuracy.value = 0.0;
  }

  void answerQuestion(String selectedAnswer, int timeBonus) {
    if (isQuizCompleted.value) return;

    currentAnswer.value = selectedAnswer;
    userAnswers.add(selectedAnswer);

    final currentQuestion = quizQuestions[currentQuestionIndex.value];
    bool isCorrect = selectedAnswer == currentQuestion['correctAnswer'];

    if (isCorrect) {
      score.value++;
      streakCount.value++;
      // Base points (10) + time bonus + streak bonus
      int streakBonus = (streakCount.value > 1) ? streakCount.value * 2 : 0;
      totalPoints.value += 10 + timeBonus + streakBonus;
    } else {
      streakCount.value = 0;
    }

    // Update accuracy
    accuracy.value = (score.value / (currentQuestionIndex.value + 1)) * 100;

    if (currentQuestionIndex.value < quizQuestions.length - 1) {
      currentQuestionIndex.value++;
    } else {
      isQuizCompleted.value = true;
    }
  }

  Future<void> startQuiz(QuizType quizType, {List<String>? favorites}) async {
    isLoading.value = true;
    currentQuestionIndex.value = 0;
    score.value = 0;
    quizQuestions.clear();

    try {
      List<String> mainWords;
      if (quizType == QuizType.favorites && favorites != null && favorites.isNotEmpty) {
        mainWords = _getRandomWords(favorites, 5);
      } else {
        mainWords = await _fetchRandomWords(5);
      }

      List<String> additionalWords = await _fetchRandomWords(10);

      for (var word in mainWords) {
        List<String> wrongOptionWords = additionalWords
            .where((w) => w != word)
            .toList()
          ..shuffle();
        wrongOptionWords = wrongOptionWords.take(3).toList();

        final questionData = await _generateQuestionWithOptions(word, wrongOptionWords);
        quizQuestions.add(questionData);
      }
    } catch (e) {
      print('Error generating quiz: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<String> _getRandomWords(List<String> words, int count) {
    if (words.length <= count) return List<String>.from(words);
    final shuffled = List<String>.from(words)..shuffle();
    return shuffled.take(count).toList();
  }

  Future<List<String>> _fetchRandomWords(int count) async {
    List<String> words = [];
    for (int i = 0; i < count; i++) {
      try {
        final word = await API.fetchRandomWord(count: 50);
        words.add(word);
      } catch (e) {
        print('Error fetching random word: $e');
      }
    }
    return words;
  }

  Future<Map<String, dynamic>> _generateQuestionWithOptions(
      String correctWord, List<String> wrongWords) async {
    Map<String, String> allDefinitions = {};

    try {
      final correctMeaning = await API.fetchMeaning(correctWord);
      allDefinitions[correctWord] = correctMeaning.meanings![0].definitions![0].definition!;

      for (String word in wrongWords) {
        try {
          final meaning = await API.fetchMeaning(word);
          allDefinitions[word] = meaning.meanings![0].definitions![0].definition!;
        } catch (e) {
          print('Error fetching definition for $word: $e');
        }
      }
    } catch (e) {
      print('Error fetching definition for $correctWord: $e');
      return {};
    }


    List<String> options = allDefinitions.values.toList()..shuffle();

    return {
      'word': correctWord,
      'question': 'What is the definition of "$correctWord"?',
      'options': options,
      'correctAnswer': allDefinitions[correctWord],
    };
  }
}