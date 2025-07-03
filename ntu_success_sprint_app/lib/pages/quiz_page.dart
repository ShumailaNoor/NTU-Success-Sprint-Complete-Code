import 'package:flutter/material.dart';
import 'package:ntu_success_sprint_app/constant.dart';
import 'package:ntu_success_sprint_app/pages/result_page.dart';

class QuizPage extends StatefulWidget {
  final List<Map<String, dynamic>> mcqs;
  final String selectedTopic;
  final String selectedProgram;
  final String selectedSemester;
  final String selectedCourse;

  const QuizPage(
      {super.key,
      required this.mcqs,
      required this.selectedTopic,
      required this.selectedProgram,
      required this.selectedSemester,
      required this.selectedCourse});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  // Map to store selected answers per question
  final Map<int, String> selectedAnswers = {};

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
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            color: primaryColor,
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(primaryColor),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        title: Text(
          'Quiz',
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

      // Main body
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: widget.mcqs.length,
              itemBuilder: (context, index) {
                final question = widget.mcqs[index];
                final selected = selectedAnswers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${index + 1}. ${question['question']}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...question['options'].map<Widget>((option) {
                          final label = option['label'];
                          final text = option['text'];
                          return RadioListTile<String>(
                            value: label,
                            groupValue: selected,
                            title: Text(text),
                            onChanged: (value) {
                              setState(() {
                                selectedAnswers[index] = value!;
                              });
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: ElevatedButton(
              onPressed: () {
                if (selectedAnswers.length < widget.mcqs.length) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Please answer all questions before submitting.',
                      ),
                      backgroundColor: primaryColor,
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizResultPage(
                        mcqs: widget.mcqs,
                        selectedAnswers: selectedAnswers,
                        selectedTopic: widget.selectedTopic,
                        selectedProgram: widget.selectedProgram,
                        selectedSemester: widget.selectedSemester,
                        selectedCourse: widget.selectedCourse,
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, size.height * 0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(size.width * 0.025),
                ),
              ),
              child: Text(
                "Submit",
                style: TextStyle(
                  fontSize: size.width * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
