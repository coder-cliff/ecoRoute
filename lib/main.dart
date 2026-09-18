import 'package:flutter/material.dart';

void main() {
  runApp(const WasteWiseApp());
}

class WasteWiseApp extends StatelessWidget {
  const WasteWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF164A3A);
    return MaterialApp(
      title: 'WasteWise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: forest),
        scaffoldBackgroundColor: const Color(0xFFF5F7F2),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  bool _pickupRequested = false;

  void _requestPickup() {
    setState(() => _pickupRequested = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pickup request received.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHome(context),
            const Center(child: Text('Collection history')),
            const Center(child: Text('Your profile')),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHome(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEDE2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.recycling, color: Color(0xFF164A3A), size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('WASTEWISE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.8, color: Color(0xFF537264))),
                    SizedBox(height: 2),
                    Text('Good morning, Alex', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF18352B))),
                  ],
                ),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
            ],
          ),
          const SizedBox(height: 26),
          Text('Make every pickup count.', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF18352B))),
          const SizedBox(height: 6),
          Text('Track your impact and keep your neighborhood clean.', style: textTheme.bodyMedium?.copyWith(color: const Color(0xFF62766C))),
          const SizedBox(height: 22),
          _buildNextPickupCard(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('This month', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF18352B))),
              Text('View details', style: textTheme.labelLarge?.copyWith(color: const Color(0xFF2E8060), fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildMetric('28 kg', 'Diverted', Icons.eco_outlined, const Color(0xFFE0F1E5))),
            const SizedBox(width: 12),
            Expanded(child: _buildMetric('12', 'Pickups', Icons.local_shipping_outlined, const Color(0xFFFFEBD1))),
          ]),
          const SizedBox(height: 26),
          Text('Waste breakdown', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF18352B))),
          const SizedBox(height: 12),
          _buildBreakdown('Organic', '14.2 kg', 0.72, const Color(0xFF4B936A), Icons.compost),
          _buildBreakdown('Recyclables', '9.6 kg', 0.49, const Color(0xFF4E8BB7), Icons.recycling),
          _buildBreakdown('General waste', '4.2 kg', 0.25, const Color(0xFFE19A55), Icons.delete_outline),
        ],
      ),
    );
  }

  Widget _buildNextPickupCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF164A3A),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x30164A3A), blurRadius: 18, offset: Offset(0, 9))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Expanded(child: Text('NEXT PICKUP', style: TextStyle(color: Color(0xFFB8D7C3), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF2E8060), borderRadius: BorderRadius.circular(20)), child: const Text('On schedule', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 18),
          const Row(children: [
            Icon(Icons.calendar_today_outlined, color: Color(0xFFE6F2E8), size: 24),
            SizedBox(width: 12),
            Text('Tuesday, 24 September', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          const Row(children: [
            Icon(Icons.access_time, color: Color(0xFFB8D7C3), size: 18),
            SizedBox(width: 10),
            Text('08:00 - 11:00 AM  •  All categories', style: TextStyle(color: Color(0xFFB8D7C3), fontSize: 13)),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _pickupRequested ? null : _requestPickup,
              icon: Icon(_pickupRequested ? Icons.check : Icons.add, size: 18),
              label: Text(_pickupRequested ? 'Pickup requested' : 'Request extra pickup'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE1F1E5), foregroundColor: const Color(0xFF164A3A), padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE5EBE5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(radius: 18, backgroundColor: color, child: Icon(icon, size: 19, color: const Color(0xFF285840))),
        const SizedBox(height: 14),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF18352B))),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7D73))),
      ]),
    );
  }

  Widget _buildBreakdown(String label, String amount, double progress, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        CircleAvatar(radius: 19, backgroundColor: color.withAlpha(35), child: Icon(icon, size: 20, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF365045))),
            Text(amount, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF18352B))),
          ]),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress, minHeight: 7, backgroundColor: const Color(0xFFE5EBE5), color: color)),
        ])),
      ]),
    );
  }
}
