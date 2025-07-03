import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:ntu_successsprint_adminpanel/constant.dart';
import 'package:ntu_successsprint_adminpanel/widgets/custom_card.dart';
import 'package:ntu_successsprint_adminpanel/widgets/dropdown.dart';
import 'package:ntu_successsprint_adminpanel/widgets/fetched_list_view.dart';

class ManageYoutubeLink extends StatefulWidget {
  const ManageYoutubeLink({super.key});

  @override
  State<ManageYoutubeLink> createState() => _ManageYoutubeLinkState();
}

class _ManageYoutubeLinkState extends State<ManageYoutubeLink> {
  final DatabaseReference database = FirebaseDatabase.instance.ref();

  String? selectedProgram;
  String? selectedSemester;
  String? selectedCourse;
  String? selectedTopic;
  Map<String, String> courses = {};
  Map<String, String> courseContents = {};
  Map<String, Map<String, String>> youtubeLinks = {};

  final TextEditingController _addTitleController = TextEditingController();
  final TextEditingController _addLinkController = TextEditingController();
  final TextEditingController _addTranscriptController =
      TextEditingController();
  final TextEditingController _editTitleController = TextEditingController();
  final TextEditingController _editUrlController = TextEditingController();
  final TextEditingController _editTranscriptController =
      TextEditingController();

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

  void _fetchCourseContent() {
    if (selectedProgram == null ||
        selectedSemester == null ||
        selectedCourse == null) return;

    database
        .child("All Courses")
        .child(selectedCourse!)
        .onValue
        .listen((event) {
      Map<String, String> topics = {}; // Always reset

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> courseData =
            event.snapshot.value as Map<dynamic, dynamic>;
        courseData.forEach((key, value) {
          topics[key.toString()] = value["content"].toString();
        });
      }

      setState(() {
        courseContents = topics;
        selectedTopic = "Select Topic"; // Reset dropdown
      });

      if (topics.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No topics available for the selected course."),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _addYouTubeVideo() {
    if (_addTitleController.text.isNotEmpty &&
        _addLinkController.text.isNotEmpty) {
      database.child("All Topics").child(selectedTopic!).push().set({
        "title": _addTitleController.text.trim(),
        "link_url": _addLinkController.text.trim(),
        "transcript": _addTranscriptController.text.trim(),
      }).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("YouTube Video Data Added Successfully!")),
        );
        Navigator.pop(context);
        _addTitleController.clear();
        _addLinkController.clear();
        _addTranscriptController.clear();
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $error")),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter title, link and transcript!")),
      );
    }
  }

  // Fetch YouTube Videos from Firebase
  Future<void> _fetchYouTubeVideos(String purpose) async {
    if (selectedProgram == null ||
        selectedSemester == null ||
        selectedCourse == null ||
        selectedCourse == "Select Course") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Please select a program, semester, course and topic")),
      );
      return;
    }

    DatabaseReference videosRef =
        database.child("All Topics").child(selectedTopic!);
    try {
      DatabaseEvent event = await videosRef.once();
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        Map<String, Map<String, String>> videoMap = {};

        data.forEach((key, value) {
          if (value is Map &&
              value.containsKey("title") &&
              value.containsKey("link_url") &&
              value.containsKey("transcript")) {
            videoMap[key.toString()] = {
              "title": value["title"].toString(),
              "link_url": value["link_url"].toString(),
              "transcript": value["transcript"].toString(),
            };
          }
        });

        setState(() {
          youtubeLinks = videoMap;
        });

        // Invoke the respective dialog
        if (purpose.contains('Update')) {
          _showUpdateYouTubeVideoDialog();
        } else {
          _showDeleteYouTubeVideoDialog();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No YouTube videos found.")),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching videos: $error")),
      );
    }
  }

