import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:ntu_successsprint_adminpanel/constant.dart';
import 'package:ntu_successsprint_adminpanel/widgets/custom_card.dart';
import 'package:ntu_successsprint_adminpanel/widgets/dropdown.dart';
import 'package:ntu_successsprint_adminpanel/widgets/fetched_list_view.dart';

class ManageCourseOutline extends StatefulWidget {
  const ManageCourseOutline({super.key});

  @override
  State<ManageCourseOutline> createState() => _ManageCourseOutlineState();
}

class _ManageCourseOutlineState extends State<ManageCourseOutline> {
  final DatabaseReference database = FirebaseDatabase.instance.ref();

  String? selectedProgram;
  String? selectedSemester;
  String? selectedCourse;
  Map<String, String> courses = {};
  Map<String, Map<String, dynamic>> courseContent = {};
  final TextEditingController _addContentController = TextEditingController();
  final TextEditingController _editContentController = TextEditingController();

  String? _selectedAfterKey; // Added to fix undefined name error
  List<Map<String, dynamic>> _courseTopics =
      []; // Added to fix undefined name error

// Fetch Courses from Firebase
  void _fetchCourses() {
    if (selectedProgram == null || selectedSemester == null) return;

    database
        .child(selectedProgram!)
        .child(selectedSemester!)
        .child("Courses")
        .onValue
        .listen((event) {
      Map<String, String> titles = {}; // Always reset

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> courseData =
            event.snapshot.value as Map<dynamic, dynamic>;
        courseData.forEach((key, value) {
          titles[key.toString()] = value["title"].toString();
        });
      }

      setState(() {
        courses = titles;
        selectedCourse = "Select Course"; // Reset dropdown
      });
      if (titles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "No courses available for the selected semester or pragram."),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  Future<void> _handleAddContentClick(String purpose) async {
    await _fetchCourseContent();

    if (purpose.contains('Add')) {
      _showAddContentDialog();
    } else if (purpose.contains('Update')) {
      _showUpdateCourseContentDialog();
    } else {
      _showDeleteCourseContentDialog();
    }
  }

  // Add Course Content to Firebase
  void _addCourseContent() async {
    if (_addContentController.text.isEmpty) return;

    final courseRef = database.child("All Courses").child(selectedCourse!);

    double newSequence = 1.0;

    if (_selectedAfterKey != null) {
      final entries = courseContent.entries.toList()
        ..sort((a, b) =>
            (a.value['sequence'] as num).compareTo(b.value['sequence'] as num));

      if (_selectedAfterKey == "TOP_OF_LIST") {
        // Insert before the first item
        final double firstSeq = entries.first.value['sequence'].toDouble();
        newSequence = firstSeq - 1; // ensures it's before all others
      } else {
        final currentIndex =
            entries.indexWhere((e) => e.key == _selectedAfterKey);
        final double currentSeq =
            entries[currentIndex].value['sequence'].toDouble();
        final double? nextSeq = currentIndex + 1 < entries.length
            ? entries[currentIndex + 1].value['sequence'].toDouble()
            : null;
        newSequence =
            nextSeq != null ? (currentSeq + nextSeq) / 2 : currentSeq + 1;
      }
    } else {
      // If no position selected, just append
      final snapshot =
          await courseRef.orderByChild("sequence").limitToLast(1).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        final sorted = data.entries.toList()
          ..sort((a, b) => ((a.value["sequence"] ?? 0) as num)
              .compareTo((b.value["sequence"] ?? 0) as num));

        final lastEntry = sorted.last;
        final lastSeq = (lastEntry.value["sequence"] ?? 0).toDouble();
        newSequence = lastSeq + 1;
      }
    }

    await courseRef.push().set({
      "content": _addContentController.text.trim(),
      "sequence": newSequence,
    }).then((_) async {
      await _fetchCourseContent();
      Navigator.pop(context);
      _addContentController.clear();
      _selectedAfterKey = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Course Content Outline Added Successfully!")),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $error")),
      );
    });
  }

  Future<void> _fetchCourseContent() async {
    if (selectedProgram == null ||
        selectedSemester == null ||
        selectedCourse == null ||
        selectedCourse == "Select Course") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a program, semester and course")),
      );
      return;
    }

    DatabaseReference contentRef =
        database.child("All Courses").child(selectedCourse!);

    try {
      DatabaseEvent event = await contentRef.orderByChild("sequence").once();
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        Map<String, Map<String, dynamic>> contentMap = {};

        data.forEach((key, value) {
          if (value is Map && value.containsKey("content")) {
            contentMap[key.toString()] = {
              "content": value["content"].toString(),
              "sequence": value["sequence"] ?? 0.0
            };
          }
        });
        // Sort by sequence
        final sortedContent = Map.fromEntries(contentMap.entries.toList()
          ..sort((a, b) => (a.value['sequence'] as num)
              .compareTo(b.value['sequence'] as num)));

        setState(() {
          courseContent = sortedContent;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No course content found.")),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching content: $error")),
      );
    }
  }

