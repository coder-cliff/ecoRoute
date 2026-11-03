import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final IconData icon;
  final Color color;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.icon,
    required this.color,
    this.isRead = false,
  });
}

class NotificationProvider with ChangeNotifier {
  final List<AppNotification> _notifications = [
    AppNotification(
      id: 'notif_01',
      title: 'Welcome to EcoRoute',
      message: 'Take a photo of waste and auto-capture GPS coordinates for scheduled cash pickup.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      icon: Icons.eco_rounded,
      color: AppTheme.primaryGreen,
      isRead: false,
    ),
    AppNotification(
      id: 'notif_02',
      title: 'Rider Fleet Ready',
      message: 'Collection tricycles are actively patrolling Kololo, Kamwokya, and Makerere zones.',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      icon: Icons.two_wheeler_rounded,
      color: const Color(0xFF0D6EFD),
      isRead: true,
    ),
  ];

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void triggerNotification({
    required String title,
    required String message,
    IconData icon = Icons.notifications_active_rounded,
    Color color = AppTheme.primaryGreen,
  }) {
    final notif = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      timestamp: DateTime.now(),
      icon: icon,
      color: color,
      isRead: false,
    );

    _notifications.insert(0, notif);
    notifyListeners();
  }

  void markAllAsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
