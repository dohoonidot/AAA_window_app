# lib/features/leave — Leave Management Module Guide

## OVERVIEW
Layered feature module for Leave Management. This module handles everything from leave balance tracking and history to advanced vacation recommendations and real-time approval notifications. 

The feature is designed to handle high-complexity enterprise workflows, including electronic approval integration and department-wide leave visibility. It prioritizes a clear separation between domain data, reactive state, and presentation layers to maintain scalability.

## STRUCTURE
- **`models/`**: Domain data entities and JSON serialization logic.
  - Examples: `VacationRecommendationModel`, `LeaveRequestHistory`, and `LeaveBalance`.
  - These models define the data structure used throughout the feature.
- **`providers/`**: Global and feature-scoped state management using Riverpod.
  - Examples: `VacationRecommendationProvider`, `LeaveNotificationProvider`, and `LeaveRequestHistoryNotifier`.
  - Providers manage the lifecycle of leave data and respond to user actions.
- **`services/`**: Specialized business logic and real-time synchronization.
  - Examples: `VacationRecommendationService` for logic and `LeaveRealtimeService` for AMQP-based updates.
- **`widgets/`**: Reusable UI components specifically designed for leave-related views.
  - Categories: Charts (`vacation_recommendation_charts`), Calendars (`vacation_recommendation_calendar_view`), and loading overlays.
- **Root Files**: Main entry points and complex UI orchestration.
  - Includes: `LeaveScreenController`, `LeaveRequestSidebar`, and specialized modals like `LeaveHistoryTableModal`.

## PATTERNS
- **Logic Separation**: 
  - **Data Fetching**: Use `LeaveApiService` (located in `shared/services/`) for standard backend REST communication.
  - **Business Logic**: Use local `services/` for complex client-side calculations or domain-specific logic like recommendation algorithms.
- **State Management**: 
  - `LeaveProviders` (and files in `providers/`) serve as the single source of truth for leave data across the feature.
  - UI components must listen to these providers via `ref.watch` to ensure reactive updates and avoid state mismatch.
- **UI Architecture**:
  - Keep domain-specific, leaf-node widgets organized in the `widgets/` directory.
  - Use Screens and Modals in the root directory as high-level orchestration layers that connect providers to widgets.

## ANTI-PATTERNS (DO NOT)
- **PII Security**: Never log sensitive user IDs, employee names, or leave details in plain text using `print()`. Use structured logging instead.
- **Mixed Concerns**: Do not mix UI rendering and API logic; always delegate data fetching to `LeaveApiService` and state management to Providers.
- **Heavy UI**: Avoid performing complex calculations (like vacation recommendation logic) inside the `build` method. Use the specialized `Services` and `compute()` where necessary.
- **Direct SQL**: Do not access the database directly; use the centralized `DatabaseHelper` if local persistence or caching is required for offline support.
- **Context Boundaries**: Avoid using `BuildContext` across asynchronous boundaries; prefer using `ref` or checking the `mounted` state before performing UI actions.
- **State Leakage**: Do not use global variables for feature state; always encapsulate state within Riverpod providers for testability and isolation.
