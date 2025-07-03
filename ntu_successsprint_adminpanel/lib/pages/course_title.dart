import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:ntu_successsprint_adminpanel/constant.dart';
import 'package:ntu_successsprint_adminpanel/widgets/custom_card.dart';
import 'package:ntu_successsprint_adminpanel/widgets/dropdown.dart';
import 'package:ntu_successsprint_adminpanel/widgets/fetched_list_view.dart';

class ManageCourseTitle extends StatefulWidget {
  const ManageCourseTitle({super.key});

  @override
  State<ManageCourseTitle> createState() => _ManageCourseTitleState();
}

class _ManageCourseTitleState extends State<ManageCourseTitle> {
  final DatabaseReference database = FirebaseDatabase.instance.ref();

  String? selectedProgram;
  String? selectedSemester;
  final TextEditingController _courseTitleController = TextEditingController();
  final TextEditingController _editController = TextEditingController();
  Map<String, String> courseTitles = {};

// Add Course Title to Firebase
  Future<void> _addCourseTitle() async {
    if (selectedProgram == null || selectedSemester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a program and semester")),
      );
      return;
    }

    String courseTitle = _courseTitleController.text.trim();
    if (courseTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Course title cannot be empty")),
      );
      return;
    }
    database
        .child(selectedProgram!)
        .child(selectedSemester!)
        .child("Courses")
        .push()
        .set({"title": courseTitle}).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Course Title Added Successfully!"),
        ),
      );
      Navigator.pop(context); // Close the dialog
      _courseTitleController.clear(); // Clear the text field
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $error"),
        ),
      );
    });
  }

// Fetch course titles from Firebase
  Future<void> _fetchCourseTitles(String purpose) async {
    if (selectedProgram == null || selectedSemester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a program and semester")),
      );
      return;
    }

    DatabaseReference coursesRef = database
        .child(selectedProgram!)
        .child(selectedSemester!)
        .child("Courses");

    coursesRef.once().then((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> values =
            event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          courseTitles.clear();
          values.forEach((key, value) {
            courseTitles[key] = value["title"];
          });
        });
        if (purpose.contains('Update')) {
          _showUpdateDialog();
        } else {
          _showDeleteDialog();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No course titles found.")),
        );
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching courses: $error")),
      );
    });
  }

// Function to update course title in Firebase and update the UI instantly
  Future<void> _updateCourseTitle(String key, String newTitle) async {
    database
        .child(selectedProgram!)
        .child(selectedSemester!)
        .child("Courses")
        .child(key)
        .update({"title": newTitle}).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Course Title Updated Successfully!")),
      );

      // Update the local list immediately
      setState(() {
        courseTitles[key] = newTitle;
      });
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating course: $error")),
      );
    });
  }

  // Delete course title from Firebase and update UI
  void _deleteCourseTitle(String key, Function setDialogState) {
    if (selectedProgram == null || selectedSemester == null) return;

    database
        .child(selectedProgram!)
        .child(selectedSemester!)
        .child("Courses")
        .child(key)
        .remove()
        .then((_) {
      setDialogState(() {
        courseTitles.remove(key); // Remove from local list
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Course Title Deleted Successfully!")),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $error")),
      );
    });
  }

  // Show Add Course Title Dialog
  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Add Course Title"),
          content: SizedBox(
            width: 200,
            child: TextField(
              controller: _courseTitleController,
              onSubmitted: (_) => _addCourseTitle(),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryColor, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                hintText: 'Enter Course Title',
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
            ElevatedButton.icon(
              onPressed: _addCourseTitle,
              label: Text("Add"),
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

// Show Update Course Title Dialog
  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) {
        Set<String> updatedKeys = {};
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text("Update Course Title"),
            content: SizedBox(
              height: 300,
              width: 400,
              child: ListView.builder(
                itemCount: courseTitles.length,
                itemBuilder: (context, index) {
                  String key = courseTitles.keys.elementAt(index);
                  String title = courseTitles[key]!;

                  return ListTile(
                    title: Text(title),
                    trailing: IconButton(
                      icon: Icon(Icons.edit, color: secondaryColor),
                      onPressed: () {
                        _editController.text = title;

                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor: Colors.white,
                              title: Text("Edit Course Title"),
                              content: SizedBox(
                                width: 200,
                                child: TextField(
                                  controller: _editController,
                                  onSubmitted: (value) {
                                    String newTitle =
                                        _editController.text.trim();

                                    if (newTitle.isNotEmpty) {
                                      _updateCourseTitle(key, newTitle)
                                          .then((_) {
                                        setDialogState(() {
                                          courseTitles[key] = newTitle;
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
                                    String newTitle =
                                        _editController.text.trim();

                                    if (newTitle.isNotEmpty) {
                                      _updateCourseTitle(key, newTitle)
                                          .then((_) {
                                        setDialogState(() {
                                          courseTitles[key] = newTitle;
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

// Show Delete Course Title Dialog
  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        // Track deleted items
        Set<String> deletedKeys = {};

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text("Delete Course Title"),
            content: SizedBox(
              height: 300,
              width: 400,
              child: ListView.builder(
                itemCount: courseTitles.length,
                itemBuilder: (context, index) {
                  String key = courseTitles.keys.elementAt(index);
                  String title = courseTitles[key]!;

                  return ListTile(
                    title: Text(title),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: secondaryColor),
                      onPressed: () {
                        _deleteCourseTitle(key, (fn) {
                          setDialogState(() {
                            fn(); // update local courseTitles
                            deletedKeys.add(key); // track deletion
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
                    : null, // Disable if nothing deleted
                label: Text("Done"),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: deletedKeys.isNotEmpty
                      ? primaryColor
                      : Colors.grey, // Change color for feedback
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

// Build the Manage Course Title Page UI
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
            "Manage Course Title",
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
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Cards Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomCard(
                icon: Icons.add,
                text: "Add Course Title",
                onTap: () {
                  if (selectedProgram == null || selectedSemester == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text("Please select a program and semester")),
                    );
                    return;
                  }
                  _showAddDialog();
                },
                color: tertiaryColor,
              ),
              CustomCard(
                icon: Icons.edit,
                text: "Update Course Title",
                onTap: () => _fetchCourseTitles('Update'),
                color: primaryColor,
              ),
              CustomCard(
                icon: Icons.delete,
                text: "Delete Course Title",
                onTap: () => _fetchCourseTitles('Delete'),
                color: secondaryColor,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                "Available Course Title",
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
              // Display Course ListContainer
              child: SingleChildScrollView(
                child: FirebaseListView(
                  selectedPath:
                      selectedProgram != null && selectedSemester != null
                          ? "$selectedProgram/$selectedSemester/Courses"
                          : null,
                  database: database,
                  fieldKey: "title",
                  emptyMessage: "Select a Program and Semester to View Courses",
                  leadingIcon: Icons.book,
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
