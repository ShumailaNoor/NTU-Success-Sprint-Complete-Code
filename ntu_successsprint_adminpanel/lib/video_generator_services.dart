ceimport 'dart:convert';
import 'package:http/http.dart' as http;

class VideoGeneratorService {
  static const String _openAiUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String _openAiKey =
      'replace_with_your_key';
  static const String _youtubeApiKey =
      'replace_with_your_key';

  static Future<List<Map<String, String>>> generateForTopic(
      String topic, String course, String languageOption) async {
    // Generate multiple search queries for better results
    final searchQueries =
        await _generateSearchQueries(topic, course, languageOption);

    List<Map<String, String>> allResults = [];

    for (String query in searchQueries) {
      try {
        final results = await _searchYouTubeWithFiltering(
            query, topic, course, languageOption);
        allResults.addAll(results);

        // If we found good results, we can break early
        if (allResults.isNotEmpty) break;
      } catch (e) {
        print("⚠️ Search failed for query: $query - $e");
        continue;
      }
    }

    if (allResults.isEmpty) {
      throw Exception('No relevant videos found for topic: $topic');
    }

    // Return only the best result
    return [allResults.first];
  }

  static Future<List<String>> _generateSearchQueries(
      String topic, String course, String languageOption) async {
    final searchPrompt = '''
You are an educational YouTube search expert.

Generate 3 different search queries to find educational videos for:
Topic: "$topic"
Course: "$course"
Language: "$languageOption"

Requirements:
- Create simple, natural search terms that students would use
- Focus on the core concept, not complex phrases
- Include language preference: $languageOption
- Don't include course codes
- Make queries progressively broader if needed

Return ONLY this JSON format:
{
  "queries": [
    "primary search term + $languageOption + explained",
    "alternative search + $languageOption + tutorial", 
    "broader search + $languageOption + basics"
  ]
}
''';

    final promptResponse = await http.post(
      Uri.parse(_openAiUrl),
      headers: {
        'Authorization': 'Bearer $_openAiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "openai/gpt-4o",
        "messages": [
          {"role": "user", "content": searchPrompt}
        ]
      }),
    );

    if (promptResponse.statusCode != 200) {
      // Fallback to manual query generation
      return _generateFallbackQueries(topic, languageOption);
    }

    try {
      final rawContent =
          jsonDecode(promptResponse.body)['choices'][0]['message']['content'];
      final cleanedContent = rawContent
          .replaceAll(RegExp(r'```json|```'), '')
          .replaceAll(RegExp(r',\s*}'), '}')
          .trim();

      final Map<String, dynamic> result = jsonDecode(cleanedContent);
      return List<String>.from(result['queries'] ?? []);
    } catch (e) {
      print("⚠️ Failed to parse search queries: $e");
      return _generateFallbackQueries(topic, languageOption);
    }
  }

  static List<String> _generateFallbackQueries(
      String topic, String languageOption) {
    return [
      "$topic $languageOption explained",
      "$topic $languageOption tutorial",
      "$topic $languageOption basics"
    ];
  }

  static Future<List<Map<String, String>>> _searchYouTubeWithFiltering(
      String query, String topic, String course, String languageOption) async {
    final uri = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search?part=snippet&q=${Uri.encodeComponent(query)}&maxResults=10&type=video&videoDuration=medium&order=relevance&key=$_youtubeApiKey',
    );

    print("🔎 Searching YouTube for: $query");
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('YouTube API Error: ${response.statusCode}');
    }

    final json = jsonDecode(response.body);
    final items = json['items'];

    if (items == null || items.isEmpty) {
      throw Exception('No videos found for query: $query');
    }

    // Filter and score videos for relevance
    List<Map<String, dynamic>> scoredVideos = [];

    for (var video in items) {
      final title = video['snippet']['title']?.toString() ?? '';
      final description = video['snippet']['description']?.toString() ?? '';
      final videoId = video['id']['videoId']?.toString() ?? '';

      if (videoId.isEmpty) continue;

      // Calculate relevance score
      final relevanceScore = _calculateRelevanceScore(
        title: title,
        description: description,
        topic: topic,
        course: course,
      );

      // Only include videos with decent relevance
      if (relevanceScore > 0.3) {
        scoredVideos.add({
          'video': video,
          'score': relevanceScore,
          'title': title,
          'description': description,
          'videoId': videoId,
        });
      }
    }

    if (scoredVideos.isEmpty) {
      throw Exception('No relevant videos found for: $query');
    }

    // Sort by relevance score (highest first)
    scoredVideos.sort((a, b) => b['score'].compareTo(a['score']));

    // Process the best video
    final bestVideo = scoredVideos.first;
    final link = "https://www.youtube.com/watch?v=${bestVideo['videoId']}";

    print(
        "🎬 Selected video: ${bestVideo['title']} (Score: ${bestVideo['score']})");

    return [
      {
        "title": bestVideo['title'],
        "link": link,
        "language": languageOption,
      }
    ];
  }

  static double _calculateRelevanceScore({
    required String title,
    required String description,
    required String topic,
    required String course,
  }) {
    double score = 0.0;

    final titleLower = title.toLowerCase();
    final descriptionLower = description.toLowerCase();
    final topicLower = topic.toLowerCase();
    final courseLower = course.toLowerCase();

    // Split topic into keywords
    final topicWords =
        topicLower.split(' ').where((word) => word.length > 2).toList();

    // Title relevance (most important)
    for (String word in topicWords) {
      if (titleLower.contains(word)) {
        score += 0.3;
      }
    }

    // Exact topic match in title gets bonus
    if (titleLower.contains(topicLower)) {
      score += 0.4;
    }

    // Description relevance
    for (String word in topicWords) {
      if (descriptionLower.contains(word)) {
        score += 0.1;
      }
    }

    // Course relevance
    if (titleLower.contains(courseLower) ||
        descriptionLower.contains(courseLower)) {
      score += 0.2;
    }

    // Educational keywords bonus
    final educationalKeywords = [
      'tutorial',
      'explained',
      'lecture',
      'lesson',
      'learn',
      'course',
      'education'
    ];
    for (String keyword in educationalKeywords) {
      if (titleLower.contains(keyword) || descriptionLower.contains(keyword)) {
        score += 0.1;
        break; // Only add bonus once
      }
    }

    // Penalize irrelevant content
    final irrelevantKeywords = [
      'music',
      'song',
      'funny',
      'prank',
      'reaction',
      'unboxing',
      'vlog'
    ];
    for (String keyword in irrelevantKeywords) {
      if (titleLower.contains(keyword)) {
        score -= 0.5;
        break;
      }
    }

    return score.clamp(0.0, 1.0);
  }
}
