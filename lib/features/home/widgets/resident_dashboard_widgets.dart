import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/pickup_request.dart';
import '../../../domain/enums/request_status.dart';
import '../../../domain/enums/role.dart';
import '../../../domain/enums/waste_type.dart';

/// Personalized greeting section for residents showing time-of-day greeting,
/// user profile pill, and quick eco-status in flat, borderless Rich Jade style.
class ResidentHeroGreeting extends StatelessWidget {
  const ResidentHeroGreeting({
    required this.user,
    required this.activeRequestsCount,
    this.onTapProfile,
    super.key,
  });

  final AppUser? user;
  final int activeRequestsCount;
  final VoidCallback? onTapProfile;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _displayName {
    if (user == null || user!.fullName.isEmpty) return 'Resident';
    final parts = user!.fullName.trim().split(RegExp(r'\s+'));
    return parts.first;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: Greeting on left, thin outlined badge on right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                '$_greeting, $_displayName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D2618),
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onTapProfile,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF0D2618), width: 1),
                ),
                child: Text(
                  user?.role == AppRole.admin
                      ? 'Admin'
                      : user?.role == AppRole.rider
                          ? 'Rider'
                          : 'Resident',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D2618),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        // Middle row: "Arua City • On-Demand Tricycle" followed by inline 9x9 green circle
        Row(
          children: [
            const Flexible(
              child: Text(
                'Arua City • On-Demand Tricycle',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A3A28),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Bottom row: Flat inline lightning bolt icon + active requests text with no background pill
        Row(
          children: [
            const Icon(Icons.bolt_rounded, size: 18, color: Color(0xFF0D2618)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                activeRequestsCount > 0
                    ? '$activeRequestsCount collection request${activeRequestsCount > 1 ? 's' : ''} currently in progress'
                    : 'Instant waste collection ready • Ready for dispatch',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0D2618),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Active pickup tracking card shown prominently in flat, borderless Terracotta accent style.
class ActivePickupTrackerCard extends StatelessWidget {
  const ActivePickupTrackerCard({
    required this.request,
    required this.onTapDetails,
    this.onPayMoMo,
    super.key,
  });

  final PickupRequest request;
  final VoidCallback onTapDetails;
  final VoidCallback? onPayMoMo;

  int get _stepIndex => switch (request.status) {
    RequestStatus.requested => 0,
    RequestStatus.collected => 1,
    RequestStatus.awaitingVerification => 2,
    RequestStatus.paid => 3,
    RequestStatus.cancelled => -1,
  };

  String get _stageTitle => switch (request.status) {
    RequestStatus.requested => 'Tricycle Rider Dispatched',
    RequestStatus.collected => 'Waste Collected • In Transit',
    RequestStatus.awaitingVerification => 'Depot Verification Pending',
    RequestStatus.paid => 'Pickup Verified & Settled',
    RequestStatus.cancelled => 'Pickup Cancelled',
  };

  String get _stageSubtitle => switch (request.status) {
    RequestStatus.requested => 'Rider heading to your address in Arua',
    RequestStatus.collected => 'Collected by rider, in transit to sorting depot',
    RequestStatus.awaitingVerification => 'Depot administrator reviewing audit weight',
    RequestStatus.paid => 'Thank you for keeping Arua City clean!',
    RequestStatus.cancelled => 'This order was cancelled',
  };

  @override
  Widget build(BuildContext context) {
    final rawSuffix = request.id.replaceAll(RegExp(r'[^0-9]'), '');
    final shortId = rawSuffix.length >= 6
        ? rawSuffix.substring(rawSuffix.length - 6)
        : (request.id.length > 6
            ? request.id.substring(request.id.length - 6).toUpperCase()
            : request.id.toUpperCase());

    final step = _stepIndex;
    const terracotta = Color(0xFF9C3D18);
    const primaryInk = Color(0xFF0D2618);
    const subtleTint = Color(0x1F0D2618);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: Stage title + Short ID in Terracotta on left, Outlined tricycle icon on right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                '$_stageTitle #$shortId',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: terracotta,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.electric_rickshaw_outlined,
              size: 26,
              color: terracotta,
            ),
          ],
        ),
        const SizedBox(height: 3),
        // Subtitle: Rider heading to your address in Arua
        Text(
          _stageSubtitle,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: primaryInk,
          ),
        ),
        const SizedBox(height: 14),

        // 4-Step Horizontal Stepper (Requested -> Collected -> Verifying -> Settled)
        Row(
          children: [
            for (int i = 0; i < 4; i++) ...[
              // Step Node
              if (i <= (step >= 0 ? step : 0))
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: terracotta,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: Color(0xFF72B08D),
                    ),
                  ),
                )
              else if (i == (step >= 0 ? step : 0) + 1)
                Container(
                  width: 11,
                  height: 11,
                  decoration: const BoxDecoration(
                    color: terracotta,
                    shape: BoxShape.circle,
                  ),
                )
              else
                Container(
                  width: 11,
                  height: 11,
                  decoration: const BoxDecoration(
                    color: subtleTint,
                    shape: BoxShape.circle,
                  ),
                ),

              // Connecting Line
              if (i < 3)
                Expanded(
                  child: Container(
                    height: i <= (step >= 0 ? step : 0) ? 2.5 : 1.5,
                    color: i <= (step >= 0 ? step : 0) ? terracotta : subtleTint,
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        // Step labels
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Requested', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF1A3A28))),
            Text('Collected', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF1A3A28))),
            Text('Verifying', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF1A3A28))),
            Text('Settled', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF1A3A28))),
          ],
        ),
        const SizedBox(height: 14),

        // Details & CTA row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: Sack count & Address
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 16, color: primaryInk),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${request.sackCount} sack(s) • ${request.wasteType.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: primaryInk,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: primaryInk),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          request.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: primaryInk,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right column: Price on top + flat text link "View Live Status >" below
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatUgx(request.priceUgx),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: primaryInk,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTapDetails();
                  },
                  child: const Text(
                    'View Live Status >',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: terracotta,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// 4-card Quick Action Grid specifically tailored for residents.
class ResidentQuickActionsGrid extends StatelessWidget {
  const ResidentQuickActionsGrid({
    required this.onTapCamera,
    required this.onTapOrder,
    required this.onTapDatabase,
    required this.onTapOrders,
    super.key,
  });

  final VoidCallback onTapCamera;
  final VoidCallback onTapOrder;
  final VoidCallback onTapDatabase;
  final VoidCallback onTapOrders;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Resident Services',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF183B20),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.camera_alt_rounded,
                title: 'Scan Rubbish',
                subtitle: 'Photo & GPS Lock',
                color: const Color(0xFF2E8B57),
                badgeText: 'Instant',
                onTap: onTapCamera,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionTile(
                icon: Icons.local_shipping_rounded,
                title: 'Order Pickup',
                subtitle: 'Arua Tricycle Dispatch',
                color: const Color(0xFF1B5E3B),
                badgeText: 'On-Demand',
                onTap: onTapOrder,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.dataset_outlined,
                title: 'Waste Rates',
                subtitle: 'UGX & Lugbara Terms',
                color: const Color(0xFF0288D1),
                badgeText: 'Guide',
                onTap: onTapDatabase,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionTile(
                icon: Icons.receipt_long_rounded,
                title: 'My Pickups',
                subtitle: 'Track Status & Bills',
                color: const Color(0xFF7B1FA2),
                badgeText: 'History',
                onTap: onTapOrders,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.badgeText,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String badgeText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2EAE1)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF183B20),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF71877D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Resident personal environmental impact and clean city score card.
class ResidentEcoImpactCard extends StatelessWidget {
  const ResidentEcoImpactCard({
    required this.personalRequests,
    super.key,
  });

  final List<PickupRequest> personalRequests;

  @override
  Widget build(BuildContext context) {
    final paidOrders = personalRequests.where((o) => o.status == RequestStatus.paid).toList();
    final totalSacks = personalRequests.fold<int>(0, (sum, o) => sum + o.sackCount);
    final totalKg = totalSacks * 25;
    final co2AvoidedKg = (totalKg * 0.45).toStringAsFixed(1);

    final tier = paidOrders.length >= 5
        ? 'Eco Champion'
        : paidOrders.length >= 2
            ? 'Green Guardian'
            : 'Active Resident';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F9F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6E8DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco_rounded, size: 18, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Clean Arua Footprint',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF183B20),
                      ),
                    ),
                    Text(
                      'Municipal waste diverted from illegal dumping',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF647568),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tier,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ImpactMetric(
                  icon: Icons.delete_outline_rounded,
                  value: '$totalSacks',
                  unit: 'sacks',
                  label: 'Diverted',
                ),
              ),
              Container(width: 1, height: 36, color: const Color(0xFFD6E8DB)),
              Expanded(
                child: _ImpactMetric(
                  icon: Icons.scale_rounded,
                  value: '$totalKg',
                  unit: 'kg',
                  label: 'Recycled',
                ),
              ),
              Container(width: 1, height: 36, color: const Color(0xFFD6E8DB)),
              Expanded(
                child: _ImpactMetric(
                  icon: Icons.cloud_done_outlined,
                  value: co2AvoidedKg,
                  unit: 'kg',
                  label: 'CO₂ Saved',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImpactMetric extends StatelessWidget {
  const _ImpactMetric({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            color: Color(0xFF647568),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Educational waste segregation tips for residents.
class WasteSegregationTipsCard extends StatelessWidget {
  const WasteSegregationTipsCard({this.onTapDatabase, super.key});

  final VoidCallback? onTapDatabase;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAE1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_outlined, size: 18, color: Color(0xFFE65100)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Arua Waste Segregation Guide',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF183B20),
                  ),
                ),
              ),
              if (onTapDatabase != null)
                TextButton(
                  onPressed: onTapDatabase,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Full Rates →',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              _TipBadge(label: 'Organic (Gboo)', desc: 'UGX 1,500/sack • Compost'),
              SizedBox(width: 8),
              _TipBadge(label: 'Plastics & Glass', desc: 'Recycled at Oli Depot'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TipBadge extends StatelessWidget {
  const _TipBadge({required this.label, required this.desc});

  final String label;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAF8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2EAE1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF183B20),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: const TextStyle(fontSize: 9.5, color: Color(0xFF647568)),
            ),
          ],
        ),
      ),
    );
  }
}
