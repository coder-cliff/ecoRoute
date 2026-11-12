import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/layout/adaptive_layout.dart';
import '../../../core/services/gemini_eco_service.dart';
import '../../../core/theme/eco_palette.dart';
import '../../../main.dart';

/// Opens the WhatsApp-style ecoRoute Bot Chat Sheet
void showEcoRouteBotChatSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const EcoRouteBotChatSheet(),
  );
}

/// Backward compatibility alias
void showEcoGeminiAssistantSheet(BuildContext context) =>
    showEcoRouteBotChatSheet(context);

class EcoRouteBotChatSheet extends StatefulWidget {
  const EcoRouteBotChatSheet({super.key});

  @override
  State<EcoRouteBotChatSheet> createState() => _EcoRouteBotChatSheetState();
}

class _EcoRouteBotChatSheetState extends State<EcoRouteBotChatSheet>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _geminiService = GeminiEcoService();

  late final AnimationController _dotsController;

  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'model',
      'text':
          "Hey there! I'm ecoRoute Bot, your 24/7 WhatsApp waste assistant in Arua City.\n\n"
          "Need a quick sack pickup, want to check rates (2,500 UGX home / 3,000 UGX shop), or just saying hello? I'm right here!",
      'time': _formatCurrentTime(),
    }
  ];

  WasteClassificationResult? _lastClassification;
  bool _isProcessing = false;

  static const List<String> _quickPrompts = [
    'Muke! How are you?',
    'Request Sack Pickup',
    'How much per sack?',
    'Are you in Ediofe today?',
    'How do I sort plastics?',
    'Dispatch Hotline',
    'Tell me a joke',
    'Muni University schedule',
  ];

  static String _formatCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    final prefs = EcoRouteState.instance.prefs;
    if (prefs != null) {
      _geminiService.attachPreferences(prefs);
    }
  }

  @override
  void dispose() {
    _dotsController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend(String input) async {
    final query = input.trim();
    if (query.isEmpty || _isProcessing) return;

    final userName = EcoRouteState.instance.userName;
    final timeStr = _formatCurrentTime();

    _textController.clear();
    setState(() {
      _messages.add({
        'role': 'user',
        'text': query,
        'time': timeStr,
      });
      _isProcessing = true;
      _lastClassification = null;
    });

    _scrollToBottom();

    // 1. Check if user wants waste classification for an item
    WasteClassificationResult? classification;
    final lower = query.toLowerCase();
    if (!lower.startsWith('what') &&
        !lower.startsWith('how') &&
        !lower.startsWith('who') &&
        !lower.startsWith('where') &&
        !lower.contains('joke') &&
        !lower.contains('funny') &&
        !lower.contains('schedule') &&
        !lower.contains('hotline') &&
        !lower.contains('phone') &&
        !lower.contains('muke') &&
        !lower.contains('kopi') &&
        !lower.contains('habari') &&
        !lower.contains('oli otya') &&
        !lower.contains('call')) {
      classification = await _geminiService.classifyWaste(query);
    }

    // 2. Chat response from ecoRoute Bot's 400+ WhatsApp engine or online Gemini
    final reply = await _geminiService.askEcoAssistant(
      question: query,
      chatHistory: _messages
          .map((m) => {
                'role': m['role'] as String,
                'text': m['text'] as String,
              })
          .toList(),
      userName: userName.isNotEmpty ? userName : null,
    );

    if (!mounted) return;

    setState(() {
      _lastClassification = classification;
      _messages.add({
        'role': 'model',
        'text': reply,
        'time': _formatCurrentTime(),
      });
      _isProcessing = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _callHotline() {
    Clipboard.setData(const ClipboardData(text: '+256394880352'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hotline +256394880352 copied to clipboard! Opening dialer...'),
        backgroundColor: Color(0xFF008069),
      ),
    );
  }

  void _showApiKeyDialog() {
    final keyCtrl = TextEditingController(text: _geminiService.getApiKey() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF008069), size: 22),
            SizedBox(width: 8),
            Text('Free Google AI Key', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ecoRoute Bot works 100% offline with 400+ local WhatsApp chats. To also enable generative Gemini AI reasoning, you can optionally paste your free API key from Google AI Studio (aistudio.google.com).',
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
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF008069)),
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

    // WhatsApp Colors
    final headerBg = isDark ? const Color(0xFF1F2C34) : const Color(0xFF075E54);
    final chatBg = isDark ? const Color(0xFF0B141A) : const Color(0xFFEFEAE2);
    final userBubbleBg = isDark ? const Color(0xFF005C4B) : const Color(0xFFDCF8C6);
    final botBubbleBg = isDark ? const Color(0xFF1F2C34) : const Color(0xFFFFFFFF);
    final textColor = isDark ? Colors.white : const Color(0xFF111B21);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF667781);
    final inputBarBg = isDark ? const Color(0xFF1F2C34) : const Color(0xFFF0F2F5);
    final hasKey = _geminiService.getApiKey() != null && _geminiService.getApiKey()!.isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: chatBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // WhatsApp Top App Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF00A884),
                      child: const Icon(Icons.eco, color: Colors.white, size: 22),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366),
                        shape: BoxShape.circle,
                        border: Border.all(color: headerBg, width: 2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'ecoRoute Bot',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Satoshi',
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              hasKey ? 'Gemini AI' : '400+ Arua Chats',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF25D366),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'online • WhatsApp Waste Assistant',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Call Hotline +256394880352',
                  icon: const Icon(Icons.phone, color: Colors.white, size: 20),
                  onPressed: _callHotline,
                ),
                IconButton(
                  tooltip: 'Gemini Key Settings',
                  icon: const Icon(Icons.key, color: Colors.white, size: 20),
                  onPressed: _showApiKeyDialog,
                ),
              ],
            ),
          ),

          // Quick Prompts Chips (WhatsApp Quick Replies)
          Container(
            color: isDark ? const Color(0xFF111B21) : const Color(0xFFE8ECEF),
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final prompt = _quickPrompts[i];
                return ActionChip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: isDark ? const Color(0xFF1F2C34) : Colors.white,
                  side: BorderSide(
                    color: isDark ? const Color(0xFF2A3942) : Colors.black12,
                  ),
                  label: Text(
                    prompt,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF008069),
                    ),
                  ),
                  onPressed: () => _handleSend(prompt),
                );
              },
            ),
          ),

          // WhatsApp Chat Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: _messages.length + (_lastClassification != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (_lastClassification != null && index == _messages.length - 1) {
                  return _buildClassificationCard(_lastClassification!, isDark);
                }

                final actualIndex = (_lastClassification != null && index >= _messages.length)
                    ? index - 1
                    : index;
                final msg = _messages[actualIndex];
                final isUser = msg['role'] == 'user';
                final time = (msg['time'] as String?) ?? 'Just now';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.82,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? userBubbleBg : botBubbleBg,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: isUser ? const Radius.circular(12) : const Radius.circular(0),
                        bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['text'] as String? ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 10,
                                color: subtextColor,
                              ),
                            ),
                            if (isUser) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.done_all,
                                size: 14,
                                color: Color(0xFF53BDEB), // WhatsApp blue double tick
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Typing indicator
          if (_isProcessing)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(left: 14, bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: botBubbleBg,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ecoRoute Bot is typing',
                      style: TextStyle(fontSize: 12, color: subtextColor, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(width: 6),
                    AnimatedBuilder(
                      animation: _dotsController,
                      builder: (context, _) {
                        final val = (_dotsController.value * 3).floor() + 1;
                        return Text('.' * val, style: const TextStyle(fontWeight: FontWeight.bold));
                      },
                    ),
                  ],
                ),
              ),
            ),

          // WhatsApp Bottom Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
            decoration: BoxDecoration(
              color: inputBarBg,
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF2A3942) : Colors.black12,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A3942) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sentiment_satisfied_alt_outlined,
                          color: subtextColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            textInputAction: TextInputAction.send,
                            onSubmitted: _handleSend,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Type a message to ecoRoute Bot...',
                              hintStyle: TextStyle(color: subtextColor, fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.attach_file, color: subtextColor, size: 20),
                          tooltip: 'Add Waste Details',
                          onPressed: () => _handleSend('How do I sort organic waste?'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _handleSend(_textController.text),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00A884), // WhatsApp Send Button Green
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3224) : const Color(0xFFE9F5EB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00A884).withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFF00A884), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Waste Identified: ${res.item}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: res.recyclable ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  res.recyclable ? 'Recyclable' : 'General Waste',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: res.recyclable ? Colors.green[800] : Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text(res.sackType, style: const TextStyle(fontSize: 10.5)),
                backgroundColor: isDark ? Colors.black26 : Colors.white,
              ),
              const SizedBox(width: 6),
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text('${res.suggestedRateUgx} UGX/sack', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                backgroundColor: isDark ? Colors.black26 : Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            res.disposalAdvice,
            style: const TextStyle(fontSize: 12),
          ),
          if (res.safetyWarning != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      res.safetyWarning!,
                      style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
