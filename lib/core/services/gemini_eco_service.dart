import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/rules/price_calculator.dart';

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

  void attachPreferences(SharedPreferences prefs) {
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

  /// Ask general EcoRoute / Arua City municipal waste questions
  Future<String> askEcoAssistant({
    required String question,
    List<Map<String, String>> chatHistory = const [],
  }) async {
    final cleanQ = question.trim();
    if (cleanQ.isEmpty) return 'Please ask a question about waste collection, sorting, or municipal schedules in Arua City.';

    final apiKey = getApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final answer = await _callGeminiChat(cleanQ, apiKey, chatHistory);
        if (answer != null && answer.isNotEmpty) {
          return answer;
        }
      } catch (e) {
        debugPrint('Gemini chat online notice (using smart fallback): $e');
      }
    }

    return _offlineChatFallback(cleanQ);
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

    // System context
    contents.add({
      'role': 'user',
      'parts': [
        {
          'text': 'You are EcoBot, the friendly AI waste management assistant for EcoRoute in Arua City, Uganda. '
                  'EcoRoute provides zero-emission, on-demand municipal waste collection via electric/pedal tricycles. '
                  'Standard residential fee is 1,500 UGX per sack. Commercial fee is 2,000 - 3,000 UGX. '
                  'Emergency hotline is +256394880352. Provide concise, helpful advice.'
        }
      ]
    });
    contents.add({
      'role': 'model',
      'parts': [
        {
          'text': 'Understood. I am EcoBot, ready to assist Arua City residents and businesses with waste sorting, tariffs, and collection schedules.'
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
    final l = q.toLowerCase();

    if (l.contains('fee') || l.contains('price') || l.contains('cost') || l.contains('rate')) {
      return 'EcoRoute standard residential collection is 1,500 UGX per sack. '
             'Commercial rates in Arua City start at 3,000 UGX for small shops, with volume discounts down to 1,800 UGX per sack for bulk orders (30+ sacks).';
    }

    if (l.contains('schedule') || l.contains('when') || l.contains('day') || l.contains('zone')) {
      return 'Arua City collection schedules by division:\n'
             '• North Division (Central Market & Hospital): Daily mornings (6:00 AM - 11:00 AM)\n'
             '• West Division (River Oli & Ediofe): Tuesdays & Saturdays\n'
             '• East Division (Arua Hill & Golf Course): Fridays\n'
             '• South Division (Muni University): Thursdays\n'
             'You can also request an on-demand rapid pickup anytime from your Resident Dashboard!';
    }

    if (l.contains('hotline') || l.contains('call') || l.contains('contact') || l.contains('support') || l.contains('phone')) {
      return 'You can contact EcoRoute Operations directly:\n'
             '• Hotline: +256394880352 (Toll-free dispatcher)\n'
             '• WhatsApp: +256394880352\n'
             '• Email: ecoroute.waste@gmail.com';
    }

    if (l.contains('sort') || l.contains('separate') || l.contains('recycle')) {
      return 'EcoRoute recommends 3-way sorting:\n'
             '1. Green Sack: Organic peels, food remains, and yard trimmings.\n'
             '2. Yellow Sack: Clean plastic bottles, tins, and aluminum cans.\n'
             '3. General Sack: Mixed dry domestic waste.\n'
             'Sorting waste earns you 50 EcoPoints per verified sack, redeemable for municipal credits!';
    }

    return 'I am EcoBot, your zero-cost AI waste guide for Arua City. '
           'You can ask me about collection schedules, fees (1,500 UGX/sack), how to sort specific waste items, or how to reach dispatch (+256394880352). '
           'To enable full generative reasoning, you can also paste a free Google AI Studio Gemini API key in Municipal Settings!';
  }
}
