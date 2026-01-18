# AGENTS.md — ASPN AI Agent Repository Guide

## OVERVIEW
ASPN AI Agent (AAA) is a high-performance Flutter desktop application for Windows, Linux, and macOS. It serves as a centralized hub for AI-powered corporate services including SAP assistance, electronic approvals, leave management, and real-time AI chatting. 

The project prioritizes a "Windows-native" feel using Fluent UI and integrates deeply with the host OS (Auto-startup, WinSparkle updates, SQLite FFI). It is designed to be a lightweight yet powerful assistant for enterprise workflows.

## STRUCTURE
```text
lib/
├── core/             # Infrastructure & Core Logic
│   └── database/     # DatabaseHelper (SQLite FFI, Migrations, Repair)
├── features/         # Feature-specific Modules (Domain Logic)
│   ├── approval/     # Electronic approval flows & HTML rendering logic
│   ├── auth/         # Authentication, Token management, Privacy compliance
│   ├── chat/         # AI Chat v3 implementation & attachment handling
│   ├── gift/         # Corporate events (Birthday/Gift notifications)
│   ├── leave/        # Leave management system (Calendar/Charts/Recommendations)
│   └── sap/          # SAP module specific messaging & integration logic
├── models/           # Shared data entities and JSON models
├── shared/           # Cross-cutting concerns
│   ├── providers/    # Global State (Riverpod: Theme, Notifications, UserID)
│   ├── services/     # API Client, AMQP (Real-time Syncing), Logging
│   └── utils/        # Versioning, Desktop helpers, String Formatters
└── ui/               # Global UI Definitions
    ├── screens/      # Base screens like LoginPage
    ├── theme/        # App-wide theme configuration (Fluent UI + Material)
    └── widgets/      # Shared UI components across features
packages/             # Internal local packages (highlighting, charts, etc.)
test/                 # Automated tests (widget_test.dart, unit tests)
```

## COMMANDS
- **Dependencies**: `flutter pub get` (Updates all packages including local ones)
- **Run Debug**: `flutter run -d windows` (Standard development loop)
- **Clean Project**: `flutter clean && flutter pub get` (Fixes sync issues)
- **Build Windows**: `flutter build windows --release` (Generates .exe in build folder)
- **Environment Fix**: `powershell -ExecutionPolicy Bypass -File .\fix_nuget.ps1` (Run as Admin)
- **Asset Generation**: `dart run flutter_launcher_icons` (Updates app icons)
- **Installer Creation**: Use Inno Setup compiler with `installer.iss` script
- **Static Analysis**: `flutter analyze` (Check for linting errors and type safety)
- **Code Formatting**: `dart format .` (Apply standard Dart formatting)
- **Testing**: `flutter test` (Runs all unit and widget tests)

## KEY PATTERNS
- **State Management**: **Riverpod** (v2+) is the standard.
  - Use `StateNotifierProvider` for logic-heavy states (e.g., `ChatNotifier`, `LeaveNotifier`).
  - Use `ConsumerWidget` or `ConsumerState` to access `WidgetRef` for reactive UI.
  - Prefer `ref.watch` for dependencies and `ref.read` for event handlers.
- **Persistence**: **SQLite** via `sqflite_common_ffi` and `sqlite3_flutter_libs`.
  - **DatabaseHelper**: Centralized singleton for all DB I/O and transaction management.
  - **Migrations**: Versioned logic in `_onUpgrade`. Always increment `version` in `openDatabase`.
  - **Repair**: `_repairDatabaseIfNeeded()` in `main.dart` ensures schema integrity for existing users.
- **UI Architecture**: Hybrid approach using `fluent_ui` for Windows-native UX and `Material` for standard components.
- **Real-time**: `AmqpService` handles background notifications and message syncing via AMQP protocol.
- **Dependency Injection**: Handled via Riverpod providers to ensure testability and isolation.

## ANTI-PATTERNS
- **PII Security**: **NEVER** use `print()` for User IDs, Passwords, Hashes, or Tokens. Use `AmqpLogger` or structured debug logs.
- **Context Safety**: **NEVER** use `BuildContext` after `await` boundaries. Always check `mounted` or use `ref.read` where appropriate.
- **Main Thread**: **NEVER** perform heavy JSON parsing or large SQL queries on the main thread. Use `compute()` for heavy tasks.
- **Direct SQL**: **NEVER** write raw SQL inside UI files. Encapsulate all persistence logic within `DatabaseHelper`.
- **Global Variables**: Avoid global mutable state. Use Riverpod providers for all app-wide state.

## CRITICAL WORKFLOWS
- **Environment Prep**: New developer setups must run `fix_nuget.ps1` as Administrator to configure the Windows build environment (PATH and nuget.exe).
- **Release Flow**: 
  1. Increment version in `pubspec.yaml` (e.g., 1.4.0 -> 1.4.1).
  2. Run `flutter build windows` to generate release binaries.
  3. Compile `installer.iss` to generate the `.exe` setup package.
  4. Update `appcast.xml` for `auto_updater` to trigger client-side updates.
- **DB Migration**: Schema changes require a version bump in `DatabaseHelper` and a corresponding logic block in `_onUpgrade`.
- **AMQP Syncing**: Ensure `amqpService.connect(userId)` is called after successful login to start real-time updates.

## HOW TO ADD NEW FEATURES
1. **Define Feature Folder**: Create a new directory in `lib/features/<feature_name>`.
2. **Setup State**: Create a `provider` or `notifier` in the feature folder or `lib/shared/providers`.
3. **Implement UI**: Use `ConsumerWidget` and follow the `fluent_ui` design patterns.
4. **Data Persistence**: Add necessary tables/methods to `DatabaseHelper.dart` and handle migrations.
5. **Real-time Integration**: Register any new AMQP message types in `AmqpService`.

## KEY RISKS & MITIGATION
- **Async Gap Crashes**: Frequent usage of `Navigator` or `context` after async calls is the primary crash vector. Mitigation: Use `navigatorKey` or `ref.mounted` checks.
- **UI Performance**: Heavy charts (`fl_chart`) or massive markdown rendering can cause stuttering. Mitigation: Use `ListView.builder` and avoid unnecessary widget rebuilds.
- **DB Corruption**: SQLite files in Documents can be locked by other processes. Mitigation: `DatabaseHelper` implements multi-path fallback (Documents -> Executable Dir -> Temp).
- **Memory Leaks**: Improper disposal of `StreamSubscription` or `Timer`. Mitigation: Always cancel subscriptions in `dispose()` or use `ref.listen`.
