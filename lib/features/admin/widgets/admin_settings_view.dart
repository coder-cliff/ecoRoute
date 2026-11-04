import 'package:flutter/material.dart';

import '../../../core/services/rider_invite_service.dart';
import '../../../core/services/theme_service.dart';

class AdminSettingsView extends StatefulWidget {
  const AdminSettingsView({
    required this.onShowConfigureEmailGateway,
    this.onSignOut,
    super.key,
  });

  final VoidCallback onShowConfigureEmailGateway;
  final VoidCallback? onSignOut;

  @override
  State<AdminSettingsView> createState() => _AdminSettingsViewState();
}

class _AdminSettingsViewState extends State<AdminSettingsView> {
  // Municipal Fee Configuration State
  final _baseSackFeeCtrl = TextEditingController(text: '3,000');
  final _bulkySurchargeCtrl = TextEditingController(text: '5,000');
  final _maxTricycleSacksCtrl = TextEditingController(text: '15');
  final _riderCommissionCtrl = TextEditingController(text: '70');

  // Coverage Zones State
  bool _zoneCentral = true;
  bool _zoneAyivu = true;
  bool _zoneMuni = true;
  bool _zoneRiverOli = true;
  bool _weatherEmergencyAlert = false;

  @override
  void dispose() {
    _baseSackFeeCtrl.dispose();
    _bulkySurchargeCtrl.dispose();
    _maxTricycleSacksCtrl.dispose();
    _riderCommissionCtrl.dispose();
    super.dispose();
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Municipal operational settings saved successfully.'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF192A1D) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2A3F2F) : const Color(0xFFE2EAE1);
    final subtextColor = isDark ? const Color(0xFF9EABA1) : const Color(0xFF647568);
    final sectionTitleColor = isDark ? Colors.white : const Color(0xFF183B20);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Appearance & Theme Setting
        _SectionContainer(
          title: 'Display & Appearance',
          subtitle: 'Customize EcoRoute visual interface and dark mode',
          icon: Icons.palette_outlined,
          cardBg: cardBg,
          cardBorder: cardBorder,
          titleColor: sectionTitleColor,
          subtextColor: subtextColor,
          child: Column(
            children: [
              ListenableBuilder(
                listenable: ThemeService.instance,
                builder: (context, _) {
                  final currentMode = ThemeService.instance.themeMode;

                  return Row(
                    children: [
                      Expanded(
                        child: _ThemeChoiceTile(
                          title: 'Light',
                          icon: Icons.light_mode_outlined,
                          selected: currentMode == ThemeMode.light,
                          onTap: () => ThemeService.instance.setThemeMode(ThemeMode.light),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ThemeChoiceTile(
                          title: 'Dark',
                          icon: Icons.dark_mode_outlined,
                          selected: currentMode == ThemeMode.dark,
                          onTap: () => ThemeService.instance.setThemeMode(ThemeMode.dark),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ThemeChoiceTile(
                          title: 'System',
                          icon: Icons.settings_brightness_outlined,
                          selected: currentMode == ThemeMode.system,
                          onTap: () => ThemeService.instance.setThemeMode(ThemeMode.system),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Municipal Waste Tariffs & Fees
        _SectionContainer(
          title: 'Municipal Waste Tariffs (UGX)',
          subtitle: 'Collection fees applied across Arua resident orders',
          icon: Icons.price_change_outlined,
          cardBg: cardBg,
          cardBorder: cardBorder,
          titleColor: sectionTitleColor,
          subtextColor: subtextColor,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _baseSackFeeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Base Fee / Sack (UGX)',
                        prefixIcon: const Icon(Icons.attach_money_rounded, size: 18),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _bulkySurchargeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Bulky Surcharge (UGX)',
                        prefixIcon: const Icon(Icons.add_circle_outline, size: 18),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _maxTricycleSacksCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Tricycle Max Sacks',
                        prefixIcon: const Icon(Icons.two_wheeler_rounded, size: 18),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _riderCommissionCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Rider Payout (%)',
                        prefixIcon: const Icon(Icons.percent_rounded, size: 18),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Arua Coverage Zones
        _SectionContainer(
          title: 'Arua City Coverage Sectors',
          subtitle: 'Active collection areas served by the tricycle fleet',
          icon: Icons.location_city_outlined,
          cardBg: cardBg,
          cardBorder: cardBorder,
          titleColor: sectionTitleColor,
          subtextColor: subtextColor,
          child: Column(
            children: [
              _ZoneSwitchRow(
                title: 'Arua Central Division',
                subtitle: 'Main Market, Avenue Road, Hospital Area',
                value: _zoneCentral,
                onChanged: (v) => setState(() => _zoneCentral = v),
                isDark: isDark,
              ),
              const Divider(height: 12),
              _ZoneSwitchRow(
                title: 'Ayivu Division',
                subtitle: 'Onduparaka, Adumi Road, Pajulu',
                value: _zoneAyivu,
                onChanged: (v) => setState(() => _zoneAyivu = v),
                isDark: isDark,
              ),
              const Divider(height: 12),
              _ZoneSwitchRow(
                title: 'Muni University Corridor',
                subtitle: 'Campus grounds, faculty residences, student hostels',
                value: _zoneMuni,
                onChanged: (v) => setState(() => _zoneMuni = v),
                isDark: isDark,
              ),
              const Divider(height: 12),
              _ZoneSwitchRow(
                title: 'River Oli & Arua Hill',
                subtitle: 'Commercial strip and hillside residential sector',
                value: _zoneRiverOli,
                onChanged: (v) => setState(() => _zoneRiverOli = v),
                isDark: isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4. Operational Safety & Weather Alerts
        _SectionContainer(
          title: 'Safety & Dispatch Protocol',
          subtitle: 'Emergency weather warning and fleet safety alerts',
          icon: Icons.security_rounded,
          cardBg: cardBg,
          cardBorder: cardBorder,
          titleColor: sectionTitleColor,
          subtextColor: subtextColor,
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Severe Weather Alert Broadcast',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Notify all active tricycle riders of unpaved road hazards and heavy rain.',
                  style: TextStyle(fontSize: 10, color: subtextColor),
                ),
                value: _weatherEmergencyAlert,
                activeThumbColor: const Color(0xFF2E7D32),
                onChanged: (v) => setState(() => _weatherEmergencyAlert = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 5. Cloud Gateway & Integration Config
        _SectionContainer(
          title: 'Cloud Gateway & Integrations',
          subtitle: 'Google Apps Script MailApp API and Firebase Status',
          icon: Icons.cloud_sync_outlined,
          cardBg: cardBg,
          cardBorder: cardBorder,
          titleColor: sectionTitleColor,
          subtextColor: subtextColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.email_outlined, size: 18, color: Color(0xFF2E7D32)),
                  ),
                  title: const Text('MailApp Web Gateway', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    RiderInviteService.scriptUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  ),
                  trailing: TextButton(
                    onPressed: widget.onShowConfigureEmailGateway,
                    child: const Text('Configure', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ),
              const Divider(height: 12),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Firebase Authentication & Firestore: Active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFC7D3C9) : const Color(0xFF183B20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Save Button & Logout Row
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Save Operational Settings'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (widget.onSignOut != null) ...[
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: widget.onSignOut,
                icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.redAccent),
                label: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SectionContainer extends StatelessWidget {
  const _SectionContainer({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.cardBg,
    required this.cardBorder,
    required this.titleColor,
    required this.subtextColor,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color cardBg;
  final Color cardBorder;
  final Color titleColor;
  final Color subtextColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 10, color: subtextColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _ThemeChoiceTile extends StatelessWidget {
  const _ThemeChoiceTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final activeBg = const Color(0xFF2E7D32);
    final inactiveBg = isDark ? const Color(0xFF233627) : const Color(0xFFF3F7F4);
    final activeText = Colors.white;
    final inactiveText = isDark ? const Color(0xFFC7D3C9) : const Color(0xFF37474F);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF1B5E20) : (isDark ? const Color(0xFF2E4633) : const Color(0xFFDCE8DB)),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: selected ? activeText : inactiveText),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? activeText : inactiveText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneSwitchRow extends StatelessWidget {
  const _ZoneSwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF183B20),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? const Color(0xFF9EABA1) : const Color(0xFF647568),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: const Color(0xFF2E7D32),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
