# real-time-fund (Flutter)

A cross-platform real-time fund tracking application built with Flutter. It helps you track your fund holdings, calculate profits in real-time, and synchronize data across devices using Supabase.

This project is a Flutter rewrite of the original [real-time-fund](https://github.com/inannan/real-time-fund) extension/app, bringing native performance and multi-platform support (iOS, Android, macOS, Web).

## ✨ Features

- **Real-time Data**: Fetches real-time fund valuation and NAV from EastMoney and Tencent.
- **Holdings Management**: Track your cost, shares, and calculate daily/total profit automatically.
- **Cloud Synchronization**: Sync your data (funds, holdings, groups) across devices using Supabase.
- **Group Management**: Organize funds into custom groups for better tracking.
- **Privacy Mode**: Hide sensitive amount information with a single tap.
- **Detailed Insights**: View fund details, including top stock holdings and their daily performance.
- **Cross-Platform**: Runs smoothly on iOS, Android, macOS, and Web.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Backend / Sync**: [Supabase](https://supabase.com/)
- **Networking**: `http`, `fast_gbk` (for handling legacy encoding)
- **Storage**: `shared_preferences` (local), Supabase (cloud)
- **UI**: Material Design 3 with custom dark theme optimization

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- A [Supabase](https://supabase.com/) project (free tier is sufficient).

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/real-time-fund-flutter.git
   cd real-time-fund-flutter
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configuration**
   
   This project uses Supabase for authentication and data sync. You need to provide your own Supabase credentials.

   Open `lib/config.dart` and update the following fields:

   ```dart
   class Config {
     static const String supabaseUrl = 'YOUR_SUPABASE_URL';
     static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   }
   ```
   
   *Note: Ensure you have enabled Email/Password authentication in your Supabase project settings.*

4. **Run the App**

   ```bash
   # Run on macOS
   flutter run -d macos

   # Run on Chrome
   flutter run -d chrome
   ```

## 📱 Screenshots

<img src="assets/screenshots/1.png" width="300" alt="App Screenshot" />

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgements

- Original Project: [real-time-fund](https://github.com/inannan/real-time-fund)
- Data Sources: EastMoney, Tencent Finance

## ☕ Support

If you find this project helpful, you can buy me a coffee!

| WeChat Pay | Alipay |
|------------|--------|
| <img src="assets/weixin.png" width="200" /> | <img src="assets/zhifubao.png" width="200" /> |
