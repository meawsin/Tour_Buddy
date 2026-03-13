# Tour Buddy

A Flutter travel expense tracker with Firebase sync, analytics, PDF expense reports, and Google Sign-In. Built as a portfolio project demonstrating real-world mobile app development with clean architecture, live Firestore data, and a polished Material 3 UI.

---

## Screenshots

> Add screenshots here after final build — home screen, expense screen, analytics, PDF export.

---

## Features

- **Trip management** — create trips with destination, date range, budget, and currency; swipe to delete
- **Expense tracking** — add categorised expenses with atomic Firestore writes (no stale overwrites)
- **Budget alerts** — in-app banners at 50%, 80%, and 100% of budget with persistent dismiss
- **Analytics** — overview stats, daily bar chart, category donut chart (fl_chart)
- **PDF expense report** — formal bill layout with itemised table, grand total, and signature fields
- **Google Sign-In** — anonymous → Google account linking with full trip migration
- **Dark / light mode** — Material 3 theming with Syne + DM Sans fonts
- **Currency support** — per-trip currency with settings default
- **Offline-resilient** — Firestore offline persistence via SDK default caching

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart) |
| State management | Provider + ChangeNotifier |
| Backend | Firebase Firestore + Firebase Auth |
| Authentication | Anonymous + Google Sign-In |
| Charts | fl_chart ^0.70 |
| PDF generation | pdf ^3.11 + path_provider |
| Sharing | share_plus |
| Fonts | google_fonts (Syne + DM Sans) |
| Local storage | shared_preferences |
| HTTP | http (currency exchange rates) |

---

## Project Structure

```
lib/
├── main.dart                    # App entry, Firebase init, Provider setup
├── theme_provider.dart          # Theme, currency, username — persisted via SharedPreferences
├── constants/
│   └── categories.dart          # Expense category constants
├── models/
│   ├── trip.dart                # Trip model with Firestore serialisation
│   └── expense_model.dart       # Expense model
├── providers/
│   └── trip_provider.dart       # Auth + Firestore CRUD, Google Sign-In, trip migration
├── screens/
│   ├── start_screen.dart        # Home — trip list, stats, new trip sheet
│   ├── expense_screen.dart      # Trip detail — expenses, budget card, categories
│   ├── analytics_screen.dart    # Charts — overview, by day, by category
│   ├── past_trips_screen.dart   # Ended trips archive
│   └── settings_screen.dart     # Theme, currency, font size
├── services/
│   ├── budget_alert_service.dart # 50/80/100% budget thresholds, SharedPreferences dismiss
│   ├── currency_service.dart     # ExchangeRate-API with fallback rates
│   ├── pdf_export_service.dart   # Formal expense report PDF
│   └── security_service.dart    # Biometric auth helper
└── widgets/
    └── budget_alert_banner.dart  # Dismissible alert banner widget
```

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Android Studio or VS Code with Flutter extension
- Firebase project with Android app configured
- Java 17 (for Android build)

### Setup

1. Clone the repo:
   ```bash
   git clone https://github.com/meawsin/Tour_Buddy.git
   cd Tour_Buddy
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Add an Android app with package name `com.example.tour_buddy`
   - Download `google-services.json` → place in `android/app/`
   - Enable **Authentication** (Anonymous + Google providers)
   - Enable **Firestore Database**

4. Add your SHA-1 fingerprint to Firebase (required for Google Sign-In):
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

5. Set Firestore security rules:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /trips/{userId}/userTrips/{tripId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

6. Run:
   ```bash
   flutter run
   ```

### Android Build Config

`android/app/build.gradle` requires:
- `compileSdk 36`
- `minSdk 23`
- `JavaVersion.VERSION_17`
- Core library desugaring enabled

---

## Architecture Notes

### State management

`TripProvider` is a `ChangeNotifier` that owns all Firebase interactions. It listens to `FirebaseAuth.authStateChanges()` and automatically loads or clears trips when auth state changes.

`ThemeProvider` handles UI preferences (dark mode, currency, font size, username) via `SharedPreferences` with synchronous getters and async setters.

Both providers are initialised before `runApp()` and injected via `MultiProvider`.

### Firestore data model

```
trips/{uid}/userTrips/{tripId}
  name: string
  destination: string
  startDate: Timestamp
  endDate: Timestamp
  budget: number
  currency: string
  expenses: array of {
    id: string
    title: string
    amount: number
    category: string
    date: ISO string
    notes: string?
  }
```

Expenses are stored as an array field. Adds use `FieldValue.arrayUnion` and deletes use `FieldValue.arrayRemove` to prevent stale local-state overwrites on concurrent writes.

### Anonymous → Google migration

When an anonymous user signs in with Google and the Google account already exists:
1. Fetch all trips from the anonymous Firestore collection
2. Sign out of anonymous account
3. Sign in with Google credential
4. Write all fetched trips to the Google account's collection

This prevents data loss when a user creates trips before signing in.

---

## Running Tests

```bash
# Unit and widget tests (no device needed)
flutter test test/

# Integration tests (connected device required)
flutter test integration_test/expense_flow_test.dart
```

Test coverage includes Trip model serialisation, Expense model, CurrencyService fallback/conversion, budget alert thresholds, category constants, widget rendering, and pure business logic (totals, date ranges, sorting).

---

## Planned Features

- AI spending insights
- Map / destination photo integration
- Export to Google Sheets

---

## License

MIT
