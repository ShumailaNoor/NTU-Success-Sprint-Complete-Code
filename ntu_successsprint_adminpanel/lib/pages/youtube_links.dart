import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:ntu_successsprint_adminpanel/constant.dart';
import 'package:ntu_successsprint_adminpanel/video_generator_services.dart';
import 'package:ntu_successsprint_adminpanel/widgets/custom_card.dart';
import 'package:ntu_successsprint_adminpanel/widgets/dropdown.dart';
import 'package:ntu_successsprint_adminpanel/widgets/fetched_list_view.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _fetchYouTubeVideos() async {
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
        _showDeleteYouTubeVideoDialog();
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
    String selectedLanguage = 'English Only';
    final List<String> _languageOptions = ['English Only', 'Urdu/Hindi Only'];
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text("Generate AI Video"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedLanguage,
                  decoration: InputDecoration(
                    labelText: "Select Language",
                    border: OutlineInputBorder(),
                  ),
                  items: _languageOptions.map((lang) {
                    return DropdownMenuItem<String>(
                      value: lang,
                      child: Text(lang),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedLanguage = value;
                      });
                    }
                  },
                ),
                SizedBox(height: 20),
                isLoading
                    ? Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text("Fetching videos and transcripts..."),
                        ],
                      )
                    : ElevatedButton.icon(
                        onPressed: () async {
                          setState(() {
                            isLoading = true;
                          });

                          try {
                            final results =
                                await VideoGeneratorService.generateForTopic(
                              selectedTopic!,
                              selectedCourse!,
                              selectedLanguage,
                            );

                            setState(() {
                              isLoading = false;
                            });

                            if (results.isEmpty) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("⚠️ No videos found."),
                                ),
                              );
                              return;
                            }

                            // Close current dialog and show preview
                            Navigator.pop(context);
                            _showVideoPreviewDialog(
                                results.first, selectedLanguage);
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                            print("🛑 Error generating videos: $e");
                          }
                        },
                        icon: Icon(
                          Icons.auto_fix_high,
                          color: Colors.white,
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        label: Text("Search with AI"),
                      ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showVideoPreviewDialog(
      Map<String, String> video, String selectedLanguage) {
    bool isSaving = false;
    final TextEditingController transcriptController =
        TextEditingController(text: video["transcript"]);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Video Preview"),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                  },
                ),
              ],
            ),
            content: Container(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Title
                    Text(
                      "Title:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        video["title"] ?? "Untitled Video",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Video Link
                    Text(
                      "YouTube Link:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: secondaryColor.withOpacity(0.3)),
                      ),
                      child: InkWell(
                        onTap: () async {
                          // Open YouTube link in browser
                          final url = video["link"] ?? "";
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url),
                                mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text("❌ Could not launch URL.")),
                            );
                          }
                        },
                        child: Row(
                          children: [
                            Icon(Icons.link,
                                color: secondaryColor.withOpacity(0.6),
                                size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                video["link"] ?? "No link available",
                                style: TextStyle(
                                  color: secondaryColor,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Language
                    Text(
                      "Language:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: primaryColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        selectedLanguage,
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Transcript Preview
                    Text(
                      "Transcript:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: transcriptController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: "Enter transcript here...",
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        // Regenerate Button
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () {
                                    Navigator.pop(context);
                                    _showAddYouTubeVideoDialog(); // Go back to generate new video
                                  },
                            icon: Icon(Icons.refresh, color: secondaryColor),
                            label: Text("Regenerate"),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),

                        SizedBox(width: 12),

                        // Save Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    setState(() {
                                      isSaving = true;
                                    });

                                    try {
                                      print("🎬 Saving Video:");
                                      print("→ Title: ${video["title"]}");
                                      print("→ Link: ${video["link"]}");
                                      print(
                                          "→ Transcript: ${video["transcript"]}");

                                      await database
                                          .child("All Topics")
                                          .child(selectedTopic!)
                                          .push()
                                          .set({
                                        "title":
                                            video["title"] ?? "Untitled Video",
                                        "link_url": video["link"] ?? "",
                                        "language": selectedLanguage,
                                        "transcript": transcriptController.text
                                                .trim()
                                                .isNotEmpty
                                            ? transcriptController.text.trim()
                                            : "Transcript not provided",
                                      });

                                      Navigator.pop(
                                          context); // Close preview dialog

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              "✅ Video saved successfully!"),
                                        ),
                                      );
                                    } catch (e) {
                                      setState(() {
                                        isSaving = false;
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text("❌ Error saving video: $e"),
                                        ),
                                      );
                                      print("🛑 Error saving video: $e");
                                    }
                                  },
                            icon: isSaving
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Icon(Icons.save, color: Colors.white),
                            label: Text(isSaving ? "Saving..." : "Save Video"),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
                icon: Icons.smart_toy,
                text: "Search via AI",
                onTap: () {
                  if (selectedProgram == null ||
                      selectedSemester == null ||
                      selectedCourse == null ||
                      selectedTopic == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              "Please select a program, semester, course and topic.")),
                    );
                    return;
                  }
                  _showAddYouTubeVideoDialog();
                },
                color: secondaryColor,
              ),
              CustomCard(
                icon: Icons.delete,
                text: "Delete Youtube Videos",
                onTap: () {
                  if (selectedProgram == null ||
                      selectedSemester == null ||
                      selectedCourse == null ||
                      selectedTopic == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              "Please select a program, semester, course and topic.")),
                    );
                    return;
                  }
                  _fetchYouTubeVideos();
                },
                color: primaryColor,
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
                  languageKey: "language",
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
