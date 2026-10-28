import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/rider_invite_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/pickup_request.dart';
import '../../../domain/enums/request_status.dart';
import '../../../domain/enums/waste_type.dart';
import 'analytics_breakdown.dart';

class AdminCommandCenter extends StatefulWidget {
  const AdminCommandCenter({
    required this.orders,
    required this.authService,
    required this.onUpdateOrderStatus,
    required this.onOpenEmailClientForRider,
    required this.onCopyRiderInviteLink,
    required this.onShowConfigureEmailGateway,
    required this.onRefreshOrders,
    super.key,
  });

  final List<PickupRequest> orders;
  final AuthService? authService;
  final Future<void> Function(PickupRequest request, RequestStatus status) onUpdateOrderStatus;
  final void Function(Map<String, dynamic> rider) onOpenEmailClientForRider;
  final void Function(Map<String, dynamic> rider) onCopyRiderInviteLink;
  final VoidCallback onShowConfigureEmailGateway;
  final VoidCallback onRefreshOrders;

  @override
  State<AdminCommandCenter> createState() => _AdminCommandCenterState();
}

class _AdminCommandCenterState extends State<AdminCommandCenter> {
  int _activeTab = 0; // 0: Approvals, 1: Fleet & Riders, 2: Resident Directory, 3: Analytics
  final _riderNameCtrl = TextEditingController();
  final _riderEmailCtrl = TextEditingController();
  final _riderPhoneCtrl = TextEditingController();
  bool _invitingRider = false;
  String _residentSearch = '';

  @override
  void dispose() {
    _riderNameCtrl.dispose();
    _riderEmailCtrl.dispose();
    _riderPhoneCtrl.dispose();
    super.dispose();
  }

  int _countStatus(RequestStatus status) =>
      widget.orders.where((o) => o.status == status).length;

