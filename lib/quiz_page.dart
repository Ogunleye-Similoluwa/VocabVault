import 'dart:math';

import 'package:advanced_dictionary/quiz_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class AdvancedQuizPage extends StatefulWidget {
  final List<String>? favorites;
  
  const AdvancedQuizPage({Key? key, this.favorites}) : super(key: key);

  @override
  State<AdvancedQuizPage> createState() => _AdvancedQuizPageState();
}

class _AdvancedQuizPageState extends State<AdvancedQuizPage> with SingleTickerProviderStateMixin {
  final QuizController quizController = Get.find();
  final RxInt timeRemaining = 30.obs;
  Timer? timer;
  late ConfettiController _confettiController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

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

    return Stack(
      children: [
        Column(
          children: [
            _buildQuizHeader(context),
            const SizedBox(height: 8),
            _buildProgressAndTimer(context),
            const SizedBox(height: 8),
            _buildStreakAndAccuracy(),
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
                      if (!quizController.currentAnswer.value.isNotEmpty)
                        _buildHintButton(currentQuestion),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (quizController.streakCount.value >= 3)
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            maxBlastForce: 5,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 10,
          ),
      ],
    );
  }

  Widget _buildQuizHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                const SizedBox(width: 4),
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
    ).animate()
     .fadeIn(duration: 400.ms)
     .slideX(begin: 0.2, end: 0);
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
    final bool isAnswered = quizController.currentAnswer.isNotEmpty;
    final bool isSelected = quizController.currentAnswer.value == option;
    final bool isCorrect = option == correctAnswer;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          backgroundColor: isAnswered
              ? (isSelected
                  ? (isCorrect ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2))
                  : Colors.white)
              : Colors.white,
          foregroundColor: Colors.black87,
          elevation: isAnswered ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isAnswered
                  ? (isSelected
                      ? (isCorrect ? Colors.green : Colors.red)
                      : Colors.grey.withOpacity(0.2))
                  : Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        onPressed: isAnswered ? null : () => _handleAnswer(option, correctAnswer, context),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
            if (isAnswered)
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Colors.red,
                size: 20,
              ),
          ],
        ),
      ),
    ).animate()
     .fadeIn(delay: (100 * index).ms)
     .slideX(begin: 0.2, end: 0);
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
    if (quizController.isQuizCompleted.value) return;

    timer?.cancel();
    HapticFeedback.mediumImpact();

    bool isCorrect = selectedAnswer == correctAnswer;
    int timeBonus = _calculateTimeBonus(timeRemaining.value);

    quizController.answerQuestion(selectedAnswer, timeBonus);

    if (isCorrect) {
      _animationController.forward(from: 0.0);
      if (quizController.streakCount.value >= 3) {
        _confettiController.play();
      }
    }

    _showAnswerFeedback(context, isCorrect, correctAnswer, timeBonus);

    if (quizController.isQuizCompleted.value) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _showQuizResults(context);
        }
      });
    } else {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          timeRemaining.value = 30;
          quizController.currentAnswer.value = '';
        }
      });
    }
  }

  int _calculateTimeBonus(int timeLeft) {
    return (timeLeft / 2).round(); // 0-15 bonus points based on speed
  }

  void _showAnswerFeedback(BuildContext context, bool isCorrect, String correctAnswer, int points) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCorrect ? 'Correct! +$points points' : 'The correct answer was: $correctAnswer',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: isCorrect ? Colors.green : Colors.red,
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
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
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Time\'s Up! Moving to next question...',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 1),
      ),
    );

    quizController.answerQuestion('', 0);

    if (quizController.isQuizCompleted.value) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _showQuizResults(context);
        }
      });
    } else {
      timeRemaining.value = 30;
    }
  }

  Future<void> _showQuizResults(BuildContext context) async {
    final score = quizController.score.value;
    final total = quizController.quizQuestions.length;
    final percentage = (score / total * 100).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirection: -pi / 2,
                    emissionFrequency: 0.3,
                    numberOfParticles: 20,
                  ),
                  _buildResultsHeader(percentage),
                  const SizedBox(height: 24),
                  _buildResultsStats(score, total, percentage),
                  const SizedBox(height: 24),
                  _buildResultsActions(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (percentage >= 70) {
      _confettiController.play();
    }
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
          textAlign: TextAlign.center,
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
              icon: Icons.stars,
              color: Colors.blue,
              value: quizController.totalPoints.value,
              label: 'Points',
            ),
          ],
        ),
        SizedBox(height: 20),
        _buildProgressCircle(percentage),
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
      width: 80,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
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
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCircle(int percentage) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(
            value: percentage / 100,
            strokeWidth: 12,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage >= 70 ? Colors.green : Colors.orange,
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Accuracy'),
          ],
        ),
      ],
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
            Navigator.of(context).pop();
            quizController.startQuiz(
              widget.favorites != null && widget.favorites!.isNotEmpty
                  ? QuizType.favorites
                  : QuizType.random,
              favorites: widget.favorites,
            );
          },
        ),
        _buildActionButton(
          icon: Icons.list,
          label: 'Review',
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizReviewScreen(
                  quizQuestions: quizController.quizQuestions,
                  userAnswers: quizController.userAnswers,
                ),
              ),
            );
          },
        ),
        _buildActionButton(
          icon: Icons.share,
          label: 'Share',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sharing functionality coming soon!'),
                behavior: SnackBarBehavior.floating,
              ),
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

  Widget _buildStreakIndicator() {
    return Obx(() {
      if (quizController.streakCount.value < 2) return const SizedBox.shrink();
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
            const SizedBox(width: 4),
            Text(
              '${quizController.streakCount.value}x Streak!',
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAccuracyIndicator() {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Accuracy: ${quizController.accuracy.value.toStringAsFixed(1)}%',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    ));
  }

  Widget _buildStreakAndAccuracy() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStreakIndicator(),
          _buildAccuracyIndicator(),
        ],
      ),
    );
  }

  Widget _buildHintButton(Map<String, dynamic> question) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextButton.icon(
        icon: const Icon(Icons.lightbulb_outline),
        label: const Text('Get Hint'),
        onPressed: () => _showHint(question),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  void _showHint(Map<String, dynamic> question) {
    final correctAnswer = question['correctAnswer'] as String;
    final words = correctAnswer.split(' ');
    final hint = words.map((word) {
      if (word.length <= 3) return word;
      return '${word[0]}${word[1]}${word.substring(2).replaceAll(RegExp(r'[a-zA-Z]'), '_')}';
    }).join(' ');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.lightbulb, color: Colors.amber),
            SizedBox(width: 8),
            Text('Hint'),
          ],
        ),
        content: Text(hint),
        actions: [
          TextButton(
            child: const Text('Got it'),
            onPressed: () => Navigator.pop(context),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quiz Review',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareResults(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode 
              ? [Colors.grey[900]!, Colors.grey[800]!]
              : [Colors.blue[50]!, Colors.blue[100]!],
          ),
        ),
        child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: quizQuestions.length,
          itemBuilder: (context, index) => _buildQuestionCard(context, index),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, int index) {
    final question = quizQuestions[index];
    final userAnswer = userAnswers[index];
    final correctAnswer = question['correctAnswer'];
    final isCorrect = userAnswer == correctAnswer;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCorrect 
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: isCorrect ? Colors.green : Colors.red,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Q${index + 1}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question['word'],
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              userAnswer.isEmpty 
                ? 'Time expired'
                : 'Your answer: ${_truncateText(userAnswer, 40)}',
              style: TextStyle(
                color: isCorrect ? Colors.green : Colors.red,
                fontSize: 14,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('Question', question['question']),
                Divider(),
                _buildSection('Correct Answer', correctAnswer),
                if (!isCorrect && userAnswer.isNotEmpty) ...[
                  Divider(),
                  _buildSection('Your Answer', userAnswer, isError: true),
                ],
                Divider(),
                _buildOptionsGrid(question['options'], correctAnswer, userAnswer),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, {bool isError = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            color: isError ? Colors.red : null,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsGrid(List<String> options, String correctAnswer, String userAnswer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Options',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final option = options[index];
            final isCorrect = option == correctAnswer;
            final isSelected = option == userAnswer;
            
            return Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCorrect
                    ? Colors.green.withOpacity(0.1)
                    : isSelected
                        ? Colors.red.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCorrect
                      ? Colors.green
                      : isSelected
                          ? Colors.red
                          : Colors.grey,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCorrect
                        ? Icons.check_circle
                        : isSelected
                            ? Icons.cancel
                            : Icons.radio_button_unchecked,
                    size: 16,
                    color: isCorrect
                        ? Colors.green
                        : isSelected
                            ? Colors.red
                            : Colors.grey,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _truncateText(option, 30),
                      style: TextStyle(
                        fontSize: 12,
                        color: isCorrect
                            ? Colors.green
                            : isSelected
                                ? Colors.red
                                : null,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  void _shareResults(BuildContext context) {
    final correctAnswers = userAnswers.asMap().entries.where(
      (entry) => entry.value == quizQuestions[entry.key]['correctAnswer']
    ).length;
    
    final percentage = (correctAnswers / quizQuestions.length * 100).round();
    
    Share.share(
      'I scored $percentage% on my VocabVault quiz! 📚\n'
      'Correct answers: $correctAnswers/${quizQuestions.length}\n'
      'Download VocabVault to improve your vocabulary!',
    );
  }
}

