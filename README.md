# Tour Buddy

**Tour Buddy** is a modern, offline-first travel companion and budget management application built with Flutter and Firebase. Designed for travelers who want effortless expense tracking, itinerary planning, and seamless multi-device synchronization without intrusive clutter.

---

## Key Features

### Trip Planning & Budgeting
* **Multi-Trip Management**: Organize trips into **Active & Upcoming** and **Past Trips** with automatic date-based archiving.
* **Date Range Picker**: Select departure and return dates seamlessly with an integrated calendar picker.
* **Multi-Currency Support**: Budget and track expenses in BDT, USD, EUR, GBP, or INR with live currency conversion and offline rate caching.
* **Visual Budget Progress**: Dynamic progress meters that change color as you approach or exceed your budget limits.

### Expense Tracking & Categorization
* **Visual Category Badges**: Color-coded categorization across **Food**, **Transport**, **Stay**, **Shopping**, **Activities**, and **Other**.
* **Flexible Foreign Currencies**: Log expenses in local foreign currencies while Tour Buddy automatically converts and tracks against your home trip budget.
* **Fluid Gestures**: Tap any expense to open the edit sheet; swipe to delete with an immediate **Undo** option.
* **Flexible Sorting**: Sort transactions by newest first, oldest first, highest amount, lowest amount, or category.

### Dual-Tab Travel Companion
* **Expenses Tab**: Granular transaction ledger, category distribution, and live spending metrics.
* **Itinerary & Notes Tab**: Dedicated markdown travel notebook with quick-insert templates for **Hotel Reservations**, **Flight Details**, **Daily Itinerary**, and **Packing Checklists**.

### Offline-First Architecture & Cloud Sync
* **Offline Exchange Rates**: Exchange rates are cached locally in `SharedPreferences`—convert currencies even in airplane mode or remote areas.
* **Offline Persistence**: Full read and write capabilities without an active network; automatically synchronizes with Cloud Firestore when back online.
* **Google Cloud Backup**: Optional, non-intrusive Google Sign-In to back up and sync your trips across all your Android devices.

### Thoughtful Human Design
* **Zero Emoji Clutter**: Professional, clean typography using Google Fonts and native Material Design 3 guidelines.
* **Adaptive Modal Sheets**: Bottom sheets designed for one-handed operation with built-in keyboard avoidance.
* **Overflow Resilience**: Responsive layouts constrained with flexible text wrappers that adapt to any screen size and font scaling settings.

---

## Tech Stack

| Component | Technology |
|---|---|
| **Framework** | Flutter (Dart SDK ^3.5.3) |
| **State Management** | Provider |
| **Backend & Cloud** | Firebase Authentication & Cloud Firestore |
| **Local Storage** | SharedPreferences |
| **Currency API** | ExchangeRate-API v6 |
| **Platform** | Android (minSdk 23) & iOS |

---

## Project Structure & Architecture

```text
lib/
├── firebase_options.dart      # Firebase initialization configuration
├── main.dart                  # App entry point, theme configuration, and provider bindings
├── theme_provider.dart        # Light and dark theme state management
├── models/
│   ├── trip.dart              # Core Trip model (dates, budget, destination, markdown notes, serialization)
│   ├── expense.dart           # Typed Expense entity (amount, category, foreign currency, timestamps)
│   └── expense_category.dart  # Category taxonomy (Food, Transport, Stay, etc.) with icons & color palette
├── providers/
│   └── trip_provider.dart     # Central state manager, Firestore synchronization & sample data seeder
├── screens/
│   ├── start_screen.dart      # Home dashboard with Active & Upcoming trips, date-range trip planner
│   ├── expense_screen.dart    # Dual-tab screen: Expenses ledger (insights/sorting) & Itinerary notebook
│   ├── past_trips_screen.dart # Archive of past journeys with budget metrics and trip management
│   └── settings_screen.dart   # App settings, currency preferences, and theme toggle
└── services/
    └── currency_service.dart  # ExchangeRate-API integration with offline caching in SharedPreferences

test/
└── widget_test.dart           # Unit test suite verifying models, serialization & currency conversion

assets/
└── images/
    ├── TourBuddylogo.png      # Tour Buddy logo artwork and launcher icon source
    └── google_logo.png        # Google Cloud Sync branding asset
```

---

## Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.5.3 or higher)
* Android Studio / VS Code with Flutter extensions
* Android SDK (API 23+) or connected physical device

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/meawsin/Tour_Buddy.git
   cd tour_buddy
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Firebase Setup** (Optional for local testing):
   * Place your `google-services.json` inside `android/app/`.
   * Add your debug SHA-1 and SHA-256 certificate fingerprints in Firebase Console.

4. **Run the application**:
   ```bash
   flutter run
   ```

5. **Run tests**:
   ```bash
   flutter test
   ```

---

## Build Standalone Release APK

To generate a production-ready, standalone Android APK:
```bash
flutter build apk --release
```
The output APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## License

This project is licensed under the MIT License - see the LICENSE file for details.
