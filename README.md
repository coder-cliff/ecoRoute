
# EcoRoute

EcoRoute is an offline-first waste collection app for Arua homes and small trading centers. The project is being built around the MVP plan in the design brief: domain-first business rules, feature-based folders, and a local-first data model.

## Current project status

The codebase is now a Week 9 offline-first demo with role-specific operations:

- Android support has been generated for the project.
- App shell and theme live under `lib/app`.
- Domain entities, enums, and rules live under `lib/domain`.
- Feature screens live under `lib/features`.
- Shared support code lives under `lib/core`.
- Business rules are covered by tests in `test/domain_rules_test.dart`.
- Resident, rider, and admin role flows are available through the auth sheet and role-specific dashboards.
- Riders get a route-stop queue driven by saved pickup requests and can advance pickups through collection and verification.
- Admins get an approval queue with approve/return actions plus an analytics breakdown based on persisted request statuses.
- The service-area map panel includes an illustrative Arua zone view and request count; it does not require a map service or network connection.
- Local persistence layer is in place via `SharedPreferencesPickupRequestRepository`.

## Run locally

```bash
flutter pub get
flutter run
```

## Test

```bash
flutter test
flutter analyze
```

## Week 9 demo features

The current implementation is centered on the MVP path:

- Zone logic in `lib/domain/rules/zone_resolver.dart`
- Request lifecycle rules in `lib/domain/rules/status_machine.dart`
- Price calculation in `lib/domain/rules/price_calculator.dart`
- Reminder policy in `lib/domain/rules/reminder_policy.dart`
- App config in `lib/app/config/app_config.dart`
- Rider route actions and admin approval/analytics panels in `lib/features/home/home_screen.dart`

## MVP notes

- The app is intentionally local-first and domain-driven.
- Zone logic is configured around the Arua reference point and service radius.
- Requests are modelled as domain entities before any Firebase or Firestore integration is added.
- The splash screen transitions after 1.5 seconds to the resident, rider and admin demo dashboard.
- Demo accounts are resident@ecoroute.demo, rider@ecoroute.demo and admin@ecoroute.demo; each uses `demo123`.
- Route, approval and analytics data comes from local pickup requests. Financial totals are intentionally not fabricated because requests do not yet store payment amounts.
