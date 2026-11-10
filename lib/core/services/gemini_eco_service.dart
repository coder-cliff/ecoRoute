import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/rules/price_calculator.dart';
import 'ecoroute_bot_conversations.dart';

/// Structured response from the EcoRoute Gemini AI Assistant
class WasteClassificationResult {
  const WasteClassificationResult({
    required this.item,
    required this.category,
    required this.sackType,
    required this.suggestedRateUgx,
    required this.recyclable,
    required this.disposalAdvice,
    required this.safetyWarning,
    required this.isAiGenerated,
  });

  final String item;
  final String category; // 'Organic', 'Recyclable Plastic/Metal', 'Hazardous', 'E-Waste', 'General Household'
  final String sackType; // 'Green Compost Sack', 'Blue Dry Sack', 'Red Hazardous Bin', 'Standard Woven Sack'
  final int suggestedRateUgx;
  final bool recyclable;
  final String disposalAdvice;
  final String? safetyWarning;
  final bool isAiGenerated;
}

/// Zero-cost Google Gemini AI Integration for EcoRoute
/// Uses Google AI Studio's free tier (15 requests/min, zero cost) with intelligent offline heuristics
class GeminiEcoService {
  GeminiEcoService({http.Client? httpClient, SharedPreferences? preferences})
      : _client = httpClient ?? http.Client(),
        _prefs = preferences;

  static const String _kApiKeyPref = 'ecoroute_gemini_api_key_v1';
  final http.Client _client;
  SharedPreferences? _prefs;

  void attachPreferences(SharedPreferences? prefs) {
    _prefs = prefs;
  }

  /// Get configured Gemini API key (from SharedPreferences or environment variable)
  String? getApiKey() {
    return _prefs?.getString(_kApiKeyPref);
  }

  /// Save or clear the user's free Google AI Studio key
  Future<void> setApiKey(String? key) async {
    if (key == null || key.trim().isEmpty) {
      await _prefs?.remove(_kApiKeyPref);
    } else {
      await _prefs?.setString(_kApiKeyPref, key.trim());
    }
  }

  /// Classifies a waste item using Google Gemini, with robust offline heuristics
  Future<WasteClassificationResult> classifyWaste(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return _offlineFallback('Unknown Waste');
    }

