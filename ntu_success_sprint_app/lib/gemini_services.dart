import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _apiKey =
      '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'; // 🔑 Replace with your actual key

  static Future<List<Map<String, dynamic>>> generateMcqs(String input) async {
    print('[GeminiService] Step 1: Preparing prompt...');

    final prompt = '''
You are an AI that generates multiple-choice questions (MCQs).  
Based on the transcript below, generate 5 MCQs. Each question should be formatted exactly like this:

1. [The question text]  
A) [Option A]  
B) [Option B]  
C) [Option C]  
D) [Option D]  
Correct answer: A/B/C/D) [the correct option text]

Do not include any other text or formatting. Ensure that each question follows this exact structure with no extra spaces or newlines.

Transcript:  
$input
''';

    print('[GeminiService] Step 2: Making API call to OpenRouter...');

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://yourappname.com', // optional, can be dummy
          'X-Title': 'NTU Success Sprint', // optional
        },
        body: jsonEncode({
          "model":
              "google/gemini-2.0-flash-001", // You can change the variant here
          "messages": [
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.7
        }),
      );

      print('[GeminiService] Step 3: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final content = decoded['choices'][0]['message']['content'];

        print('[GeminiService] Step 4: Raw response from GPT:');
        print(content);

        final mcqs = _parseMcqs(content);
        print('[GeminiService] Step 5: Parsed MCQs:');
        print(mcqs);
        return mcqs;
      } else {
        print('[GeminiService] ❌ Error: ${response.body}');
        return [];
      }
    } catch (e) {
      print('[GeminiService] ❌ Exception: $e');
      return [];
    }
  }

  static List<Map<String, dynamic>> _parseMcqs(String content) {
    final List<Map<String, dynamic>> mcqs = [];

    content = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final questionBlocks = content.split(RegExp(r'\n(?=\d+\.)'));

    for (final block in questionBlocks) {
      if (block.trim().isEmpty) continue;

      final lines = block.trim().split('\n');
      final questionLine = lines.firstWhere(
        (line) => RegExp(r'^\d+\.').hasMatch(line),
        orElse: () => '',
      );
      final question =
          questionLine.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();

      final List<Map<String, String>> options = [];

      for (final line in lines) {
        final match = RegExp(r'^([A-D])\)\s*(.+)$').firstMatch(line.trim());
        if (match != null) {
          options
              .add({'label': match.group(1)!, 'text': match.group(2)!.trim()});
        }
      }

      final answerLine = lines.firstWhere(
        (line) => line.toLowerCase().contains('correct answer'),
        orElse: () => '',
      );
      String? answerLabel;
      final correctMatch =
          RegExp(r'Correct answer:\s*([A-D])\)').firstMatch(answerLine);
      if (correctMatch != null) {
        answerLabel = correctMatch.group(1);
      }

      if (question.isNotEmpty && options.length == 4 && answerLabel != null) {
        mcqs.add({
          'question': question,
          'options': options,
          'answer': answerLabel, // Just "B", not the full text
        });
      }
    }

    return mcqs;
  }
}
