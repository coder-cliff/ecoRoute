import 'package:flutter/material.dart';

import '../../../core/services/app_install_service.dart';

/// Non-intrusive, responsive banner that prompts web and mobile visitors
/// to install the EcoRoute app (PWA or APK) if not already installed.
class SmartInstallBanner extends StatefulWidget {
  const SmartInstallBanner({super.key, this.forceShow = false});

  final bool forceShow;

  @override
  State<SmartInstallBanner> createState() => _SmartInstallBannerState();
}

class _SmartInstallBannerState extends State<SmartInstallBanner> {
  bool _shouldShow = false;
  bool _dismissedLocally = false;

  @override
  void initState() {
    super.initState();
    _checkInstallStatus();
    AppInstallService.instance.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    AppInstallService.instance.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) {
      setState(() {
        _shouldShow = !AppInstallService.instance.isDismissed && !AppInstallService.instance.isAppInstalled;
      });
    }
  }

  Future<void> _checkInstallStatus() async {
    final show = await AppInstallService.instance.shouldShowInstallBanner();
    if (mounted) {
      setState(() => _shouldShow = show);
    }
  }

  void _dismiss() {
    setState(() => _dismissedLocally = true);
    AppInstallService.instance.dismissBanner();
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissedLocally || (!_shouldShow && !widget.forceShow)) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0D2618),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;

            if (isCompact) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B3828),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF2E553E)),
                        ),
                        child: const Icon(Icons.install_mobile_rounded, color: Color(0xFFA3CFB1), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Get the Official EcoRoute App',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Faster pickups, offline map, and live driver tracking.',
                              style: TextStyle(
                                color: Color(0xFFB8C8BC),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                        onPressed: _dismiss,
                        tooltip: 'Dismiss',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: FilledButton.icon(
                            onPressed: () => AppInstallService.instance.triggerInstall(),
                            icon: const Icon(Icons.download_rounded, size: 14),
                            label: const Text('Install App', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: () => AppInstallService.instance.downloadApk(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFA3CFB1),
                            side: const BorderSide(color: Color(0xFF2E553E)),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('APK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            // Desktop / Tablet layout: single line
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B3828),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2E553E)),
                  ),
                  child: const Icon(Icons.install_mobile_rounded, color: Color(0xFFA3CFB1), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Install the EcoRoute Application',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Experience real-time tricycle dispatch, offline collection logs, and fast GPS sync on your device.',
                        style: TextStyle(
                          color: Color(0xFFB8C8BC),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 34,
                  child: FilledButton.icon(
                    onPressed: () => AppInstallService.instance.triggerInstall(),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Install App', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 34,
                  child: OutlinedButton.icon(
                    onPressed: () => AppInstallService.instance.downloadApk(),
                    icon: const Icon(Icons.android_rounded, size: 16),
                    label: const Text('Download APK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFA3CFB1),
                      side: const BorderSide(color: Color(0xFF2E553E)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                  onPressed: _dismiss,
                  tooltip: 'Dismiss',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
