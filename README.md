
# EcoRoute

EcoRoute is an offline-first waste collection app for Arua homes and small trading centers. The project is being built around the MVP plan in the design brief: domain-first business rules, feature-based folders, and a local-first data model.

## Current project status

The codebase is now in a cleaner Week 8-ready state:

- Android support has been generated for the project.
- App shell and theme live under `lib/app`.
- Domain entities, enums, and rules live under `lib/domain`.
- Feature screens live under `lib/features`.
- Shared support code lives under `lib/core`.
- Business rules are covered by tests in `test/domain_rules_test.dart`.

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

## Week 8 / 9 focus

The current implementation is centered on the MVP path:

- Zone logic in `lib/domain/rules/zone_resolver.dart`
- Request lifecycle rules in `lib/domain/rules/status_machine.dart`
- Price calculation in `lib/domain/rules/price_calculator.dart`
- Reminder policy in `lib/domain/rules/reminder_policy.dart`
- App config in `lib/app/config/app_config.dart`

## MVP notes

- The app is intentionally local-first and domain-driven.
- Zone logic is configured around the Arua reference point and service radius.
- Requests are modelled as domain entities before any Firebase or Firestore integration is added.
- The next workstream is the full request flow, rider/admin transitions, and persistence layer.