  Future<void> _handleInviteRider() async {
    final name = _riderNameCtrl.text.trim();
    final email = _riderEmailCtrl.text.trim();
    final phone = _riderPhoneCtrl.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter rider name and email.')),
      );
      return;
    }

    setState(() => _invitingRider = true);
    try {
      final inviteCode = await widget.authService?.inviteRider(
        email: email,
        fullName: name,
        phone: phone,
      ) ?? 'RIDER-001';

      final inviteLink = '${RiderInviteService.defaultAppUrl}?invite=$inviteCode&email=${Uri.encodeComponent(email)}';

      final emailSent = await RiderInviteService.sendRiderInviteEmail(
        riderEmail: email,
        riderName: name,
        inviteLink: inviteLink,
      );

      _riderNameCtrl.clear();
      _riderEmailCtrl.clear();
      _riderPhoneCtrl.clear();

      if (mounted) {
        if (emailSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Official invitation sent to $email via Google Apps Script.'),
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
        } else {
          // Open direct fallback dialog
          _showInviteLinkDialog(name, email, inviteLink);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inviting rider: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _invitingRider = false);
    }
  }

  void _showInviteLinkDialog(String riderName, String riderEmail, String inviteLink) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.mail_outline_rounded, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Text('Rider Onboarding Dispatch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rider $riderName has been registered. You can dispatch their invitation immediately:',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD3E7D5)),
              ),
              child: SelectableText(
                inviteLink,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: inviteLink));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invite link copied to clipboard!')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Link'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await RiderInviteService.openEmailClient(
                riderEmail: riderEmail,
                riderName: riderName,
                inviteLink: inviteLink,
              );
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Send via Email App'),
          ),
        ],
      ),
    );
  }

  void _copyAuditSummary() {
    final total = widget.orders.length;
    final paid = _countStatus(RequestStatus.paid);
    final totalSacks = widget.orders.fold<int>(0, (sum, o) => sum + o.sackCount);
    final totalKg = totalSacks * 25;
    final totalCo2 = (totalKg * 0.45).toStringAsFixed(1);
    final totalRevenue = widget.orders
        .where((o) => o.status == RequestStatus.paid)
        .fold<int>(0, (sum, o) => sum + o.priceUgx);

    final summary = '''
ECOROUTE ARUA — MUNICIPAL LOGISTICS AUDIT REPORT
Generated: ${DateTime.now().toLocal().toString().split('.').first}
City Jurisdiction: Arua Central & Ayivu Division, Uganda

--- OPERATIONAL KPIS ---
Total Pickups Logged: $total
Verified & Settled: $paid (${total > 0 ? (paid / total * 100).toStringAsFixed(1) : 0}%)
Total Solid Waste Diverted: ~$totalKg kg ($totalSacks sacks)
Estimated CO₂ Avoided: $totalCo2 kg CO₂
Municipal Revenue Settled: ${formatUgx(totalRevenue)}

--- STATUS BREAKDOWN ---
Requested / Open: ${_countStatus(RequestStatus.requested)}
Collected in Transit: ${_countStatus(RequestStatus.collected)}
Awaiting Depot Scale Review: ${_countStatus(RequestStatus.awaitingVerification)}
Paid & Completed: $paid
Cancelled: ${_countStatus(RequestStatus.cancelled)}
''';

    Clipboard.setData(ClipboardData(text: summary));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Audit summary copied to clipboard for reporting!'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }

  Future<void> _makePhoneCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: clean);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final pendingApprovals = widget.orders
        .where((o) => o.status == RequestStatus.awaitingVerification)
        .toList();
    final riders = widget.authService?.getInvitedRiders() ?? [];
    final residents = widget.authService?.getRegisteredResidents() ?? [];

    final totalSettledRevenue = widget.orders
        .where((o) => o.status == RequestStatus.paid)
        .fold<int>(0, (sum, o) => sum + o.priceUgx);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2EAE1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Ribbon
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF2E7D32), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Operations Command Center',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF183B20),
                        ),
                      ),
                      Text(
                        'Arua Municipal Dispatch, Approvals & Fleet Roster',
                        style: TextStyle(fontSize: 11, color: Color(0xFF556958)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_suggest_outlined, size: 20, color: Color(0xFF2E7D32)),
                  tooltip: 'Configure MailApp Gateway URL',
                  onPressed: widget.onShowConfigureEmailGateway,
                ),
              ],
            ),
          ),

          // 4 Executive KPI Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: _buildExecutiveKpi(
                    title: 'Approvals',
                    value: '${pendingApprovals.length}',
                    hint: 'needs review',
                    icon: Icons.fact_check_rounded,
                    color: pendingApprovals.isNotEmpty ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                    badge: pendingApprovals.isNotEmpty ? 'ALERT' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildExecutiveKpi(
                    title: 'Revenue',
                    value: formatUgx(totalSettledRevenue),
                    hint: 'settled',
                    icon: Icons.payments_rounded,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildExecutiveKpi(
                    title: 'Riders',
                    value: '${riders.length}',
                    hint: 'in fleet',
                    icon: Icons.two_wheeler_rounded,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tab Navigation Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _buildSegmentButton(
                  index: 0,
                  label: 'Approvals (${pendingApprovals.length})',
                  icon: Icons.check_box_outlined,
                  highlight: pendingApprovals.isNotEmpty,
                ),
                const SizedBox(width: 6),
                _buildSegmentButton(
                  index: 1,
                  label: 'Fleet & Riders (${riders.length})',
                  icon: Icons.two_wheeler_rounded,
                ),
                const SizedBox(width: 6),
                _buildSegmentButton(
                  index: 2,
                  label: 'Residents (${residents.length})',
                  icon: Icons.people_alt_outlined,
                ),
                const SizedBox(width: 6),
                _buildSegmentButton(
                  index: 3,
                  label: 'Analytics & Audit',
                  icon: Icons.insights_rounded,
                ),
              ],
            ),
          ),

          const Divider(height: 18),

          // Tab Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: switch (_activeTab) {
              0 => _buildApprovalsTab(pendingApprovals),
              1 => _buildFleetTab(riders),
              2 => _buildResidentsTab(residents),
              _ => _buildAnalyticsTab(),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveKpi({
    required String title,
    required String value,
    required String hint,
    required IconData icon,
    required Color color,
    String? badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EAE1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            '$title • $hint',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, color: Color(0xFF647568)),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required int index,
    required String label,
    required IconData icon,
    bool highlight = false,
  }) {
    final isSelected = _activeTab == index;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _activeTab = index);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1B5E20)
              : highlight
                  ? const Color(0xFFFFF3E0)
                  : const Color(0xFFF1F5F2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : highlight
                      ? const Color(0xFFE65100)
                      : const Color(0xFF556958),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : highlight
                        ? const Color(0xFFE65100)
                        : const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalsTab(List<PickupRequest> approvals) {
    if (approvals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(Icons.task_alt_rounded, size: 40, color: Color(0xFF2E7D32)),
            SizedBox(height: 8),
            Text(
              'Approval Queue Clear',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF183B20)),
            ),
            SizedBox(height: 2),
            Text(
              'Completed collections submitted by riders will appear here for depot scale signoff.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF647568)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < approvals.length; i++) ...[
          if (i > 0) const Divider(height: 18),
          _buildApprovalCard(approvals[i]),
        ],
      ],
    );
  }

  Widget _buildApprovalCard(PickupRequest request) {
    final shortId = request.id.length > 8
        ? request.id.substring(request.id.length - 8).toUpperCase()
        : request.id.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFDFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EAE1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#$shortId',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF512DA8)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${request.wasteType.label} • ${request.sackCount} sack(s)',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const Spacer(),
              Text(
                formatUgx(request.priceUgx),
                style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2E7D32)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${request.residentName} (${request.residentPhone}) • ${request.address}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF556958)),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => widget.onUpdateOrderStatus(request, RequestStatus.collected),
                icon: const Icon(Icons.undo_rounded, size: 14),
                label: const Text('Return to Rider', style: TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => widget.onUpdateOrderStatus(request, RequestStatus.paid),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                icon: const Icon(Icons.check_circle_rounded, size: 14),
                label: const Text('Approve & Settle', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFleetTab(List<Map<String, dynamic>> riders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Invite card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FBF8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE0ECE2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Invite Authorized Collection Rider',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1B5E3B)),
              ),
              const SizedBox(height: 2),
              const Text(
                'Riders are sent official onboarding invitations via Google Apps Script MailApp API.',
                style: TextStyle(fontSize: 11, color: Color(0xFF557060)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _riderNameCtrl,
                decoration: InputDecoration(
                  labelText: 'Rider full name',
                  isDense: true,
                  prefixIcon: const Icon(Icons.person_outline, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _riderEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Rider email address',
                  isDense: true,
                  prefixIcon: const Icon(Icons.email_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _riderPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone number (optional)',
                  isDense: true,
                  prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _invitingRider ? null : _handleInviteRider,
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                  icon: _invitingRider
                      ? const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 16),
                  label: Text(_invitingRider ? 'Dispatching...' : 'Send Official Invitation'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        const Text(
          'Active & Invited Rider Roster',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF183B20)),
        ),
        const SizedBox(height: 8),

        if (riders.isEmpty)
          const Text('No riders in fleet yet.', style: TextStyle(fontSize: 12, color: Color(0xFF647568)))
        else
          for (var i = 0; i < riders.length; i++) ...[
            if (i > 0) const Divider(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: const Icon(Icons.two_wheeler_rounded, size: 16, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        riders[i]['fullName'] as String? ?? 'Rider',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      Text(
                        '${riders[i]['email']} • ${riders[i]['phone'] ?? ''}',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF647568)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.mail_outline_rounded, size: 18, color: Color(0xFF2E7D32)),
                  tooltip: 'Send via Email App',
                  onPressed: () => widget.onOpenEmailClientForRider(riders[i]),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF556958)),
                  tooltip: 'Copy onboarding link',
                  onPressed: () => widget.onCopyRiderInviteLink(riders[i]),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                  tooltip: 'Remove rider',
                  onPressed: () async {
                    await widget.authService?.removeRider(riders[i]['email'] as String);
                    widget.onRefreshOrders();
                  },
                ),
              ],
            ),
          ],
      ],
    );
  }

  Widget _buildResidentsTab(List<AppUser> residents) {
    final filtered = residents.where((r) {
      if (_residentSearch.isEmpty) return true;
      final q = _residentSearch.toLowerCase();
      return r.fullName.toLowerCase().contains(q) ||
          r.email.toLowerCase().contains(q) ||
          r.phone.contains(q) ||
          (r.address?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Search residents by name, phone or zone...',
            prefixIcon: const Icon(Icons.search_rounded, size: 18),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onChanged: (v) => setState(() => _residentSearch = v.trim()),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text('No residents match your search.', style: TextStyle(fontSize: 12, color: Color(0xFF647568))),
            ),
          )
        else
          for (var i = 0; i < filtered.length; i++) ...[
            if (i > 0) const Divider(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: Text(
                    filtered[i].fullName.isNotEmpty ? filtered[i].fullName[0].toUpperCase() : 'R',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2E7D32)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(filtered[i].fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      Text('${filtered[i].email} • ${filtered[i].phone}', style: const TextStyle(fontSize: 10, color: Color(0xFF647568))),
                      if (filtered[i].address?.isNotEmpty == true)
                        Text(filtered[i].address!, style: const TextStyle(fontSize: 9, color: Color(0xFF8B9D90))),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => _makePhoneCall(filtered[i].phone),
                  icon: const Icon(Icons.phone_rounded, size: 16),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFE8F5E9),
                    foregroundColor: const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ],
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    final statuses = [
      RequestStatus.requested,
      RequestStatus.collected,
      RequestStatus.awaitingVerification,
      RequestStatus.paid,
      RequestStatus.cancelled,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in statuses)
          AnalyticsRow(
            status: s,
            count: _countStatus(s),
            total: widget.orders.length,
          ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                '${widget.orders.length} total municipal requests logged across Arua.',
                style: const TextStyle(fontSize: 11, color: Color(0xFF647568)),
              ),
            ),
            FilledButton.icon(
              onPressed: _copyAuditSummary,
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
              icon: const Icon(Icons.copy_rounded, size: 14),
              label: const Text('Export Audit', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ],
    );
  }
}
