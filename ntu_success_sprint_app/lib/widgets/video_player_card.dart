import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../constant.dart';

class VideoPlayerCard extends StatelessWidget {
  final Size size;
  final YoutubePlayerController controller;
  final String title;
  final String language;
  final String transcript;
  final bool isLastVideo;

  const VideoPlayerCard({
    super.key,
    required this.size,
    required this.controller,
    required this.title,
    required this.language,
    required this.transcript,
    required this.isLastVideo,
  });
  void _showTranscriptDialog(
      BuildContext context, String title, String transcript) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text("$title",
              style:
                  TextStyle(color: secondaryColor, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              maxLines: 2),
          content: SingleChildScrollView(child: Text(transcript)),
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
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: size.height * 0.01),
      child: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: primaryColor,
        ),
        builder: (context, player) {
          return Column(
            children: [
              Container(
                height: size.height * 0.33,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(size.width * 0.027),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(size.width * 0.027),
                        topRight: Radius.circular(size.width * 0.027),
                      ),
                      child: player,
                    ),
                    SizedBox(height: size.height * 0.012),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: size.width * 0.027),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: size.width * 0.038,
                            ),
                          ),
                          SizedBox(height: size.height * 0.005),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: secondaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: secondaryColor.withOpacity(0.2)),
                                ),
                                child: Text(
                                  language,
                                  style: TextStyle(
                                    color: secondaryColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _showTranscriptDialog(
                                      context, title, transcript);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: primaryColor.withOpacity(0.2)),
                                  ),
                                  child: Text(
                                    'View Notes',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              if (!isLastVideo)
                Padding(
                  padding: EdgeInsets.only(top: size.height * 0.014),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 2,
                        width: size.width * 0.2,
                        color: Colors.grey,
                      ),
                      Text(
                        '  OR  ',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: size.width * 0.038,
                        ),
                      ),
                      Container(
                        height: 2,
                        width: size.width * 0.2,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
