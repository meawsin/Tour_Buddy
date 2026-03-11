# 🌍 Tour Buddy

A full-featured travel expense tracker built with Flutter and Firebase.

## ✨ Features

- **Trip Management** — Create and manage multiple trips with budgets, destinations, and dates
- **Expense Tracking** — Log expenses by category (Food, Transport, Accommodation, Shopping, Activities, Other)
- **Analytics Dashboard** — Interactive charts powered by fl_chart
  - Daily spending bar chart
  - Category breakdown donut chart
  - Budget vs spent progress
  - Daily average, top day, top category stats
- **Google Sign-in** — Anonymous → Google account linking with trip data migration
- **Dark / Light Theme** — Material 3 design with persistent theme preference
- **Currency Support** — BDT, USD, EUR, GBP, INR, JPY, AUD
- **Font Size Control** — Adjustable text scale in settings
- **Past Trips** — Archive and review completed trips

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart) |
| State Management | Provider |
| Backend | Firebase (Auth + Firestore) |
| Charts | fl_chart |
| Fonts | Google Fonts (Syne + DM Sans) |
| Auth | Firebase Auth (Anonymous + Google Sign-in) |

## 📱 Screenshots

*Coming soon*

## 🚀 Getting Started

1. Clone the repo
```bash
git clone https://github.com/meawsin/Tour_Buddy.git
cd Tour_Buddy
```

2. Install dependencies
```bash
flutter pub get
```

3. Add your `google-services.json` to `android/app/`

4. Run the app
```bash
flutter run
```

## 📁 Project Structure

```
lib/
├── main.dart
├── theme_provider.dart
├── firebase_options.dart
├── models/
│   ├── trip.dart
│   └── expense_model.dart
├── providers/
│   └── trip_provider.dart
├── screens/
│   ├── start_screen.dart
│   ├── expense_screen.dart
│   ├── analytics_screen.dart
│   ├── past_trips_screen.dart
│   └── settings_screen.dart
└── services/
    ├── currency_service.dart
    └── security_service.dart
```

## 🔐 Firebase Setup

- Anonymous Auth + Google Sign-in enabled
- Firestore rules scoped per user UID
- SHA-1 fingerprint registered for Google Sign-in

## 👨‍💻 Author

**Mohsin** — [@meawsin](https://github.com/meawsin)