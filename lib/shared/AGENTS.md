# Shared Module — Repository Guide

## OVERVIEW
"Central hub for cross-cutting concerns." This directory contains the infrastructure, state management, and reusable UI components that power the ASPN AI Agent. By centralizing these resources, we ensure consistency across different features and minimize code duplication.

## CATALOG

### Services
- **Networking (`ApiService`)**
  - Handles all RESTful communication with the backend.
  - Manages Archive CRUD (Create, Read, Update, Delete) operations.
  - Provides methods for synchronization between local SQLite and remote DB.
  - Path: `lib/shared/services/api_service.dart`

- **Real-time (`AmqpService`)**
  - Manages persistent RabbitMQ connections for low-latency notifications.
  - Subscribes to user-specific queues for Birthday alerts, Gift events, and Approval requests.
  - Implements robust reconnection logic and health checks.
  - Path: `lib/shared/services/amqp_service.dart`

### State Management
- **Global Session (`userIdProvider`)**
  - A `StateProvider<String?>` that tracks the logged-in user's identity.
  - Used as a dependency for almost all service-layer providers.
  - Path: `lib/shared/providers/providers.dart`

- **Chat State (`chatProvider`)**
  - Orchestrates complex conversation logic via `ChatNotifier`.
  - Manages message streaming, attachment state, and UI loading indicators.
  - Path: `lib/shared/providers/chat_notifier.dart`

### UI & Utilities
- **Shared Widgets (`Sidebar`)**
  - The main navigation drawer for conversation history and module switching.
  - Includes integrated search and archive management tools.
  - Path: `lib/shared/widgets/sidebar.dart`

- **Utils (`CommonUIUtils`)**
  - Standardized UI helpers for SnackBars (Success, Error, Info).
  - Common Dialogs for confirmations, deletions, and text input.
  - Ensures a unified Look & Feel for user feedback.
  - Path: `lib/shared/utils/common_ui_utils.dart`

## USAGE
"Check here before building new utilities."
- **Services**: Always use `ApiService` for standard HTTP calls instead of manual `http` requests.
- **State**: Reference `userIdProvider` to determine if a user session is active.
- **UI**: Use `CommonUIUtils` for any user-facing notifications to maintain theme consistency.
- **Widgets**: Reuse `Sidebar` and other shared widgets to keep the layout predictable for users.
