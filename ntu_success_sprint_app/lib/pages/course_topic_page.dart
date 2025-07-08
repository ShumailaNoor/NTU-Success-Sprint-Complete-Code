import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:ntu_success_sprint_app/constant.dart';
import 'package:ntu_success_sprint_app/pages/youtube_video_page.dart';

class CourseAndTopicPage extends StatefulWidget {
  final String selectedProgram;
  final String selectedSemester;

  const CourseAndTopicPage({
    super.key,
    required this.selectedProgram,
    required this.selectedSemester,
  });

  @override
  State<CourseAndTopicPage> createState() => _CourseAndTopicPageState();
}

class _CourseAndTopicPageState extends State<CourseAndTopicPage> {
  final database = FirebaseDatabase.instance.ref();
  Map<String, String> courseTitles = {};
  Map<String, String> courseContent = {};
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  String? selectedCourse;
  String? selectedTopic;

  @override
  void initState() {
    super.initState();
    _fetchCourseTitles();
  }

  Future<void> _fetchCourseTitles() async {
    final ref = database
        .child(widget.selectedProgram)
        .child(widget.selectedSemester)
        .child("Courses");

    try {
      final event = await ref.once();
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> values =
            event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          courseTitles.clear();
          values.forEach((key, value) {
            courseTitles[key] = value["title"];
          });
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading courses: $e")),
      );
    }
  }

  Future<void> _fetchCourseContent(String courseKey) async {
    final ref = database.child("All Courses").child(courseKey);

    try {
      print("Fetching course content for: $courseKey");
      final event = await ref.once();
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> values =
            event.snapshot.value as Map<dynamic, dynamic>;

        final sortedEntries = values.entries.toList()
          ..sort((a, b) {
            final aSeq = a.value['sequence'] ?? 0;
            final bSeq = b.value['sequence'] ?? 0;
            return (aSeq is num ? aSeq : int.tryParse(aSeq.toString()) ?? 0)
                .compareTo(
                    bSeq is num ? bSeq : int.tryParse(bSeq.toString()) ?? 0);
          });

        Map<String, String> topics = {};
        for (var entry in sortedEntries) {
          final key = entry.key;
          final value = entry.value;
          print("Found topic key: $key, value: $value");

          if (value is Map && value.containsKey("content")) {
            topics[key] = value["content"];
          }
        }

        setState(() {
          courseContent = topics;
          selectedTopic = null; // Reset on course change
        });
        print("courseContent after fetch: $courseContent");
      } else {
        setState(() {
          courseContent.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading topics: $e")),
      );
    }
  }

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
                      'Please Select the Course',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: size.width * 0.05,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: size.height * 0.014),

              /// Dropdown
              DropdownButtonFormField<String>(
                value: selectedCourse,
                hint: Text("Select Course"),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(size.width * 0.027),
                  ),
                ),
                items: courseTitles.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCourse = value;
                  });
                  print("Selected course title: ${courseTitles[value]}");
                  _fetchCourseContent(courseTitles[value]!);
                },
              ),

              SizedBox(height: size.height * 0.025),

              /// Topics List
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: size.height * 0.012),
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(size.width * 0.033),
                    border: Border.all(color: secondaryColor, width: 2),
                  ),
                  child: Column(
                    children: [
                      // 🔍 Search Field
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 8),
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Search topics...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value.toLowerCase();
                            });
                          },
                        ),
                      ),

                      // 📝 Filtered List
                      Expanded(
                        child: courseContent.isEmpty
                            ? Center(
                                child: Text(
                                  "No topics available.",
                                  style: TextStyle(color: Colors.black54),
                                ),
                              )
                            : ListView(
                                children: courseContent.entries
                                    .where((entry) => entry.value
                                        .toLowerCase()
                                        .contains(searchQuery))
                                    .map((entry) {
                                  return RadioListTile<String>(
                                    title: Text(entry.value),
                                    fillColor: MaterialStateProperty.all(
                                        secondaryColor),
                                    value: entry.key,
                                    groupValue: selectedTopic,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedTopic = value;
                                      });
                                    },
                                    activeColor: primaryColor,
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.020),

              /// Next Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding:
                        EdgeInsets.symmetric(vertical: size.height * 0.018),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(size.width * 0.027),
                    ),
                  ),
                  onPressed: () {
                    if (selectedCourse == null || selectedTopic == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Please select both course and topic."),
                        ),
                      );
                      return;
                    }

                    // Proceed to next page with selected course & topic
                    // Navigator.push(...);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => YouTubeVideoPage(
                          selectedProgram: widget.selectedProgram,
                          selectedSemester: widget.selectedSemester,
                          selectedCourse: courseTitles[selectedCourse!]!,
                          selectedTopic: courseContent[selectedTopic!]!,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Next',
                    style: TextStyle(
                        fontSize: size.width * 0.044, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
