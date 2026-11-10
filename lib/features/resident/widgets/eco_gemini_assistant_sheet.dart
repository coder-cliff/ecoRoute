import 'package:flutter/material.dart';

import '../../../core/layout/adaptive_layout.dart';
import '../../../core/services/gemini_eco_service.dart';
import '../../../core/theme/eco_palette.dart';
import '../../../main.dart';

/// Modal bottom sheet allowing users to ask EcoBot (Google Gemini AI) about waste sorting & municipal info
void showEcoGeminiAssistantSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const EcoGeminiAssistantSheet(),
  );
}

class EcoGeminiAssistantSheet extends StatefulWidget {
  const EcoGeminiAssistantSheet({super.key});

  @override
  State<EcoGeminiAssistantSheet> createState() => _EcoGeminiAssistantSheetState();
}

class _EcoGeminiAssistantSheetState extends State<EcoGeminiAssistantSheet> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _geminiService = GeminiEcoService();

  final List<Map<String, String>> _messages = [
    {
      'role': 'model',
      'text': 'Hello! I am EcoBot, your zero-cost AI waste sorting assistant powered by Google Gemini. '
              'Type any waste item or question about Arua City municipal collection below to get instant guidance.',
    }
  ];

  WasteClassificationResult? _lastClassification;
  bool _isProcessing = false;

  static const List<String> _quickPrompts = [
    'Old rechargeable battery',
    'Plastic water bottles',
    'Food scraps & banana peels',
    'Collection fees in Arua',
    'Municipal hotline',
  ];

  @override
  void initState() {
    super.initState();
    final prefs = EcoRouteState.instance.prefs;
    if (prefs != null) {
      _geminiService.attachPreferences(prefs);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend(String input) async {
    final query = input.trim();
    if (query.isEmpty || _isProcessing) return;

    _textController.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': query});
      _isProcessing = true;
      _lastClassification = null;
    });

    _scrollToBottom();

    // 1. Run waste classification if it looks like an item
    WasteClassificationResult? classification;
    if (!query.toLowerCase().startsWith('what') &&
        !query.toLowerCase().startsWith('how') &&
        !query.toLowerCase().startsWith('who') &&
        !query.toLowerCase().startsWith('where') &&
        !query.toLowerCase().contains('schedule') &&
        !query.toLowerCase().contains('hotline') &&
        !query.toLowerCase().contains('phone') &&
        !query.toLowerCase().contains('call')) {
      classification = await _geminiService.classifyWaste(query);
    }

    // 2. Run chat assistant
    final reply = await _geminiService.askEcoAssistant(
      question: query,
      chatHistory: _messages,
    );

    if (!mounted) return;

    setState(() {
      _lastClassification = classification;
      _messages.add({'role': 'model', 'text': reply});
      _isProcessing = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showApiKeyDialog() {
    final keyCtrl = TextEditingController(text: _geminiService.getApiKey() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: EcoPalette.primaryForest, size: 22),
            SizedBox(width: 8),
            Text('Free Google AI Key', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'EcoRoute operates with 100% zero costs. To enable full online Gemini LLM reasoning, paste your free API key from Google AI Studio (aistudio.google.com).',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: keyCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Google AI Studio Key',
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _geminiService.setApiKey(null);
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Clear Key'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: EcoPalette.primaryForest),
            onPressed: () async {
              await _geminiService.setApiKey(keyCtrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gemini API key saved.')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = AntigravityTheme.isDark(context);
    final cardBg = AntigravityTheme.card(context);
    final textColor = AntigravityTheme.textPrimary(context);
    final hasKey = _geminiService.getApiKey() != null && _geminiService.getApiKey()!.isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: EcoPalette.primaryForest.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: EcoPalette.primaryForest,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'EcoBot AI Assistant',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: hasKey ? Colors.green.withOpacity(0.15) : Colors.blue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              hasKey ? 'Gemini 1.5' : 'Zero-Cost Rules',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: hasKey ? Colors.green[700] : Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Smart waste classification & Arua municipal guide',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Google AI Key Settings',
                  icon: const Icon(Icons.key, size: 20),
                  onPressed: _showApiKeyDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Quick Prompts Chips
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final prompt = _quickPrompts[i];
                return ActionChip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: EcoPalette.primaryForest.withOpacity(0.08),
                  side: BorderSide(color: EcoPalette.primaryForest.withOpacity(0.2)),
                  label: Text(
                    prompt,
                    style: const TextStyle(fontSize: 11, color: EcoPalette.primaryForest, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => _handleSend(prompt),
                );
              },
            ),
          ),

          // Chat message list & classification card
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_lastClassification != null ? 1 : 0),
              itemBuilder: (context, index) {
                // Render Classification Card if available
                if (_lastClassification != null && index == _messages.length - 1) {
                  return _buildClassificationCard(_lastClassification!, isDark);
                }

                final actualIndex = (_lastClassification != null && index >= _messages.length)
                    ? index - 1
                    : index;
                final msg = _messages[actualIndex];
                final isUser = msg['role'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? EcoPalette.primaryForest
                          : (isDark ? const Color(0xFF24362A) : const Color(0xFFEFF5F0)),
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isUser ? const Radius.circular(4) : null,
                        bottomLeft: !isUser ? const Radius.circular(4) : null,
                      ),
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        color: isUser ? Colors.white : textColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isProcessing) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: EcoPalette.primaryForest),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'EcoBot is analyzing waste properties...',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],

          // Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _handleSend,
                    decoration: InputDecoration(
                      hintText: 'Ask EcoBot or type an item (e.g. plastic bottles)...',
                      hintStyle: const TextStyle(fontSize: 12.5),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E2D22) : const Color(0xFFF2F6F3),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: EcoPalette.primaryForest,
                  ),
                  icon: const Icon(Icons.send, size: 18, color: Colors.white),
                  onPressed: () => _handleSend(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassificationCard(WasteClassificationResult res, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3224) : const Color(0xFFE9F5EB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EcoPalette.primaryForest.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: EcoPalette.primaryForest, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Item Identified: ${res.item}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: res.recyclable ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  res.recyclable ? 'RECYCLABLE' : 'NON-RECYCLABLE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: res.recyclable ? Colors.green[800] : Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _badge(Icons.category, 'Category', res.category),
              _badge(Icons.shopping_bag, 'Sack', res.sackType),
              _badge(Icons.payments, 'Tariff', '${res.suggestedRateUgx} UGX/sack'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            res.disposalAdvice,
            style: const TextStyle(fontSize: 12, height: 1.3),
          ),
          if (res.safetyWarning != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber, color: Colors.redAccent, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    res.safetyWarning!,
                    style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String title, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$title: ',
          style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
