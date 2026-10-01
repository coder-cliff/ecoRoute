# EcoRoute

EcoRoute is an offline-first waste collection app for Arua homes and small trading centers. The project is being reshaped around the MVP plan in the design brief: domain-first business rules, feature-based folders, and a local-first data model.

## App status

The codebase now follows a more maintainable structure:

- app shell and theme under `lib/app`
- domain entities, enums, and rules under `lib/domain`
- screens under `lib/features`
- shared support code under `lib/core`
- domain rule tests in `test/domain_rules_test.dart`

## Run locally

```bash
flutter pub get
flutter run
```

## Test

```bash
flutter test
```

## MVP architecture notes

- Zone logic lives in `lib/domain/rules/zone_resolver.dart`
- Request lifecycle rules live in `lib/domain/rules/status_machine.dart`
- Price calculation is isolated in `lib/domain/rules/price_calculator.dart`
- The dashboard remains a working prototype while the project moves toward the full Week 8–10 architecture
