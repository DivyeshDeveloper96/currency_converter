# Currency Converter

A Flutter-based Advanced Currency Converter that lets users input amounts in multiple currencies, convert them all to a selected base currency using real-time exchange rates, and see the normalised total — with offline support via local SQLite caching.

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── app.dart                           # MaterialApp, theme, routes
│
├── core/
│   ├── constants/app_constants.dart   # API key, URLs, cache TTL
│   ├── errors/app_exception.dart      # Typed exception hierarchy
│   ├── network/
│   │   ├── dio_client.dart            # Dio singleton with interceptors
│   │   └── network_info.dart          # Connectivity checker
│   └── utils/
│       ├── currency_formatter.dart    # Number/currency formatting
│       └── debouncer.dart             # Search input debounce
│
├── data/
│   ├── models/
│   │   ├── currency.dart              # Currency code/name model
│   │   └── exchange_rate.dart         # Rates map + conversion logic
│   ├── datasources/
│   │   ├── local/
│   │   │   ├── database_helper.dart   # SQLite setup and helpers
│   │   │   └── exchange_rate_local_source.dart
│   │   └── remote/
│   │       └── exchange_rate_remote_source.dart
│   └── repositories/
│       ├── currency_repository.dart   # Abstract contract
│       └── currency_repository_impl.dart  # Cache-first strategy
│
├── presentation/
│   ├── providers/providers.dart       # All Riverpod providers (DI wiring)
│   ├── viewmodels/
│   │   ├── converter_viewmodel.dart   # Core conversion state + logic
│   │   ├── currencies_viewmodel.dart  # Currency list + search
│   │   └── settings_viewmodel.dart    # Base currency preference
│   ├── screens/
│   │   ├── converter/converter_screen.dart
│   │   ├── currencies/currencies_screen.dart
│   │   └── settings/settings_screen.dart
│   └── widgets/
│       ├── currency_input_card.dart   # Per-row input with currency picker
│       ├── result_display.dart        # Gradient total result card
│       └── app_error_widget.dart      # Error & offline banner
│
test/
├── viewmodels/
│   ├── converter_viewmodel_test.dart
│   └── settings_viewmodel_test.dart
└── repositories/
    └── currency_repository_test.dart
```

---

## Architecture

The app follows **MVVM (Model–View–ViewModel)** with a clean layered approach:

```
View (Screens/Widgets)
    ↕ watches/reads via Riverpod
ViewModel (StateNotifier)
    ↕ calls
Repository (abstract interface)
    ↕ delegates to
DataSources (Remote API + Local SQLite)
```

- **Views** are fully reactive — they only watch state and forward user actions to the ViewModel. No business logic lives in widgets.
- **ViewModels** use `StateNotifier` from Riverpod. Each screen has exactly one ViewModel managing its state lifecycle.
- **Repository** implements a cache-first policy: serve fresh cache immediately, fetch from API only when stale or absent, fall back to stale cache when offline.
- **DataSources** are independently swappable. The local source uses raw `sqflite` for SQLite access. The remote source uses `Dio`.

---

## Key Design Decisions

**SQLite over Floor:** Chose raw `sqflite` to avoid code generation overhead while keeping full control over schema and queries. The `DatabaseHelper` singleton handles all transactions cleanly.

**Cache-first with 60-minute TTL:** Exchange rates are fetched once per hour per base currency. Stale data is served during offline sessions with a visible banner rather than blocking the user.

**Typed exceptions:** A sealed `AppException` hierarchy (`NetworkException`, `ServerException`, `CacheException`, etc.) keeps error handling explicit and exhaustive across the codebase.

**No code generation for models:** Models are hand-written with `fromJson`/`toMap`/`fromMap` to keep the build step minimal. Only Mockito mocks require `build_runner`.

**Cross-currency conversion:** All conversions go through the base currency (from → base → to), so any pair can be computed from a single `/latest` response, minimising API calls.

---

## Assumptions

- The free tier of apilayer's Exchange Rates Data API is used, which supports `/symbols` and `/latest` with USD as the default base.
- Orientation is locked to portrait for a cleaner single-column layout on both phone sizes.
- The Settings screen shows only a curated list of common currencies as base options rather than all 170+, since most users use USD, EUR, GBP, INR etc. as their base.
- Rate caching is per base currency — switching base triggers a fresh fetch.

---

## API Reference

Base URL: `https://api.apilayer.com/exchangerates_data`

| Endpoint | Description |
|----------|-------------|
| `GET /symbols` | Returns all supported currency codes and names |
| `GET /latest?base=USD` | Returns latest rates relative to the given base |

Auth: `apikey` header (from your apilayer dashboard).
