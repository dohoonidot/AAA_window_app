# Core Infrastructure Guide

## OVERVIEW
The `lib/core` directory houses the foundational infrastructure of the application, including local data persistence, global configuration, and reusable functional mixins. These components provide a stable base for the feature-specific modules.

- **Database**: Managed by `DatabaseHelper` using SQLite for robust local storage.
- **Config**: Application-wide settings and environment management via `AppConfig`.
- **Mixins**: Base functional extensions like `TextEditingControllerMixin` and `FileAttachmentMixin` to reduce boilerplate in UI components.

## DATABASE
Local persistence is implemented using the **Singleton pattern** in `DatabaseHelper`. It leverages `sqflite` (with FFI for desktop support) to manage SQLite databases across multiple platforms.

### Key Patterns & Implementation:
- **Singleton Access**: Use `DatabaseHelper()` to access the global instance, ensuring a single connection point to the SQLite file.
- **Path Resolution**: Employs a tiered search strategy for DB initialization, attempting the Documents folder first, then falling back to the executable directory or temporary folders.
- **Raw SQL + Helper Methods**: Combines high-level CRUD methods (e.g., `saveLoginInfo`, `createArchive`) with raw SQL queries for optimized complex operations and data migrations.
- **Schema Management**: 
    - **Migrations**: Handles incremental versioning (currently up to v9) through the `_onUpgrade` callback.
    - **Integrity**: Enforces data consistency with foreign keys enabled via `PRAGMA foreign_keys = ON` in `_onConfigure`.
- **Synchronization**: Implements sophisticated logic for syncing local archives with server-side data using serial ID comparisons (`syncArchivesBySerialGap`) and detailed chat history fetching.

## CONFIG
The `AppConfig` class provides a centralized mechanism for environment-specific configuration and application-wide constants.

### Environment Switching:
- **Build Toggle**: Controlled by the `isOfficialRelease` static constant.
- **Dynamic Endpoints**: The `baseUrl` getter automatically switches between production (`:8080`) and development (`:8060`) ports based on the build type.
- **Modular Configs**: Supported by domain-specific configuration files:
    - `FeatureConfig`: Manages UI-level feature flags and experimental toggles.
    - `GiftConfig`: Defines parameters for the gift-related subsystems.
    - `MessageQConfig`: Configures RabbitMQ/AMQP connection parameters for real-time messaging.

## MIXINS
- **TextEditingControllerMixin**: Standardizes the lifecycle management (initialization and disposal) of `TextEditingController` instances within stateful widgets.
- **FileAttachmentMixin**: Encapsulates common logic for file selection, validation, and attachment handling across different chat features.
