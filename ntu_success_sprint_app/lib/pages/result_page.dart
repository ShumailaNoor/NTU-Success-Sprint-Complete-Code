import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:ntu_success_sprint_app/constant.dart';
import 'package:ntu_success_sprint_app/nav_bar_and_pages/nav_bar_screen.dart';
import 'package:ntu_success_sprint_app/provider/nav_provider.dart';
import 'package:provider/provider.dart';

class QuizResultPage extends StatefulWidget {
  final List<Map<String, dynamic>> mcqs;
  final Map<int, String> selectedAnswers;
  final String selectedTopic;
  final String selectedProgram;
  final String selectedSemester;
  final String selectedCourse;

  const QuizResultPage(
      {super.key,
      required this.mcqs,
      required this.selectedAnswers,
      required this.selectedTopic,
      required this.selectedProgram,
      required this.selectedSemester,
      required this.selectedCourse});

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> {
  bool isSaving = false;

  int calculateScore() {
    int score = 0;
    for (int i = 0; i < widget.mcqs.length; i++) {
      if (widget.selectedAnswers[i] == widget.mcqs[i]['answer']) {
        score++;
      }
    }
    return score;
  }

  void showSuccessDialog(BuildContext context) async {
    setState(() {
      isSaving = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final score = calculateScore();
    final total = widget.mcqs.length;

    // Get reference to the user's QuizResults list
    DatabaseReference quizResultsRef = FirebaseDatabase.instance
        .ref()
        .child('Users')
        .child(user.uid)
        .child('QuizResults')
        .push();

    await quizResultsRef.set({
      'topic': widget.selectedTopic,
      'semester': widget.selectedSemester,
      'course': widget.selectedCourse,
      'score': score,
      'total': total,
      'timestamp': DateTime.now().toIso8601String(),
    });

    setState(() {
      isSaving = false;
    });

    showDialog(
      context: context,
      builder: (BuildContext buildContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          icon: Icon(
            Icons.check_circle,
            color: primaryColor,
            size: 40,
          ),
          title: Text("Success",
              style: TextStyle(
                  color: secondaryColor, fontWeight: FontWeight.bold)),
          content: Text("Your results have been saved successfully!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700])),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(buildContext).pop();

                final navProvider =
                    Provider.of<NavigationProvider>(context, listen: false);

                navProvider.setIndex(0);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NavigationScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text("See Performance"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 12, bottom: 6),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            color: primaryColor,
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(primaryColor),
              shape: WidgetStateProperty.all(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              )),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        title: Text(
          'Quiz Results',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        centerTitle: true,
        leadingWidth: 56,
      ),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.027),
        itemCount:
            widget.mcqs.length + 2, // +2 for score circle and save button
        itemBuilder: (context, index) {
          if (index == 0) {
            // Score Circle
            return Padding(
              padding: EdgeInsets.only(
                  top: size.height * 0.03, bottom: size.height * 0.02),
              child: Center(
                child: Container(
                  width: size.width * 0.28,
                  height: size.width * 0.28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: secondaryColor.withOpacity(0.15),
                    border: Border.all(color: secondaryColor, width: 3),
                  ),
                  alignment: Alignment.center,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                        begin: 0, end: calculateScore().toDouble()),
                    duration: const Duration(seconds: 1),
                    builder: (context, value, child) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${value.toInt()} / ${widget.mcqs.length}",
                            style: TextStyle(
                              fontSize: size.width * 0.05,
                              fontWeight: FontWeight.bold,
                              color: secondaryColor,
                            ),
                          ),
                          Text(
                            "Score",
                            style: TextStyle(
                              fontSize: size.width * 0.033,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          } else if (index == widget.mcqs.length + 1) {
            // Save Button
            return Padding(
              padding: EdgeInsets.symmetric(vertical: size.height * 0.025),
              child: ElevatedButton(
                onPressed: () => showSuccessDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, size.height * 0.06),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(size.width * 0.025),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          "Save Results",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size.width * 0.038,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            );
          } else {
            // Quiz Question Card
            final i = index - 1;
            final question = widget.mcqs[i];
            final selected = widget.selectedAnswers[i];
            final correct = question['answer'];
            final isCorrect = selected == correct;

            return Card(
              color: isCorrect ? Colors.lightBlue[50] : null,
              margin: EdgeInsets.symmetric(vertical: size.height * 0.012),
              child: Padding(
                padding: EdgeInsets.all(size.width * 0.033),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${i + 1}. ${question['question']}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: size.height * 0.012),
                    ...question['options'].map<Widget>((option) {
                      final label = option['label'];
                      final text = option['text'];
                      final isSelected = selected == label;

                      return RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        value: label,
                        groupValue: selected,
                        title: Text(
                          text,
                          style: TextStyle(
                            color: label == correct && isSelected
                                ? secondaryColor
                                : (isSelected ? Colors.red : null),
                            fontWeight: label == correct && isSelected
                                ? FontWeight.bold
                                : null,
                          ),
                        ),
                        onChanged: null,
                        activeColor: label == correct && isSelected
                            ? secondaryColor
                            : (isSelected ? Colors.red : null),
                      );
                    }).toList(),
                    if (!isCorrect) ...[
                      SizedBox(height: size.height * 0.01),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: secondaryColor.withOpacity(0.3),
                          borderRadius:
                              BorderRadius.circular(size.width * 0.025),
                        ),
                        child: Text(
                          "Correct Answer: ${correct}) ${question['options'].firstWhere((opt) => opt['label'] == correct)['text']}",
                          style: TextStyle(
                            color: secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ]
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