//Update Course Content in Firebase
  Future<void> _updateCourseContent(String key, String newContent) async {
    await database
        .child("All Courses")
        .child(selectedCourse!)
        .child(key)
        .update({"content": newContent}).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Course Content Updated Successfully!")),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating content: $error")),
      );
    });
  }

//Delete Course Content from Firebase
  void _deleteCourseContent(String key, Function setDialogState) {
    if (selectedProgram == null ||
        selectedSemester == null ||
        selectedCourse == null) {
      return;
    }

    DatabaseReference contentRef =
        database.child("All Courses").child(selectedCourse!).child(key);

    contentRef.remove().then((_) {
      setDialogState(() {
        courseContent.remove(key); // Remove from local list
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Course Content Deleted Successfully!")),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $error")),
      );
    });
  }

  // Show Add Course Content Dialog
  void _showAddContentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Add Course Content"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (courseContent.isNotEmpty)
                SizedBox(
                  width: 300,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: "Insert At",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: TextStyle(
                      // This controls the selected item text style
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: "TOP_OF_LIST",
                        child: Text("Insert at the beginning"),
                      ),
                      ...courseContent.entries
                          .map((entry) => DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value['content']),
                              )),
                    ],
                    onChanged: (value) {
                      _selectedAfterKey = value;
                    },
                  ),
                ),
              if (courseContent.isEmpty)
                Text(
                  "No topics available. This will be the first.",
                  style: TextStyle(color: Colors.grey),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _addContentController,
                  onSubmitted: (value) => _addCourseContent(),
                  decoration: InputDecoration(
                    hintText: "Enter New Course Content",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Cancel",
                style: TextStyle(color: secondaryColor),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addCourseContent,
              label: Text("Done"),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

// Show Update Course Content Dialog
  void _showUpdateCourseContentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        Set<String> updatedKeys = {};
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text("Update Course Content"),
            content: SizedBox(
              height: 300,
              width: 400,
              child: ListView.builder(
                itemCount: courseContent.length,
                itemBuilder: (context, index) {
                  String key = courseContent.keys.elementAt(index);
                  String content = courseContent[key]!['content'];

                  return ListTile(
                    title: Text(content),
                    trailing: IconButton(
                      icon: Icon(Icons.edit, color: secondaryColor),
                      onPressed: () {
                        _editContentController.text = content;

                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor: Colors.white,
                              title: Text("Edit Course Content"),
                              content: SizedBox(
                                width: 200,
                                child: TextField(
                                  controller: _editContentController,
                                  onSubmitted: (value) {
                                    String newContent =
                                        _editContentController.text.trim();

                                    if (newContent.isNotEmpty) {
                                      _updateCourseContent(key, newContent)
                                          .then((_) {
                                        setDialogState(() {
                                          courseContent[key] = {
                                            "content": newContent,
                                            "sequence":
                                                courseContent[key]!['sequence'],
                                          };
                                          updatedKeys.add(key);
                                        });
                                        Navigator.pop(context);
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: primaryColor, width: 2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(color: secondaryColor),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    String newContent =
                                        _editContentController.text.trim();

                                    if (newContent.isNotEmpty) {
                                      _updateCourseContent(key, newContent)
                                          .then((_) {
                                        setDialogState(() {
                                          courseContent[key] = {
                                            "content": newContent,
                                            "sequence":
                                                courseContent[key]!['sequence'],
                                          };
                                          updatedKeys.add(key);
                                        });
                                        Navigator.pop(context);
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text("Update"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Cancel",
                  style: TextStyle(color: secondaryColor),
                ),
              ),
              ElevatedButton.icon(
                onPressed: updatedKeys.isNotEmpty
                    ? () => Navigator.pop(context)
                    : null,
                label: Text("Done"),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor:
                      updatedKeys.isNotEmpty ? primaryColor : Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

// Show Delete Course Content Dialog
  void _showDeleteCourseContentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        Set<String> deletedKeys = {};
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text("Delete Course Content"),
            content: SizedBox(
              height: 300,
              width: 400,
              child: ListView.builder(
                itemCount: courseContent.length,
                itemBuilder: (context, index) {
                  String key = courseContent.keys.elementAt(index);
                  String content = courseContent[key]!['content'];

                  return ListTile(
                    title: Text(content),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: secondaryColor),
                      onPressed: () {
                        _deleteCourseContent(key, (fn) {
                          setDialogState(() {
                            fn();
                            deletedKeys.add(key);
                          });
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text("Cancel", style: TextStyle(color: secondaryColor)),
              ),
              ElevatedButton.icon(
                onPressed: deletedKeys.isNotEmpty
                    ? () => Navigator.pop(context)
                    : null,
                label: Text("Done"),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor:
                      deletedKeys.isNotEmpty ? primaryColor : Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

// Build the Manage Course Content Page UI
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Page Title
          Text(
            "Manage Course Content Outline",
            style: TextStyle(
              fontSize: size.width * 0.025,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // Dropdown Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownContainer(
                hint: "Select Program",
                value: selectedProgram,
                items: programs,
                onChanged: (value) {
                  setState(() {
                    selectedProgram = value;
                    _fetchCourses();
                  });
                },
              ),
              const SizedBox(width: 20),
              DropdownContainer(
                hint: "Select Semester",
                value: selectedSemester,
                items: semesters,
                onChanged: (value) {
                  setState(() {
                    selectedSemester = value;
                    _fetchCourses();
                  });
                },
              ),
              const SizedBox(width: 20),
              DropdownContainer(
                hint: "Select Course",
                value:
                    selectedCourse == "Select Course" ? null : selectedCourse,
                items: courses.values.toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCourse = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 30),
          //cards row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomCard(
                icon: Icons.add,
                text: "Add Course Topic",
                onTap: () {
                  if (selectedProgram == null ||
                      selectedSemester == null ||
                      selectedCourse == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text("Please select Program, Semester and Course"),
                      ),
                    );
                    return;
                  }
                  _handleAddContentClick("Add");
                },
                color: tertiaryColor,
              ),
              CustomCard(
                icon: Icons.edit,
                text: "Update Course Topic",
                onTap: () {
                  if (selectedProgram == null ||
                      selectedSemester == null ||
                      selectedCourse == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text("Please select Program, Semester and Course"),
                      ),
                    );
                    return;
                  }
                  _handleAddContentClick("Update");
                },
                color: primaryColor,
              ),
              CustomCard(
                icon: Icons.delete,
                text: "Delete Course Topic",
                onTap: () {
                  if (selectedProgram == null ||
                      selectedSemester == null ||
                      selectedCourse == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text("Please select Program, Semester and Course"),
                      ),
                    );
                    return;
                  }
                  _handleAddContentClick("Delete");
                },
                color: secondaryColor,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                "All Course Topics",
                style: TextStyle(
                  fontSize: size.width * 0.015,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                textAlign: TextAlign.start,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Course Content Display Container
          Expanded(
            child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: FirebaseListView(
                  selectedPath: selectedProgram != null &&
                          selectedSemester != null &&
                          selectedCourse != null
                      ? "All Courses/$selectedCourse"
                      : null,
                  database: database,
                  fieldKey: "content",
                  emptyMessage:
                      "Select a Program, Semester and Course to View Topics",
                  leadingIcon: Icons.description,
                  iconColor: primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
