import 'package:flutter/material.dart';
import 'package:ntu_success_sprint_app/constant.dart';
import 'package:ntu_success_sprint_app/pages/course_topic_page.dart';

class SemesterPage extends StatelessWidget {
  final String selectedProgram;

  const SemesterPage({super.key, required this.selectedProgram});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(size.width * 0.042),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    color: primaryColor,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(primaryColor),
                      shape: WidgetStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(size.width * 0.029),
                      )),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: Text(
                      selectedProgram,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: size.width * 0.066,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: size.height * 0.012),

              /// Semester Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                  children: List.generate(8, (index) {
                    final semesterNumber = index + 1;
                    final semesterLabel = 'Semester $semesterNumber';

                    return GestureDetector(
                      onTap: () {
                        // Navigate to course and topic selection page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseAndTopicPage(
                              selectedProgram: selectedProgram,
                              selectedSemester: semesterLabel,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: secondaryColor.withOpacity(0.9),
                          borderRadius:
                              BorderRadius.circular(size.width * 0.031),
                          border: Border.all(color: secondaryColor, width: 1),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$semesterNumber',
                                style: TextStyle(
                                  fontSize: size.width * 0.095,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              SizedBox(height: size.height * 0.01),
                              Text(
                                'Semester',
                                style: TextStyle(
                                  fontSize: size.width * 0.062,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
