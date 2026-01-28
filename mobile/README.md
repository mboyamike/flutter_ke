# Flutter Nairobi — Mobile

Mobile app for **Flutter Nairobi**. It currently supports **chats**.

## Stack

- **Flutter** — UI framework
- **Supabase** — Backend (auth, database, realtime)
- **Riverpod** — State management
- **auto_route** — Navigation and routing
- **freezed** & **json_serializable** — Models and JSON (de)serialization
- **SQLite** — Local storage
- **Firebase** — Crashlytics, Analytics, and Performance Monitoring

## File structure

The project uses a **mix of layer-first and feature-first** organization. There are three general layers:

1. **ui** — Screens, widgets, and presentation
2. **providers** — Riverpod providers and app state
3. **repositories** — Data access and remote/local sources

## Getting Started

### Prerequisites

**⚠️ Important:** This project requires Flutter beta due to the Riverpod dependency. Make sure you're using Flutter beta before proceeding.

### Installation

1. **Install Flutter**

   Follow the official Flutter installation guide for your platform:
   - [Install Flutter](https://docs.flutter.dev/get-started/install)
   
   After installation, verify Flutter is working:
   ```bash
   flutter doctor
   ```

2. **Switch to Flutter Beta**

   Since this project requires Flutter beta, switch to the beta channel:
   ```bash
   flutter channel beta
   flutter upgrade
   ```

3. **Clone this repository**

   ```bash
   git clone https://github.com/KenyaFlutterDev/flutter_ke.git
   cd flutter_ke/mobile
   ```

4. **Install dependencies and generate code**

   ```bash
   flutter pub get
   flutter pub run build_runner build
   ```

5. **Run the app**

   ```bash
   flutter run
   ```

### Additional Resources

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter documentation](https://docs.flutter.dev/)