    final apiKey = getApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final result = await _callGeminiClassifier(cleanQuery, apiKey);
        if (result != null) return result;
      } catch (e) {
        debugPrint('Gemini classification online notice (using offline rules): $e');
      }
    }

    // High-accuracy offline rules engine for Arua City
    return _offlineFallback(cleanQuery);
  }

  /// Ask ecoRoute Bot general waste collection or casual WhatsApp questions
  Future<String> askEcoAssistant({
    required String question,
    List<Map<String, String>> chatHistory = const [],
    String? userName,
  }) async {
    final cleanQ = question.trim();
    if (cleanQ.isEmpty) {
      return EcoRouteBotConversations.findWhatsAppReply('hello', userName: userName);
    }

    final apiKey = getApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final answer = await _callGeminiChat(cleanQ, apiKey, chatHistory);
        if (answer != null && answer.isNotEmpty) {
          return answer;
        }
      } catch (e) {
        debugPrint('Gemini chat online notice (using smart WhatsApp fallback): $e');
      }
    }

    return EcoRouteBotConversations.findWhatsAppReply(cleanQ, userName: userName);
  }

  /// Generate intelligent dispatch and route summary for municipal supervisors
  Future<String> generateDispatchSummary(List<Map<String, dynamic>> tasks) async {
    if (tasks.isEmpty) {
      return 'No active requests pending in the municipal collection pool.';
    }

    final apiKey = getApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final prompt = '''
You are the AI Operations Supervisor for EcoRoute Municipal Waste Platform in Arua City, Uganda.
Analyze these pending collection tasks and provide a 3-bullet action summary:
- Highest priority zone / bottleneck
- Recommended collection order
- Safety or weather advisory

Tasks data: ${jsonEncode(tasks.take(15).toList())}
''';
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
        );
        final response = await _client.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [{'text': prompt}]
              }
            ],
            'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 350},
          }),
        ).timeout(const Duration(seconds: 6));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
          if (text != null && text.trim().isNotEmpty) {
            return text.trim();
          }
        }
      } catch (_) {}
    }

    // Offline summary generator
    final total = tasks.length;
    final totalSacks = tasks.fold<int>(0, (sum, t) => sum + ((t['sacks'] as num?)?.toInt() ?? 1));
    return '• $total pending collections awaiting assignment ($totalSacks total sacks across Arua City).\n'
           '• Priority Recommendation: Dispatch tricycles to central commercial clusters (Central Market & Oli Division) first to prevent sidewalk accumulation.\n'
           '• Operational Notice: Ensure all tricycles carry digital scale and hazardous waste separation sacks.';
  }

  Future<WasteClassificationResult?> _callGeminiClassifier(String query, String apiKey) async {
    final prompt = '''
You are an expert municipal solid waste classification engine for EcoRoute in Arua City, Uganda.
Classify the following user item: "$query".
Respond STRICTLY with valid JSON matching this schema:
{
  "item": "$query",
  "category": "Organic" | "Recyclable Plastic" | "Recyclable Metal/Glass" | "Hazardous" | "E-Waste" | "General Household",
  "sackType": "Green Compost Sack" | "Blue Dry Sack" | "Yellow Recyclable Sack" | "Red Hazardous Bin" | "Standard Woven Sack",
  "suggestedRateUgx": 1500,
  "recyclable": true | false,
  "disposalAdvice": "one sentence instructions on how to package or store",
  "safetyWarning": "optional warning if sharp, chemical, or biohazard, else null"
}
''';

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final res = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [{'text': prompt}]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'responseMimeType': 'application/json',
          'maxOutputTokens': 300,
        },
      }),
    ).timeout(const Duration(seconds: 5));

    if (res.statusCode == 200) {
      final jsonResponse = jsonDecode(res.body) as Map<String, dynamic>;
      final rawText = jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      if (rawText != null) {
        final parsed = jsonDecode(rawText) as Map<String, dynamic>;
        return WasteClassificationResult(
          item: parsed['item'] as String? ?? query,
          category: parsed['category'] as String? ?? 'General Household',
          sackType: parsed['sackType'] as String? ?? 'Standard Woven Sack',
          suggestedRateUgx: (parsed['suggestedRateUgx'] as num?)?.toInt() ?? CommercialPricing.standardResidentialRate,
          recyclable: parsed['recyclable'] as bool? ?? false,
          disposalAdvice: parsed['disposalAdvice'] as String? ?? 'Place securely in standard sack for rider collection.',
          safetyWarning: parsed['safetyWarning'] as String?,
          isAiGenerated: true,
        );
      }
    }
    return null;
  }

  Future<String?> _callGeminiChat(
    String query,
    String apiKey,
    List<Map<String, String>> history,
  ) async {
    final contents = <Map<String, dynamic>>[];

    // System context - WhatsApp conversational persona
    contents.add({
      'role': 'user',
      'parts': [
        {
          'text': 'You are ecoRoute Bot, a friendly, local WhatsApp assistant for ecoRoute in Arua City, Uganda. '
                  'Reply exactly like a warm, helpful human chatting on WhatsApp: short 1 to 3 sentences, natural emojis, and zero robotic disclaimers. '
                  'Never say "As an AI..." or "According to municipal regulations...". '
                  'Standard residential fee is 2,500 UGX per sack. Commercial fee is 3,000 UGX. '
                  'Emergency dispatch hotline & WhatsApp: +256394880352. '
                  'Be conversational, friendly, and local to Arua.'
        }
      ]
    });
    contents.add({
      'role': 'model',
      'parts': [
        {
          'text': 'Hey! ecoRoute Bot here 😊 Ready to chat WhatsApp-style and help with your compound or shop waste in Arua!'
        }
      ]
    });

    for (final h in history.take(6)) {
      final r = h['role'] == 'user' ? 'user' : 'model';
      final t = h['text'] ?? '';
      if (t.isNotEmpty) {
        contents.add({
          'role': r,
          'parts': [{'text': t}]
        });
      }
    }

    contents.add({
      'role': 'user',
      'parts': [{'text': query}]
    });

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final res = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.4,
          'maxOutputTokens': 400,
        },
      }),
    ).timeout(const Duration(seconds: 6));

    if (res.statusCode == 200) {
      final jsonResponse = jsonDecode(res.body) as Map<String, dynamic>;
      final rawText = jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      return rawText?.trim();
    }
    return null;
  }

  WasteClassificationResult _offlineFallback(String q) {
    final l = q.toLowerCase();

    if (l.contains('plastic') || l.contains('bottle') || l.contains('jerrycan') || l.contains('polythene') || l.contains('kaveera')) {
      return WasteClassificationResult(
        item: q,
        category: 'Recyclable Plastic',
        sackType: 'Yellow Recyclable Sack',
        suggestedRateUgx: 1500,
        recyclable: true,
        disposalAdvice: 'Rinse bottles, compress them to save volume, and keep dry in the yellow sack for collection.',
        safetyWarning: null,
        isAiGenerated: false,
      );
    }

    if (l.contains('food') || l.contains('peel') || l.contains('vegetable') || l.contains('banana') || l.contains('cassava') || l.contains('organic')) {
      return WasteClassificationResult(
        item: q,
        category: 'Organic Compostable',
        sackType: 'Green Compost Sack',
        suggestedRateUgx: 1500,
        recyclable: true,
        disposalAdvice: 'Drain excess water and seal in a breathable green sack for municipal organic compost conversion.',
        safetyWarning: null,
        isAiGenerated: false,
      );
    }

    if (l.contains('battery') || l.contains('chemical') || l.contains('acid') || l.contains('medical') || l.contains('syringe') || l.contains('glass') || l.contains('broken')) {
      return WasteClassificationResult(
        item: q,
        category: 'Hazardous Waste',
        sackType: 'Red Hazardous Container',
        suggestedRateUgx: 3000,
        recyclable: false,
        disposalAdvice: 'Wrap sharp items securely in puncture-proof cardboard. Do not mix with regular domestic waste.',
        safetyWarning: 'CAUTION: Hazardous material. Must be handed directly to an equipped EcoRoute rider.',
        isAiGenerated: false,
      );
    }

    if (l.contains('phone') || l.contains('cable') || l.contains('computer') || l.contains('charger') || l.contains('electronic') || l.contains('tv')) {
      return WasteClassificationResult(
        item: q,
        category: 'E-Waste',
        sackType: 'Blue Dry Sack',
        suggestedRateUgx: 2500,
        recyclable: true,
        disposalAdvice: 'Keep protected from rain and moisture. Hand over for authorized metals and component recovery.',
        safetyWarning: 'Avoid smashing or puncturing lithium battery compartments.',
        isAiGenerated: false,
      );
    }

    return WasteClassificationResult(
      item: q,
      category: 'General Household',
      sackType: 'Standard Woven Sack',
      suggestedRateUgx: 1500,
      recyclable: false,
      disposalAdvice: 'Bag securely and tie the neck of the sack. Book a collection via the Resident Dashboard.',
      safetyWarning: null,
      isAiGenerated: false,
    );
  }

  String _offlineChatFallback(String q) {
    return EcoRouteBotConversations.findWhatsAppReply(q);
  }
}
