import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/eco_palette.dart';
import '../auth/splash_screen.dart';
import 'widgets/eco_gemini_assistant_sheet.dart';

/// 05_RESIDENT_SUPPORT: Support Center with FAQ search, help cards, & dispatch dialer
class SupportScreen extends StatefulWidget {
  final bool embedded;

  const SupportScreen({super.key, this.embedded = false});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<Map<String, String>> _allFaqs = [
    {
      'question': 'How to prepare waste?',
      'answer':
          'Please tie your bags securely and separate dry recyclables (plastics, cardboard, metals) from organic food waste. Place sacks at your gate or agreed compound landmark 15 minutes before your scheduled collection window.',
    },
    {
      'question': 'Accepted materials?',
      'answer':
          'EcoRoute collects household waste, paper & cardboard, commercial packaging, recyclable plastics (PET, HDPE), and scrap metals. We do not accept medical hazardous waste or construction demolition debris.',
    },
    {
      'question': 'Service hours?',
      'answer':
          'Our Arua tricycle collection fleet operates Monday through Saturday from 6:30 AM to 6:00 PM. Sunday instant pickups are available for commercial B2B subscribers.',
    },
    {
      'question': 'Pricing & Payment terms?',
      'answer':
          'Standard household sacks are 2,500 UGX each. Commercial bulk rates start at 5,000 UGX per heavy sack. Payments can be settled via cash upon pickup or instant MTN / Airtel Mobile Money.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch phone dialer for $phoneNumber'),
          backgroundColor: EcoPalette.accentTerracotta,
        ),
      );
    }
  }

  void _openChatWithDispatch() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.chat_bubble_outline_rounded, color: EcoPalette.primaryDark),
            SizedBox(width: 10),
            Text(
              'Arua Dispatch Chat',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: EcoPalette.primaryDark,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dispatch Officer Online (Arua Fleet HQ)',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: EcoPalette.onlineGreen,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Arua City dispatch officers are actively monitoring collections. For instant dispatch updates, contact our operational hotline.',
              style: TextStyle(fontFamily: 'Satoshi', fontSize: 13.5, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: EcoPalette.primaryDark)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _makeCall('+256701234567');
            },
            style: FilledButton.styleFrom(backgroundColor: EcoPalette.buttonDark),
            child: const Text('Call Dispatcher'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _searchQuery.isEmpty
        ? _allFaqs
        : _allFaqs.where((f) {
            final q = _searchQuery.toLowerCase();
            return f['question']!.toLowerCase().contains(q) ||
                f['answer']!.toLowerCase().contains(q);
          }).toList();

    final bodyContent = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Screen Title
            const Text(
              'Support Center',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: EcoPalette.primaryDark,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: EcoPalette.cardBorder),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 14.5,
                  color: EcoPalette.primaryDark,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search FAQs or topics...',
                  hintStyle: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 14.5,
                    color: Color(0xFF8A9B8F),
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF8A9B8F)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Help Cards
            const Text(
              'Quick Help Cards',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: EcoPalette.secondaryDark,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickHelpCard(
                    title: 'Missed Pickup',
                    subtitle: 'Report delay',
                    icon: Icons.local_shipping_outlined,
                    onTap: _openChatWithDispatch,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickHelpCard(
                    title: 'Change Booking',
                    subtitle: 'Reschedule',
                    icon: Icons.edit_calendar_outlined,
                    onTap: _openChatWithDispatch,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildQuickHelpCard(
              title: 'Ask EcoBot AI',
              subtitle: 'Instant waste sorting & municipal guide (Powered by Google Gemini)',
              icon: Icons.auto_awesome,
              onTap: () => showEcoGeminiAssistantSheet(context),
            ),
            const SizedBox(height: 12),
            _buildQuickHelpCard(
              title: 'Payment Issue',
              subtitle: 'MoMo & Cash dispute resolutions',
              icon: Icons.payment_rounded,
              onTap: _openChatWithDispatch,
            ),
            const SizedBox(height: 26),

            // Direct Contact Section
            const Text(
              'Direct Contact',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: EcoPalette.secondaryDark,
              ),
            ),
            const SizedBox(height: 12),

            // Chat with Dispatch Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                key: const ValueKey('support_chat_dispatch_btn'),
                onPressed: _openChatWithDispatch,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text(
                  'Chat with Dispatch',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: EcoPalette.buttonDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Call Arua Fleet Ops Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                key: const ValueKey('support_call_ops_btn'),
                onPressed: () => _makeCall('+256701234567'),
                icon: const Icon(
                  Icons.phone_in_talk_rounded,
                  size: 18,
                  color: EcoPalette.accentTerracotta,
                ),
                label: const Text(
                  'Call Arua Fleet Ops',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: EcoPalette.accentTerracotta,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: EcoPalette.accentTerracotta,
                    width: 1.4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // General FAQs Section
            const Text(
              'General FAQs',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: EcoPalette.secondaryDark,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EcoPalette.cardBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredFaqs.length,
                  separatorBuilder: (_, index) => const Divider(height: 1, color: Color(0xFFE8ECE7)),
                  itemBuilder: (context, i) {
                    final item = filteredFaqs[i];
                    return Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text(
                          item['question']!,
                          style: const TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: EcoPalette.primaryDark,
                          ),
                        ),
                        iconColor: EcoPalette.primaryDark,
                        collapsedIconColor: EcoPalette.secondaryDark,
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        children: [
                          Text(
                            item['answer']!,
                            style: const TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 13,
                              color: Color(0xFF4A5F52),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );

    if (widget.embedded) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: EcoPalette.surface,
      appBar: AppBar(
        backgroundColor: EcoPalette.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Row(
          children: [
            EcoRouteLeafLogo(size: 26, color: EcoPalette.primaryDark),
            SizedBox(width: 8),
            Text(
              'EcoRoute',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: EcoPalette.primaryDark,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: EcoPalette.primaryDark),
            onPressed: () {},
          ),
        ],
      ),
      body: bodyContent,
    );
  }

  Widget _buildQuickHelpCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EcoPalette.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: EcoPalette.chipBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: EcoPalette.accentTerracotta, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: EcoPalette.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 11.5,
                        color: Color(0xFF6B8073),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
