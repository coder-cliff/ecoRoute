import 'package:flutter/material.dart';
import '../../../core/services/email_notification_service.dart';
import '../../../main.dart';

/// Screen for Municipal Admins to review and resolve challenges,
/// inquiries, and feedback submitted by residents and field riders.
class AdminFeedbackView extends StatefulWidget {
  const AdminFeedbackView({super.key});

  @override
  State<AdminFeedbackView> createState() => _AdminFeedbackViewState();
}

class _AdminFeedbackViewState extends State<AdminFeedbackView> {
  String _filter = 'All'; // 'All', 'Pending', 'Resolved', 'Rider', 'Resident'

  @override
  Widget build(BuildContext context) {
    final state = EcoRouteState.instance;
    final isDark = state.isDarkMode;
    final theme = Theme.of(context);

    final tickets = state.residentFeedbackList.where((t) {
      if (_filter == 'Pending') return t['status'] != 'Resolved';
      if (_filter == 'Resolved') return t['status'] == 'Resolved';
      if (_filter == 'Rider') return t['authorRole'] == 'Rider';
      if (_filter == 'Resident') return t['authorRole'] == 'Resident';
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Client & Rider Feedback Hub',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Address community inquiries, route inaccessibility challenges, and operational disputes.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mark_chat_unread_outlined, size: 16, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 6),
                    Text(
                      '${state.residentFeedbackList.where((t) => t['status'] != 'Resolved').length} Pending Challenges',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filter Chips
          Wrap(
            spacing: 8,
            children: ['All', 'Pending', 'Resolved', 'Rider', 'Resident'].map((f) {
              final isSel = _filter == f;
              return ChoiceChip(
                label: Text(f),
                selected: isSel,
                selectedColor: const Color(0xFF2E7D32),
                labelStyle: TextStyle(
                  color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12.5,
                ),
                onSelected: (val) {
                  if (val) setState(() => _filter = f);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Feedback List or Empty State
          if (tickets.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No feedback or challenge reports matching "$_filter".',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (ctx, idx) {
                final ticket = tickets[idx];
                final id = ticket['id'] as String? ?? 'FDBK';
                final author = ticket['authorName'] as String? ?? 'User';
                final role = ticket['authorRole'] as String? ?? 'Resident';
                final category = ticket['category'] as String? ?? 'General';
                final subject = ticket['subject'] as String? ?? '';
                final message = ticket['message'] as String? ?? '';
                final contact = ticket['contact'] as String? ?? '';
                final status = ticket['status'] as String? ?? 'Pending';
                final reply = ticket['adminReply'] as String?;
                final isResolved = status == 'Resolved';

                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: ID, Role Badge, Status Badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: role == 'Rider'
                                  ? const Color(0xFFF59E0B).withOpacity(0.15)
                                  : const Color(0xFF3B82F6).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: role == 'Rider' ? const Color(0xFFD97706) : const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            id,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isResolved
                                  ? const Color(0xFF22C55E).withOpacity(0.15)
                                  : const Color(0xFFEF4444).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isResolved ? Icons.check_circle : Icons.error_outline,
                                  size: 13,
                                  color: isResolved ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: isResolved ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Category & Subject
                      Text(
                        subject,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Category: $category • By $author (${contact.isNotEmpty ? contact : "No phone provided"})',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Message Body
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          message,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                          ),
                        ),
                      ),

                      // Admin Reply Box (if resolved)
                      if (isResolved && reply != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.shield_outlined, size: 14, color: Color(0xFF2E7D32)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Dispatch HQ Resolution:',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reply,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark ? Colors.white : const Color(0xFF1B5E20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Action Button (if pending)
                      if (!isResolved) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            icon: const Icon(Icons.reply, size: 16),
                            label: const Text('Resolve & Respond', style: TextStyle(fontSize: 12.5)),
                            onPressed: () => _showResolveDialog(context, ticket),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showResolveDialog(BuildContext context, Map<String, dynamic> ticket) {
    final replyCtrl = TextEditingController();
    final id = ticket['id'] as String;
    final author = ticket['authorName'] as String? ?? 'User';
    final contact = ticket['contact'] as String? ?? '';
    final category = ticket['category'] as String? ?? 'General';
    final originalMessage = ticket['message'] as String? ?? '';

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Resolve Challenge $id'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Responding to $author ($category):',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                '"$originalMessage"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: replyCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Resolution / Dispatch Action Taken',
                  hintText: 'e.g. Rerouted Tricycle TRIC-04 via Onduparaka bypass. Issue cleared.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Mark Resolved & Notify'),
              onPressed: () {
                final reply = replyCtrl.text.trim();
                if (reply.isEmpty) return;

                EcoRouteState.instance.resolveFeedback(id, reply);

                // Dispatch resolution email if contact has @
                if (contact.contains('@')) {
                  final draft = EmailNotificationService.draftFeedbackResolution(
                    recipientName: author,
                    ticketId: id,
                    category: category,
                    userOriginalMessage: originalMessage,
                    adminReply: reply,
                  );
                  EmailNotificationService.sendEmail(
                    toEmail: contact,
                    subject: draft['subject']!,
                    body: draft['body']!,
                    htmlBody: draft['htmlBody'],
                  );
                }

                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Challenge $id resolved successfully.'),
                    backgroundColor: const Color(0xFF2E7D32),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
