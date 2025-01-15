import 'package:advanced_dictionary/quiz_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class AdvancedQuizPage extends StatelessWidget {
  final QuizController quizController = Get.find();
  final RxBool isTimerActive = true.obs;
  final RxInt timeRemaining = 30.obs;
  final List<String>? favorites;
  Timer? timer;

  AdvancedQuizPage({Key? key, this.favorites}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => await _showExitConfirmationDialog(context) ?? false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[700]!, Colors.purple[700]!],
            ),
          ),
          child: SafeArea(
            child: Obx(() {
              if (quizController.isLoading.value) {
                return _buildLoadingView();
              }
              if (quizController.quizQuestions.isEmpty) {
                return _buildErrorView();
              }
              return _buildQuizContent(context);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizContent(BuildContext context) {
    _startTimer();
    final currentQuestion = quizController.quizQuestions[quizController.currentQuestionIndex.value];

    return Column(
      children: [
        _buildQuizHeader(context),
        const SizedBox(height: 16),
        _buildProgressAndTimer(context),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildQuestionCard(currentQuestion),
                  const SizedBox(height: 24),
                  _buildOptions(currentQuestion, context),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => _showExitConfirmationDialog(context),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Obx(() => Text(
                  '${quizController.score}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue[100]!.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
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
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${quizController.currentQuestionIndex.value + 1}/${quizController.quizQuestions.length}',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    question['word'],
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    question['question'],
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions(Map<String, dynamic> question, BuildContext context) {
    List<String> options = List<String>.from(question['options']);
    return Column(
      children: options.asMap().entries.map((entry) {
        int idx = entry.key;
        String option = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildOptionButton(option, question['correctAnswer'], context, idx),
        );
      }).toList(),
    );
  }

  Widget _buildOptionButton(String option, String correctAnswer, BuildContext context, int index) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(20),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () => _handleAnswer(option, correctAnswer, context),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                option,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
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

  void _handleAnswer(String selectedAnswer, String correctAnswer, BuildContext context) {
    timer?.cancel();
    HapticFeedback.mediumImpact();

    bool isCorrect = selectedAnswer == correctAnswer;
    int pointsEarned = _calculatePoints(timeRemaining.value);

    if (isCorrect) {
      quizController.score.value += pointsEarned;
    }

    _showAnswerFeedback(context, isCorrect, correctAnswer, pointsEarned);
    
    Future.delayed(const Duration(seconds: 1), () {
      quizController.answerQuestion(selectedAnswer);
      if (quizController.currentQuestionIndex.value >= quizController.quizQuestions.length) {
        _showQuizResults(context);
      } else {
        timeRemaining.value = 30;
      }
    });
  }

  int _calculatePoints(int timeLeft) {
    // Base points for correct answer
    int basePoints = 10;
    // Bonus points based on remaining time (max 10 bonus points)
    int timeBonus = (timeLeft / 3).round();
    return basePoints + timeBonus;
  }

  void _showAnswerFeedback(BuildContext context, bool isCorrect, String correctAnswer, int points) {
    Get.snackbar(
      isCorrect ? 'Correct! +$points points' : 'Incorrect',
      isCorrect ? 'Great job!' : 'The correct answer was: $correctAnswer',
      backgroundColor: isCorrect ? Colors.green : Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 1),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(8),
      borderRadius: 10,
    );
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

  void _showReviewScreen(BuildContext context) {
    Get.to(
          () => QuizReviewScreen(
        quizQuestions: quizController.quizQuestions,
        userAnswers: quizController.userAnswers,
      ),
      transition: Transition.rightToLeft,
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
          SizedBox(height: 24),
          Text(
            'Preparing Your Quiz...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Failed to load quiz',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextButton(
            onPressed: () => quizController.startQuiz(QuizType.random),
            child: Text('Try Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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

