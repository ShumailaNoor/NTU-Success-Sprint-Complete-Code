import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:ntu_success_sprint_app/constant.dart';
import 'package:ntu_success_sprint_app/provider/user_provider.dart';
import 'package:provider/provider.dart';

class PerformancePage extends StatefulWidget {
  const PerformancePage({super.key});

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  final user = FirebaseAuth.instance.currentUser;
  final dbRef = FirebaseDatabase.instance.ref();
  Map<String, dynamic> quizScores = {};
  double averageScore = 0.0;
  Map<String, Map<String, List<Map<String, dynamic>>>> groupedData = {};

  @override
  void initState() {
    super.initState();
    fetchScores();
  }

  Future<void> fetchScores() async {
    final ref = dbRef.child('Users').child(user!.uid).child('QuizResults');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      int totalScore = 0;
      int quizCount = 0;

      Map<String, Map<String, List<Map<String, dynamic>>>> tempGrouped = {};

      data.forEach((key, value) {
        final entry = Map<String, dynamic>.from(value);
        final semester = entry['semester'] ?? 'Unknown Semester';
        final course = entry['course'] ?? 'Unknown Course';
        final topic = entry['topic'] ?? 'Unnamed Topic';
        final score = (entry['score'] as num).toInt();
        final total = (entry['total'] as num).toInt();

        tempGrouped[semester] ??= {};
        tempGrouped[semester]![course] ??= [];

        tempGrouped[semester]![course]!.add({
          'topic': topic,
          'score': score,
          'total': total,
        });

        totalScore += score;
        quizCount++;
      });

      setState(() {
        groupedData = tempGrouped;
        averageScore = quizCount > 0 ? totalScore / quizCount : 0.0;
      });
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return SafeArea(
      child: Scaffold(
          backgroundColor: Colors.white,
          body: userProvider.isLoggedIn
              ? Padding(
                  padding: EdgeInsets.all(size.width * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (averageScore < 3 && quizScores.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Colors.orange),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "You're doing great! Just a bit more effort and you'll ace it!",
                                  style: TextStyle(
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: groupedData.isEmpty
                            ? const Center(
                                child: Text("No quiz data available."))
                            : ListView(
                                children:
                                    groupedData.entries.map((semesterEntry) {
                                  final semester = semesterEntry.key;
                                  final courses = semesterEntry.value;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        semester,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                      ...courses.entries.map((courseEntry) {
                                        final course = courseEntry.key;
                                        final topics = courseEntry.value;

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              left: 16.0, top: 8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                course,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: secondaryColor,
                                                ),
                                              ),
                                              ...topics.map((topicData) {
                                                final score =
                                                    topicData['score'];
                                                final total =
                                                    topicData['total'];
                                                final topic =
                                                    topicData['topic'];

                                                return Card(
                                                  elevation: 3,
                                                  margin: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 6,
                                                      horizontal: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: ListTile(
                                                    title: Text(topic),
                                                    trailing:
                                                        TweenAnimationBuilder<
                                                            double>(
                                                      tween: Tween<double>(
                                                          begin: 0,
                                                          end:
                                                              score.toDouble()),
                                                      duration: const Duration(
                                                          milliseconds: 800),
                                                      builder: (context, value,
                                                          child) {
                                                        return CircleAvatar(
                                                          backgroundColor:
                                                              value >= 3
                                                                  ? secondaryColor
                                                                  : primaryColor,
                                                          child: Text(
                                                            "${value.toInt()}/$total",
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      const SizedBox(height: 16),
                                    ],
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: size.height * 0.05),
                      Icon(
                        Icons.person_off,
                        size: size.width * 0.2,
                        color: secondaryColor,
                      ),
                      SizedBox(height: size.height * 0.03),
                      Text(
                        "Please log in to view your performance.",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )),
    );
  }
}
