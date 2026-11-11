import 'package:flutter/material.dart';
import '../../main.dart';

/// Interactive modal allowing residents and field riders to submit
/// feedbacks, challenges, and inquiries directly to municipal administrators.
Future<void> showFeedbackSubmissionDialog(
  BuildContext context, {
  bool isRider = false,
}) async {
  final state = EcoRouteState.instance;
  final isDark = state.isDarkMode;

  final residentCategories = [
    'Missed Waste Collection',
    'Service Quality / Handling',
    'Tariff & Sack Pricing Inquiry',
    'App / Technical Issue',
    'Waste Sorting & Recycling Guidance',
    'Illegal Dumping Report',
    'General Community Feedback',
  ];

  final riderCategories = [
    'Road / Route Inaccessible',
    'Tricycle / Mechanical Breakdown',
    'Depot Weighing / Scale Delay',
    'Resident Pickup Dispute',
    'Payout & Cash In Pouch Challenge',
    'Protective Gear / Equipment Request',
    'Other Operational Challenge',
  ];

  final categories = isRider ? riderCategories : residentCategories;
  String selectedCategory = categories.first;

  final subjectCtrl = TextEditingController();
  final messageCtrl = TextEditingController();
  final contactCtrl = TextEditingController(
    text: state.userPhone.isNotEmpty
        ? state.userPhone
        : (state.userEmail.isNotEmpty ? state.userEmail : ''),
  );

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
          final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

          return AlertDialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.feedback_outlined, color: Color(0xFF2E7D32), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isRider ? 'Report Field Challenge' : 'Submit Feedback & Report Issue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your message will be sent directly to Arua City Council Municipal Dispatch HQ.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        dropdownColor: dialogBg,
                        items: categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat, style: TextStyle(fontSize: 13, color: textColor)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedCategory = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Subject
                  TextField(
                    controller: subjectCtrl,
                    style: TextStyle(color: textColor, fontSize: 13.5),
                    decoration: InputDecoration(
                      labelText: 'Subject / Title',
                      hintText: isRider ? 'e.g. Ediofe Road blocked by construction' : 'e.g. Missed Friday collection',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Message Details
                  TextField(
                    controller: messageCtrl,
                    maxLines: 4,
                    style: TextStyle(color: textColor, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Detailed Description',
                      hintText: 'Please provide full details so dispatch can resolve this promptly...',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Contact
                  TextField(
                    controller: contactCtrl,
                    style: TextStyle(color: textColor, fontSize: 13.5),
                    decoration: InputDecoration(
                      labelText: 'Contact Phone / Email',
                      hintText: '+256 700 000000',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Send to Dispatch'),
                onPressed: () {
                  final subject = subjectCtrl.text.trim();
                  final message = messageCtrl.text.trim();
                  if (message.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please describe your challenge before sending.')),
                    );
                    return;
                  }

                  state.submitFeedback(
                    authorName: state.userName.isNotEmpty
                        ? state.userName
                        : (isRider ? 'Field Rider' : 'Resident'),
                    authorRole: isRider ? 'Rider' : 'Resident',
                    contact: contactCtrl.text.trim(),
                    category: selectedCategory,
                    subject: subject.isNotEmpty ? subject : selectedCategory,
                    message: message,
                  );

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Feedback received! Municipal dispatch will address your challenge promptly.',
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Color(0xFF2E7D32),
                      duration: Duration(seconds: 4),
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    },
  );
}
