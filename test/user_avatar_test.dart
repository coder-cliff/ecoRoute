import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/models/user_model.dart';
import 'package:ecoroute/widgets/user_avatar.dart';

void main() {
  group('UserAvatar Widget Tests', () {
    testWidgets('UserAvatar displays initials when avatarUrl is empty', (WidgetTester tester) async {
      const user = AppUser(
        id: 'usr_001',
        name: 'Sarah Namukasa',
        phone: '+256 700 000000',
        email: 'sarah@ecoroute.app',
        role: UserRole.citizen,
        avatarUrl: '',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(user: user, radius: 24),
          ),
        ),
      );

      // Sarah Namukasa -> 'SN'
      expect(find.text('SN'), findsOneWidget);
    });

    testWidgets('UserAvatar renders role badge when showRoleBadge is true', (WidgetTester tester) async {
      const rider = AppUser(
        id: 'usr_rider',
        name: 'Alex Mukasa',
        phone: '+256 701 111111',
        email: 'alex@ecoroute.app',
        role: UserRole.rider,
        avatarUrl: 'preset:rider_tricycle',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(user: rider, radius: 24, showRoleBadge: true),
          ),
        ),
      );

      // Rider badge icon
      expect(find.byIcon(Icons.two_wheeler_rounded), findsWidgets);
    });

    testWidgets('UserAvatar renders admin icon badge for admin persona', (WidgetTester tester) async {
      const admin = AppUser(
        id: 'usr_admin',
        name: 'Grace Atuhaire',
        phone: '+256 750 222222',
        email: 'grace@ecoroute.app',
        role: UserRole.admin,
        avatarUrl: 'preset:admin_badge',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(user: admin, radius: 24, showRoleBadge: true),
          ),
        ),
      );

      expect(find.byIcon(Icons.admin_panel_settings_rounded), findsOneWidget);
    });
  });
}
