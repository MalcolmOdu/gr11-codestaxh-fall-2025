import 'dart:convert';
import 'package:http/http.dart' as http;

/// Calls Gemini AI directly. API key is injected at build time via
/// --dart-define=GEMINI_API_KEY=... and is never stored in source code.
class AIService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static const _requestsPerDay = 1500;
  static const _minRequestInterval = Duration(seconds: 1);

  DateTime? _lastRequestTime;
  final Map<String, List<DateTime>> _userRequests = {};
  final Map<String, String> _tagCache = {};
  final Map<String, String> _explanationCache = {};

  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  Future<List<String>> suggestTags(String code, String language) async {
    final cacheKey = '${language}_${code.hashCode}';
    if (_tagCache.containsKey(cacheKey)) {
      return _tagCache[cacheKey]!.split(',').map((t) => t.trim()).toList();
    }

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
      final tags = response
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .take(5)
          .toList();
      _tagCache[cacheKey] = tags.join(', ');
      return tags;
    } catch (e) {
      return _getFallbackTags(language);
    }
  }

  Future<String> explainCode(String code, String language) async {
    final cacheKey = '${language}_${code.hashCode}';
    if (_explanationCache.containsKey(cacheKey)) {
      return _explanationCache[cacheKey]!;
    }

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
      final explanation = response.trim();
      _explanationCache[cacheKey] = explanation;
      return explanation;
    } catch (e) {
      return _getFallbackExplanation(language);
    }
  }

  Future<String> _callGemini(String prompt) async {
    if (_apiKey.isEmpty) throw Exception('GEMINI_API_KEY not set at build time.');

    final url = Uri.parse('$_apiUrl?key=$_apiKey');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 200},
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text != null) return text.toString();
      throw Exception('Invalid response format from Gemini.');
    } else if (response.statusCode == 429) {
      throw Exception('Rate limit exceeded. Please wait a moment.');
    } else if (response.statusCode == 403) {
      throw Exception('Invalid API key or quota exceeded.');
    } else {
      throw Exception('Gemini API error: ${response.statusCode}');
    }
  }

  Future<void> _enforceRateLimit() async {
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - elapsed);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  bool canMakeRequest(String userId) {
    final today = DateTime.now();
    final requests = _userRequests[userId] ?? [];
    requests.removeWhere((t) => today.difference(t).inHours > 24);
    if (requests.length >= _requestsPerDay) return false;
    requests.add(today);
    _userRequests[userId] = requests;
    return true;
  }

  int getRemainingRequests(String userId) {
    final requests = _userRequests[userId] ?? [];
    final today = DateTime.now();
    final recent = requests.where((t) => today.difference(t).inHours <= 24).length;
    return _requestsPerDay - recent;
  }

  void clearCache() {
    _tagCache.clear();
    _explanationCache.clear();
  }

  Map<String, int> getCacheStats() => {
        'tags_cached': _tagCache.length,
        'explanations_cached': _explanationCache.length,
      };

  String getQuotaInfo(String userId) {
    final remaining = getRemainingRequests(userId);
    final used = _requestsPerDay - remaining;
    final pct = (used / _requestsPerDay * 100).toStringAsFixed(1);
    return 'Used: $used/$_requestsPerDay ($pct%) | Remaining: $remaining';
  }

  List<String> _getFallbackTags(String language) {
    const fallback = {
      'Python': ['python', 'script', 'code'],
      'JavaScript': ['javascript', 'web', 'code'],
      'Dart': ['dart', 'flutter', 'code'],
      'Java': ['java', 'code'],
      'C++': ['cpp', 'code'],
      'TypeScript': ['typescript', 'web', 'code'],
    };
    return fallback[language] ?? [language.toLowerCase(), 'code'];
  }

  String _getFallbackExplanation(String language) =>
      'This is a $language code snippet. AI explanation is temporarily unavailable.';
}
