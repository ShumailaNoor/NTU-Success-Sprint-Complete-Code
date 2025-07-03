import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoProvider extends ChangeNotifier {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Map<String, Map<String, String>> youtubeLinks = {};
  List<YoutubePlayerController> controllers = [];
  String combinedTranscript = '';
  bool isLoading = true;

  Future<void> fetchVideos(String topic) async {
    isLoading = true;
    notifyListeners();

    final videosRef = _db.child("All Topics").child(topic);
    try {
      final event = await videosRef.once();
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        Map<String, Map<String, String>> videoMap = {};
        String fullTranscript = '';

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
            fullTranscript += value["transcript"].toString().trim() + "\n";
          }
        });

        youtubeLinks = videoMap;
        combinedTranscript = fullTranscript;

        // Dispose previous controllers
        for (var c in controllers) {
          c.dispose();
        }
        controllers = [];

        for (var entry in youtubeLinks.entries) {
          final videoId =
              YoutubePlayer.convertUrlToId(entry.value["link_url"]!);
          if (videoId != null) {
            controllers.add(
              YoutubePlayerController(
                initialVideoId: videoId,
                flags: const YoutubePlayerFlags(
                  autoPlay: false,
                  mute: false,
                  enableCaption: false,
                  isLive: false,
                ),
              ),
            );
          }
        }

        isLoading = false;
        notifyListeners();
      } else {
        isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      print("❌ Error fetching videos: $e");
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (var c in controllers) {
      c.dispose();
    }
    super.dispose();
  }
}
