import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/pickup_request.dart';
import '../../../domain/enums/request_status.dart';
import '../../../domain/enums/waste_type.dart';

/// Personalized greeting card for residents showing time-of-day greeting,
/// user profile pill, and quick eco-status.
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
    if (user == null || user!.fullName.isEmpty) return 'EcoRoute Resident';
    final parts = user!.fullName.trim().split(RegExp(r'\s+'));
    return parts.first;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E3B), Color(0xFF2E8B57)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x281B5E3B),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'R',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_greeting, $_displayName!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF69F0AE),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Arua City • On-Demand Tricycles Active',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFD4EED8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onTapProfile != null)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTapProfile,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Resident',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFFFD54F)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    activeRequestsCount > 0
                        ? '$activeRequestsCount collection request${activeRequestsCount > 1 ? 's' : ''} currently in progress'
                        : 'Instant waste collection ready • Average rider arrival 20-35 mins',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF1F8F3),
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
}

/// Active pickup tracking card shown prominently on the resident home dashboard.
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
    RequestStatus.collected => 'Waste Collected • In Transit to Depot',
    RequestStatus.awaitingVerification => 'Depot Verification Pending',
    RequestStatus.paid => 'Pickup Verified & Settled',
    RequestStatus.cancelled => 'Pickup Cancelled',
  };

  String get _stageSubtitle => switch (request.status) {
    RequestStatus.requested => 'Rider heading to your address in Arua',
    RequestStatus.collected => 'Collected by rider, weighing at sorting center',
    RequestStatus.awaitingVerification => 'Depot administrator reviewing audit weight',
    RequestStatus.paid => 'Thank you for keeping Arua City clean!',
    RequestStatus.cancelled => 'This order was cancelled',
  };

  Color get _stageColor => switch (request.status) {
    RequestStatus.requested => const Color(0xFFE65100),
    RequestStatus.collected => const Color(0xFF0288D1),
    RequestStatus.awaitingVerification => const Color(0xFF7B1FA2),
    RequestStatus.paid => const Color(0xFF2E7D32),
    RequestStatus.cancelled => const Color(0xFFC62828),
  };

  @override
  Widget build(BuildContext context) {
    final shortId = request.id.length > 6
        ? request.id.substring(request.id.length - 6).toUpperCase()
        : request.id.toUpperCase();

    final step = _stepIndex;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _stageColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _stageColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _stageColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _stageColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    request.status == RequestStatus.paid
                        ? Icons.check
                        : Icons.two_wheeler_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _stageTitle,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _stageColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '#$shortId',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: _stageColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _stageSubtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF556958),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stepper bar
          if (step >= 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      for (int i = 0; i < 4; i++) ...[
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: i <= step ? _stageColor : const Color(0xFFE0E6E2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              i <= step ? Icons.check : Icons.circle,
                              size: 11,
                              color: i <= step ? Colors.white : const Color(0xFF9E9E9E),
                            ),
                          ),
                        ),
                        if (i < 3)
                          Expanded(
                            child: Container(
                              height: 3,
                              color: i < step ? _stageColor : const Color(0xFFE0E6E2),
                            ),
                          ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Requested', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF556958))),
                      Text('Collected', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF556958))),
                      Text('Verifying', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF556958))),
                      Text('Settled', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF556958))),
                    ],
                  ),
                ],
              ),
            ),

          // Request Summary details
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 14, color: _stageColor),
                          const SizedBox(width: 4),
                          Text(
                            '${request.sackCount} sack(s) • ${request.wasteType.label}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B2E23),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF71877D)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              request.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF556958),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatUgx(request.priceUgx),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 4),
                    OutlinedButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        onTapDetails();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(0, 28),
                        side: BorderSide(color: _stageColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'View Live Status',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _stageColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
              _TipBadge(label: '🌿 Organic (Gboo)', desc: 'UGX 1,500/sack • Compost'),
              SizedBox(width: 8),
              _TipBadge(label: '🍾 Plastics & Glass', desc: 'Recycled at Oli Depot'),
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
