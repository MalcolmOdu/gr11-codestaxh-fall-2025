import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'AIzaSyDvQXOR2OeQiIoRpeVOO0NcP70YwEbuuQ8');
  static const String _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  DateTime? _lastRequestTime;
  static const _minRequestInterval = Duration(seconds: 1);
  static const _requestsPerDay = 1500;

  final Map<String, List<DateTime>> _userRequests = {};


  // Cache responses to save quota (same input = same output)
  final Map<String, String> _tagCache = {};
  final Map<String, String> _explanationCache = {};


  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // ========== PUBLIC METHODS ==========

  // Generate tags for code snippet
  Future<List<String>> suggestTags(String code, String language) async {
    final cacheKey = '${language}_${code.hashCode}';

    // Check cache first
    if (_tagCache.containsKey(cacheKey)) {
      print('Using cached tags');
      return _tagCache[cacheKey]!.split(',').map((t) => t.trim()).toList();
    }

    // Rate limit check
    await _enforceRateLimit();

    final prompt = '''
Analyze this $language code and suggest 3-5 relevant tags for categorization.

Code:
$code

Return ONLY a comma-separated list of tags. No explanation, no formatting, just tags.
Example: authentication, API, REST, security
''';

    try {
      final response = await _callGemini(prompt);

      // Parse response
      final tags = response
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .take(5)
          .toList();

      // Cache result
      _tagCache[cacheKey] = tags.join(', ');

      print('AI generated ${tags.length} tags');
      return tags;
    } catch (e) {
      print('Tag generation failed: $e');
      // Fallback tags based on language
      return _getFallbackTags(language);
    }
  }

  // Generate plain-English explanation of code
  Future<String> explainCode(String code, String language) async {
    final cacheKey = '${language}_${code.hashCode}';

    // Check cache first
    if (_explanationCache.containsKey(cacheKey)) {
      print('Using cached description');
      return _explanationCache[cacheKey]!;
    }

    // Rate limit check
    await _enforceRateLimit();

    final prompt = '''
Explain what this $language code does in 2-3 clear sentences.
Use simple language that a beginner can understand. Focus on WHAT the code does, not HOW it works.

Code:
$code

Provide a concise explanation (2-3 sentences maximum):
''';

    try {
      final response = await _callGemini(prompt);

      // Cache result
      _explanationCache[cacheKey] = response.trim();

      print('AI generated description');
      return response.trim();
    } catch (e) {
      print('Description generation failed: $e');
      return _getFallbackExplanation(language);
    }
  }

  // Gemini API call
  Future<String> _callGemini(String prompt) async {

    // Gemini API uses query parameter for key
    final url = Uri.parse('$_apiUrl?key=$_apiKey');

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3, // Low temperature for consistent results
        'maxOutputTokens': 200,
      }
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Parse Gemini response format
      if (data['candidates'] != null && data['candidates'].isNotEmpty) {
        final content = data['candidates'][0]['content'];
        if (content != null && content['parts'] != null && content['parts'].isNotEmpty) {
          return content['parts'][0]['text'].toString();
        }
      }

      throw Exception('Invalid response format from Gemini');

    } else if (response.statusCode == 429) {
      throw Exception('Rate limit exceeded (60 requests/minute). Please wait a moment.');
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      throw Exception('Invalid request: ${error['error']['message'] ?? 'Unknown error'}');
    } else if (response.statusCode == 403) {
      throw Exception('Invalid API key or quota exceeded');
    } else {
      throw Exception('API error: ${response.statusCode}');
    }
  }

  //rate limiting (prevent spam)
  Future<void> _enforceRateLimit() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minRequestInterval) {
        final waitTime = _minRequestInterval - timeSinceLastRequest;
        print('Rate limit: waiting ${waitTime.inMilliseconds}ms');
        await Future.delayed(waitTime);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  // Check daily limit for user
  bool canMakeRequest(String userId) {
    final today = DateTime.now();
    final requests = _userRequests[userId] ?? [];

    // Remove requests older than 24 hours
    requests.removeWhere((time) => today.difference(time).inHours > 24);

    if (requests.length >= _requestsPerDay) {
      print('Daily limit reached ($_requestsPerDay requests)');
      return false;
    }

    requests.add(today);
    _userRequests[userId] = requests;
    return true;
  }

  /// Get remaining AI requests for user
  int getRemainingRequests(String userId) {
    final requests = _userRequests[userId] ?? [];
    final today = DateTime.now();

    // Count requests in last 24 hours
    final recentRequests = requests.where(
            (time) => today.difference(time).inHours <= 24
    ).length;

    return _requestsPerDay - recentRequests;
  }

  //Fallback tags when AI fails
  List<String> _getFallbackTags(String language) {
    final fallbackMap = {
      'Python': ['python', 'script', 'code'],
      'JavaScript': ['javascript', 'web', 'code'],
      'Dart': ['dart', 'flutter', 'code'],
      'Java': ['java', 'code'],
      'C++': ['cpp', 'code'],
      'TypeScript': ['typescript', 'web', 'code'],
    };
    return fallbackMap[language] ?? [language.toLowerCase(), 'code'];
  }

  //Fallback explanation when AI fails
  String _getFallbackExplanation(String language) {
    return 'This is a $language code snippet. AI explanation is temporarily unavailable.';
  }

  // for memory management
  void clearCache() {
    _tagCache.clear();
    _explanationCache.clear();
    print('AI cache cleared');
  }

  Map<String, int> getCacheStats() {
    return {
      'tags_cached': _tagCache.length,
      'explanations_cached': _explanationCache.length,
    };
  }


  String getQuotaInfo(String userId) {
    final remaining = getRemainingRequests(userId);
    final used = _requestsPerDay - remaining;
    final percentage = (used / _requestsPerDay * 100).toStringAsFixed(1);

    return 'Used: $used/$_requestsPerDay ($percentage%) | Remaining: $remaining';
  }
}