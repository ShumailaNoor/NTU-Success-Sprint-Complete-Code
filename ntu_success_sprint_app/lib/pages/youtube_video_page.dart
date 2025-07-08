import 'package:flutter/material.dart';
import 'package:ntu_success_sprint_app/constant.dart';
import 'package:ntu_success_sprint_app/gemini_services.dart';
import 'package:ntu_success_sprint_app/pages/login_page.dart';
import 'package:ntu_success_sprint_app/pages/quiz_page.dart';
import 'package:ntu_success_sprint_app/provider/user_provider.dart';
import 'package:ntu_success_sprint_app/provider/video_provider.dart';
import 'package:ntu_success_sprint_app/widgets/shimmer_video_placeholder.dart';
import 'package:ntu_success_sprint_app/widgets/video_player_card.dart';
import 'package:provider/provider.dart';

class YouTubeVideoPage extends StatefulWidget {
  final String selectedTopic;
  final String selectedProgram;
  final String selectedCourse;
  final String selectedSemester;

  const YouTubeVideoPage({
    super.key,
    required this.selectedTopic,
    required this.selectedProgram,
    required this.selectedSemester,
    required this.selectedCourse,
  });

  @override
  State<YouTubeVideoPage> createState() => _YouTubeVideoPageState();
}

class _YouTubeVideoPageState extends State<YouTubeVideoPage> {
  bool isComplete = false;

  @override
  void initState() {
    super.initState();
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    videoProvider.fetchVideos(widget.selectedTopic);
  }

  Future<void> _giveQuiz(VideoProvider provider) async {
    for (var controller in provider.controllers) {
      controller.pause();
    }
    if (provider.combinedTranscript.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "No transcript available for video",
          ),
          backgroundColor: primaryColor,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: CircularProgressIndicator(color: primaryColor),
        );
      },
    );

    final mcqs = await GeminiService.generateMcqs(provider.combinedTranscript);

    Navigator.of(context).pop();

    if (mcqs.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizPage(
            mcqs: mcqs,
            selectedTopic: widget.selectedTopic,
            selectedProgram: widget.selectedProgram,
            selectedSemester: widget.selectedSemester,
            selectedCourse: widget.selectedCourse,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No MCQs Available for this topic."),
          backgroundColor: primaryColor,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showNavigateToLoginPageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          icon: Icon(Icons.warning, color: primaryColor, size: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text("Login Required",
              style: TextStyle(
                  color: secondaryColor, fontWeight: FontWeight.bold)),
          content: Text("You need to be logged in to give the quiz.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700])),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text("Go to Login Page"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final videoProvider = Provider.of<VideoProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(size.width * 0.027),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.042,
                      vertical: size.height * 0.018),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(size.width * 0.048),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: size.width * 0.012,
                        offset: Offset(3, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        color: primaryColor,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      SizedBox(
                        width: size.width * 0.027,
                      ),
                      Expanded(
                        child: Text(
                          widget.selectedTopic,
                          style: TextStyle(
                            fontSize: size.width * 0.038,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: size.height * 0.01),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.055,
                      vertical: size.height * 0.018),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(size.width * 0.066),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: size.width * 0.015,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.recommend_rounded,
                          color: secondaryColor, size: size.width * 0.069),
                      SizedBox(width: size.width * 0.05),
                      Text(
                        'Best Recommended Videos',
                        style: TextStyle(
                          fontSize: size.width * 0.05,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                // Render all video players
                videoProvider.isLoading
                    ? Column(
                        children: List.generate(
                            2, (index) => ShimmerVideoPlaceholder(size: size)),
                      )
                    : Column(
                        children: List.generate(
                          videoProvider.youtubeLinks.length,
                          (i) {
                            final title = videoProvider.youtubeLinks.values
                                .elementAt(i)["title"]!;
                            final language = videoProvider.youtubeLinks.values
                                    .elementAt(i)["language"] ??
                                "Unknown";
                            final transcript = videoProvider.youtubeLinks.values
                                    .elementAt(i)["transcript"] ??
                                "";
                            final controller = videoProvider.controllers[i];
                            return VideoPlayerCard(
                              size: size,
                              controller: controller,
                              title: title,
                              language: language,
                              transcript: transcript,
                              isLastVideo:
                                  i == videoProvider.youtubeLinks.length - 1,
                            );
                          },
                        ),
                      ),
                // Mark as Complete button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: isComplete,
                          onChanged: (value) {
                            setState(() {
                              isComplete = value!;
                            });
                          },
                          activeColor: secondaryColor,
                        ),
                        SizedBox(width: size.width * 0.02),
                        Text(
                          'Mark as Complete',
                          style: TextStyle(
                            fontSize: size.width * 0.038,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: isComplete
                          ? (userProvider.isLoggedIn
                              ? () => _giveQuiz(videoProvider)
                              : _showNavigateToLoginPageDialog)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isComplete ? secondaryColor : Colors.grey,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, size.height * 0.06),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(size.width * 0.027),
                        ),
                      ),
                      child: Text(
                        "Give Quiz",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width * 0.038,
                          fontWeight: FontWeight.bold,
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
  }
}