// Update YouTube Video in Firebase
  Future<void> _updateYouTubeVideo(
      String key, String newTitle, String newUrl, String newTranscript) async {
    await database.child("All Topics").child(selectedTopic!).child(key).update({
      "title": newTitle,
      "link_url": newUrl,
      "transcript": newTranscript
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("YouTube Video Updated Successfully!")),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating video: $error")),
      );
    });
  }

  void _deleteYouTubeVideo(String key, Function setDialogState) {
    if (selectedProgram == null ||
        selectedSemester == null ||
        selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Please select a valid program, semester, and course.")),
      );
      return;
    }

    DatabaseReference videoRef =
        database.child("All Topics").child(selectedTopic!).child(key);

    videoRef.remove().then((_) {
      setDialogState(() {
        youtubeLinks.remove(key); // Remove from UI
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("YouTube Video Deleted Successfully!")),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $error")),
      );
    });
  }

  void _showAddYouTubeVideoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Add YouTube Video"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 400,
                child: TextField(
                  controller: _addTitleController,
                  decoration: InputDecoration(
                    hintText: "Video Title",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: 400,
                child: TextField(
                  controller: _addLinkController,
                  decoration: InputDecoration(
                    hintText: "YouTube Link",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: 400,
                height: 240,
                child: TextFormField(
                  controller: _addTranscriptController,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: "Transcript",
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
              child: Text("Cancel", style: TextStyle(color: secondaryColor)),
            ),
            ElevatedButton.icon(
              onPressed: _addYouTubeVideo,
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

  // Show Update YouTube Video Dialog
  void _showUpdateYouTubeVideoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        Set<String> updatedKeys = {};
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text("Update YouTube Videos"),
            content: SizedBox(
              height: 350,
              width: 450,
              child: ListView.builder(
                itemCount: youtubeLinks.length,
                itemBuilder: (context, index) {
                  String key = youtubeLinks.keys.elementAt(index);
                  Map<String, String> linkData = youtubeLinks[key]!;
                  String title = linkData["title"]!;
                  String url = linkData["link_url"]!;
                  String transcript = linkData["transcript"]!;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(url, style: TextStyle(color: secondaryColor)),
                        const SizedBox(height: 5),
                        Text(transcript,
                            maxLines: 3,
                            style: TextStyle(
                              color: primaryColor,
                            )),
                      ],
                    ),
                    shape: Border(
                      bottom: BorderSide(
                        color: Colors.grey,
                        width: 0.5,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.edit, color: secondaryColor),
                      onPressed: () {
                        _editTitleController.text = title;
                        _editUrlController.text = url;
                        _editTranscriptController.text = transcript;

                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor: Colors.white,
                              title: Text("Edit YouTube Video"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 400,
                                    child: TextField(
                                      controller: _editTitleController,
                                      decoration: InputDecoration(
                                        labelText: "Video Title",
                                        labelStyle:
                                            TextStyle(color: primaryColor),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: primaryColor, width: 2),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  SizedBox(
                                    width: 400,
                                    child: TextField(
                                      controller: _editUrlController,
                                      decoration: InputDecoration(
                                        labelText: "YouTube URL",
                                        labelStyle:
                                            TextStyle(color: primaryColor),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: primaryColor, width: 2),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  SizedBox(
                                    width: 400,
                                    height: 240,
                                    child: TextFormField(
                                      controller: _editTranscriptController,
                                      expands: true,
                                      maxLines: null,
                                      minLines: null,
                                      keyboardType: TextInputType.multiline,
                                      decoration: InputDecoration(
                                        labelText: "Transcript",
                                        labelStyle:
                                            TextStyle(color: primaryColor),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: primaryColor, width: 2),
                                          borderRadius:
                                              BorderRadius.circular(10),
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
                                ElevatedButton(
                                  onPressed: () {
                                    String newTitle =
                                        _editTitleController.text.trim();
                                    String newUrl =
                                        _editUrlController.text.trim();
                                    String newTranscript =
                                        _editTranscriptController.text.trim();

                                    if (newTitle.isNotEmpty &&
                                        newUrl.isNotEmpty &&
                                        newTranscript.isNotEmpty &&
                                        newUrl.startsWith("http")) {
                                      _updateYouTubeVideo(key, newTitle, newUrl,
                                              newTranscript)
                                          .then((_) {
                                        setDialogState(() {
                                          youtubeLinks[key]!["title"] =
                                              newTitle;
                                          youtubeLinks[key]!["link_url"] =
                                              newUrl;
                                          youtubeLinks[key]!["transcript"] =
                                              newTranscript;
                                          updatedKeys.add(key);
                                        });
                                        Navigator.pop(context);
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                "Enter valid title, URL and Transcript!")),
                                      );
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

  void _showDeleteYouTubeVideoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        Set<String> deletedKeys = {};
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text("Delete YouTube Video"),
            content: youtubeLinks.isEmpty
                ? Text("No videos available.")
                : SizedBox(
                    height: 300,
                    width: 400,
                    child: ListView.builder(
                      itemCount: youtubeLinks.length,
                      itemBuilder: (context, index) {
                        String key = youtubeLinks.keys.elementAt(index);
                        Map<String, String> linkData = youtubeLinks[key]!;
                        String title = linkData["title"] ?? "Unknown Title";

                        return ListTile(
                          title: Text(title),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: secondaryColor),
                            onPressed: () {
                              _deleteYouTubeVideo(key, (fn) {
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
            "Manage Content YouTube Links",
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
                    _fetchCourseContent();
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
                    _fetchCourseContent();
                  });
                },
              ),
              const SizedBox(width: 20),
              DropdownContainer(
                hint: "Select Topic",
                value: courseContents.values.contains(selectedTopic)
                    ? selectedTopic
                    : null,
                items: courseContents.values.toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTopic = value;
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
                text: "Add Content YouTube Link",
                onTap: () {
                  if (selectedProgram == null ||
                      selectedSemester == null ||
                      selectedCourse == null ||
                      selectedTopic == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              "Please select a program, semester, course and topic to add a YouTube link.")),
                    );
                    return;
                  }
                  _showAddYouTubeVideoDialog();
                },
                color: tertiaryColor,
              ),
              CustomCard(
                icon: Icons.edit,
                text: "Update Content YouTube Link",
                onTap: () {
                  _fetchYouTubeVideos("Update");
                },
                color: primaryColor,
              ),
              CustomCard(
                icon: Icons.delete,
                text: "Delete Content YouTube Link",
                onTap: () {
                  _fetchYouTubeVideos('Delete');
                },
                color: secondaryColor,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                "Available Course Content YouTube Links",
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
                  selectedPath: selectedProgram != null &&
                          selectedSemester != null &&
                          selectedCourse != null &&
                          selectedTopic != null
                      ? "All Topics/$selectedTopic"
                      : null,
                  database: database,
                  fieldKey: "title",
                  urlKey: "link_url",
                  transcriptKey: "transcript",
                  emptyMessage:
                      "Select a Program, Semester, Course and Topic to View YouTube Links",
                  leadingIcon: Icons.link,
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
