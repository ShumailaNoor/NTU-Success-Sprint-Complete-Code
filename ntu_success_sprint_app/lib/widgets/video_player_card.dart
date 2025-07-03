import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../constant.dart';

class VideoPlayerCard extends StatelessWidget {
  final Size size;
  final YoutubePlayerController controller;
  final String title;
  final bool isLastVideo;

  const VideoPlayerCard({
    super.key,
    required this.size,
    required this.controller,
    required this.title,
    required this.isLastVideo,
  });

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
                height: size.height * 0.3,
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
                      padding: EdgeInsets.only(left: size.width * 0.055),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: size.width * 0.038,
                        ),
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
