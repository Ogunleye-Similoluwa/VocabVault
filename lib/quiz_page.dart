import 'package:advanced_dictionary/quiz_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class AdvancedQuizPage extends StatelessWidget {
  final QuizController quizController = Get.put(QuizController());
  final List<String>? favorites;
  final RxBool isTimerActive = true.obs;
  final RxInt timeRemaining = 30.obs;
  final RxList<String> userAnswers = <String>[].obs;

  Timer? timer;

  AdvancedQuizPage({Key? key, this.favorites}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await _showExitConfirmationDialog(context) ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,

        appBar: _buildAppBar(context),
        body: Obx(() {
          if (quizController.isLoading.value) {
            return _buildLoadingView();
          }
          if (quizController.quizQuestions.isEmpty) {
            return _buildErrorView();
          }
          return _buildQuizContent(context);
        }),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      title: Text('Word Master Quiz'),
      actions: [
        Obx(() => _buildScoreWidget(context)),
        IconButton(
          icon: Icon(Icons.help_outline),
          onPressed: () => _showHelpDialog(context),
        ),
      ],
    );
  }

  Widget _buildScoreWidget(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme
            .of(context)
            .primaryColorLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: Colors.amber, size: 20),
          SizedBox(width: 4),
          Text(
            '${quizController.score}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme
                  .of(context)
                  .primaryColorDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              strokeWidth: 8,
              backgroundColor: Colors.grey[200],
            ),
          ),
          SizedBox(height: 32),
          Text(
            'Preparing Your Challenge',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildLoadingTips(),
        ],
      ),
    );
  }

  Widget _buildLoadingTips() {
    final tips = [
      'Did you know? The average English speaker knows 20,000-35,000 words!',
      'Learning new words improves both speaking and writing skills.',
      'Word games can increase your vocabulary by 30% faster than traditional methods.',
    ].obs;

    return Obx(() =>
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                tips[0],
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                tips.shuffle();
              },
              child: Text('Next Tip'),
            ),
          ],
        ));
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/error_illustration.png',
            width: 200,
            height: 200,
          ),
          SizedBox(height: 24),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'We couldn\'t generate the quiz questions. Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
          SizedBox(height: 32),
          _buildRetryButton(),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return ElevatedButton.icon(
      icon: Icon(Icons.refresh),
      label: Text('Try Again'),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      onPressed: () {
        HapticFeedback.mediumImpact();
        quizController.startQuiz(
          favorites != null && favorites!.isNotEmpty
              ? QuizType.favorites
              : QuizType.random,
          favorites: favorites,
        );
      },
    );
  }

  Widget _buildQuizContent(BuildContext context) {
    _startTimer();
    final currentQuestion = quizController.quizQuestions[quizController
        .currentQuestionIndex.value];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              [Colors.blue[50]!, Colors.blue[100]!],
        ),
      ),
      child: Column(
        children: [
          _buildProgressAndTimer(context),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildQuestionCard(currentQuestion),
                    SizedBox(height: 24),
                    _buildOptions(currentQuestion, context),
                  ],
                ),
              ),
            ),
          ),
          _buildHintButton(currentQuestion),
        ],
      ),
    );
  }

  Widget _buildProgressAndTimer(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 7,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (quizController.currentQuestionIndex.value + 1) /
                    quizController.quizQuestions.length,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme
                      .of(context)
                      .primaryColor,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Obx(() => _buildTimerWidget()),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerWidget() {
    Color getTimerColor() {
      if (timeRemaining.value > 20) return Colors.green;
      if (timeRemaining.value > 10) return Colors.orange;
      return Colors.red;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: getTimerColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: getTimerColor()),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer, color: getTimerColor(), size: 18),
          SizedBox(width: 4),
          Text(
            '${timeRemaining.value}s',
            style: TextStyle(
              color: getTimerColor(),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.blue[700]!, Colors.blue[900]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${quizController.currentQuestionIndex.value + 1}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '${quizController.currentQuestionIndex.value +
                        1}/${quizController.quizQuestions.length}',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              question['word'],
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black.withOpacity(0.3),
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              question['question'],
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions(Map<String, dynamic> question, BuildContext context) {
    List<String> options = List<String>.from(question['options']);
    options.shuffle(); // Randomize option order

    return Column(
      children: options.map((option) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildOptionButton(option, question['correctAnswer'], context),
        );
      }).toList(),
    );
  }

  Widget _buildOptionButton(String option, String correctAnswer,
      BuildContext context) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 4,
        ),
        onPressed: () {
          _handleAnswer(option, correctAnswer, context);
        },
        child: Text(
          option,
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildHintButton(Map<String, dynamic> currentQuestion) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextButton.icon(
        icon: Icon(Icons.lightbulb_outline),
        label: Text('Get a Hint'),
        onPressed: () => _showHint(currentQuestion),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _handleAnswer(String selectedAnswer, String correctAnswer,
      BuildContext context) {
    timer?.cancel();
    HapticFeedback.selectionClick();

    bool isCorrect = selectedAnswer == correctAnswer;

    // Show immediate feedback
    Get.snackbar(
      isCorrect ? 'Correct!' : 'Incorrect',
      isCorrect ? 'Great job!' : 'The correct answer was: $correctAnswer',
      backgroundColor: isCorrect ? Colors.green : Colors.red,
      colorText: Colors.white,
      duration: Duration(seconds: 2),
    );

    quizController.answerQuestion(selectedAnswer);

    if (quizController.currentQuestionIndex.value >=
        quizController.quizQuestions.length) {
      _showQuizResults(context);
    } else {
      timeRemaining.value = 30;
    }
  }

  void _showHint(Map<String, dynamic> question) {
    String correctAnswer = question['correctAnswer'];
    List<String> words = correctAnswer.split(' ');
    String hint = words.map((word) => '${word[0]}${word.substring(1).replaceAll(
        RegExp(r'[a-zA-Z]'), '_')}').join(' ');

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.amber),
            SizedBox(width: 8),
            Text('Hint'),
          ],
        ),
        content: Text(hint),
        actions: [
          TextButton(
            child: Text('Got it'),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuizResults(BuildContext context) async {
    final score = quizController.score.value;
    final total = quizController.quizQuestions.length;
    final percentage = (score / total * 100).round();

    await Future.delayed(
        Duration(milliseconds: 500)); // Short delay for dramatic effect

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildResultsHeader(percentage),
              SizedBox(height: 24),
              _buildResultsStats(score, total, percentage),
              SizedBox(height: 24),
              _buildResultsActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsHeader(int percentage) {
    return Column(
      children: [
        Icon(
          percentage >= 70 ? Icons.emoji_events : Icons.psychology,
          size: 64,
          color: percentage >= 70 ? Colors.amber : Colors.blue,
        ),
        SizedBox(height: 16),
        Text(
          _getResultTitle(percentage),
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildResultsStats(int score, int total, int percentage) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatCard(
              icon: Icons.check_circle,
              color: Colors.green,
              value: score,
              label: 'Correct',
            ),
            _buildStatCard(
              icon: Icons.cancel,
              color: Colors.red,
              value: total - score,
              label: 'Incorrect',
            ),
            _buildStatCard(
              icon: Icons.percent,
              color: Colors.blue,
              value: percentage,
              label: 'Score',
            ),
          ],
        ),
        SizedBox(height: 24),
        _buildProgressCircle(percentage),
        SizedBox(height: 16),
        _buildPerformanceText(percentage),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required int value,
    required String label,
  }) {
    return Container(
      width: 90,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 4),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCircle(int percentage) {
    return Container(
      width: 150,
      height: 150,
      child: Stack(
        children: [
          ShaderMask(
            shaderCallback: (rect) {
              return SweepGradient(
                startAngle: 0.0,
                endAngle: 3.14 * 2,
                stops: [percentage / 100, percentage / 100],
                center: Alignment.center,
                colors: [Colors.blue, Colors.grey.withOpacity(0.2)],
              ).createShader(rect);
            },
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
          Center(
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Complete',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceText(int percentage) {
    String message = _getPerformanceMessage(percentage);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  String _getPerformanceMessage(int percentage) {
    if (percentage >= 90) {
      return 'Outstanding! Your vocabulary skills are exceptional. Keep up the great work!';
    } else if (percentage >= 70) {
      return 'Great job! You have a strong grasp of vocabulary. A little more practice and you\'ll be unstoppable!';
    } else if (percentage >= 50) {
      return 'Good effort! You\'re making progress. Regular practice will help you improve even more.';
    } else {
      return 'Keep practicing! Every quiz is an opportunity to learn and grow your vocabulary.';
    }
  }

  Widget _buildResultsActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.refresh,
          label: 'Try Again',
          onPressed: () {
            Get.back();
            quizController.startQuiz(
              favorites != null && favorites!.isNotEmpty
                  ? QuizType.favorites
                  : QuizType.random,
              favorites: favorites,
            );
          },
        ),
        _buildActionButton(
          icon: Icons.list,
          label: 'Review',
          onPressed: () {
            Get.back();
            _showReviewScreen(context);
          },
        ),
        _buildActionButton(
          icon: Icons.share,
          label: 'Share',
          onPressed: () {
            // Implement share functionality
            Get.snackbar(
              'Share',
              'Sharing functionality coming soon!',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: Colors.blue,
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  String _getResultTitle(int percentage) {
    if (percentage >= 90) return 'Word Master!';
    if (percentage >= 70) return 'Vocabulary Virtuoso!';
    if (percentage >= 50) return 'Word Explorer';
    return 'Keep Learning!';
  }

  void _startTimer() {
    timer?.cancel(); // Cancel any existing timer
    timeRemaining.value = 30; // Reset timer to 30 seconds

    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timeRemaining.value > 0) {
        timeRemaining.value--;
      } else {
        timer.cancel();
        // Auto-submit current question when time runs out
        final currentQuestion = quizController.quizQuestions[quizController.currentQuestionIndex.value];
        _handleTimeOut(currentQuestion);
      }
    });
  }

  void _handleTimeOut(Map<String, dynamic> currentQuestion) {
    Get.snackbar(
      'Time\'s Up!',
      'Moving to the next question...',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: Duration(seconds: 2),
    );

    // Move to next question without awarding points
    quizController.answerQuestion('');

    if (quizController.currentQuestionIndex.value >= quizController.quizQuestions.length) {
      _showQuizResults(Get.context!);
    } else {
      timeRemaining.value = 30; // Reset timer for next question
    }
  }

  Future<bool?> _showExitConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Exit Quiz?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: Colors.orange,
              ),
              SizedBox(height: 16),
              Text('Are you sure you want to exit the quiz? Your progress will be lost.'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Exit Quiz'),
              onPressed: () {
                timer?.cancel(); // Cancel timer if active
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('How to Play'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHelpItem(
                  icon: Icons.timer,
                  title: 'Time Limit',
                  description: 'You have 30 seconds to answer each question.',
                ),
                _buildHelpItem(
                  icon: Icons.lightbulb_outline,
                  title: 'Hints',
                  description: 'Use the hint button for a clue, but use wisely!',
                ),
                _buildHelpItem(
                  icon: Icons.star,
                  title: 'Scoring',
                  description: 'Earn points for correct answers. The faster you answer, the more points you get!',
                ),
                _buildHelpItem(
                  icon: Icons.analytics,
                  title: 'Progress',
                  description: 'Track your progress with the bar at the top of the screen.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Got it!'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewScreen(BuildContext context) {
    Get.to(
          () => QuizReviewScreen(
        quizQuestions: quizController.quizQuestions,
        userAnswers: quizController.userAnswers,
      ),
      transition: Transition.rightToLeft,
    );
  }
}

class QuizReviewScreen extends StatelessWidget {
  final List<Map<String, dynamic>> quizQuestions;
  final List<String> userAnswers;

  const QuizReviewScreen({
    Key? key,
    required this.quizQuestions,
    required this.userAnswers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Review'),
      ),
      body: ListView.builder(
        itemCount: quizQuestions.length,
        itemBuilder: (context, index) {
          final question = quizQuestions[index];
          final userAnswer = userAnswers[index];
          final correctAnswer = question['correctAnswer'];

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ExpansionTile(
              leading: Icon(
                userAnswer == correctAnswer ? Icons.check_circle : Icons.cancel,
                color: userAnswer == correctAnswer ? Colors.green : Colors.red,
              ),
              title: Text(
                'Question ${index + 1}: ${question['word']}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                userAnswer.isEmpty ? 'Time expired' : 'Your answer: $userAnswer',
                style: TextStyle(
                  color: userAnswer == correctAnswer ? Colors.green : Colors.red,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(question['question']),
                      SizedBox(height: 8),
                      Text(
                        'Correct Answer:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(correctAnswer),
                      SizedBox(height: 8),
                      Text(
                        'All Options:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...question['options'].map<Widget>((option) => ListTile(
                        leading: Icon(
                          option == correctAnswer
                              ? Icons.check_circle
                              : (option == userAnswer ? Icons.cancel : Icons.circle_outlined),
                          color: option == correctAnswer
                              ? Colors.green
                              : (option == userAnswer ? Colors.red : Colors.grey),
                        ),
                        title: Text(option),
                      )).toList(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

