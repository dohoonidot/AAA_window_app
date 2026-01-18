# AGENTS.md — dart-highlighting-main (Vendor Package)

## OVERVIEW
- **Syntax highlighting engine (Vendor package).**
- This package provides the core syntax highlighting logic for the application.
- It is a Dart port of `highlight.js`, maintaining high fidelity with the original project's language definitions.
- Acts as a foundational layer for the application's code viewing capabilities.

## DIRECTORY STRUCTURE
- `highlighting/`: Core Dart implementation of the highlighting engine.
- `flutter_highlighting/`: Flutter-specific widgets and themes for displaying highlighted code.
- `tool/`: The porting toolchain (TypeScript/Gulp) used to ingest `highlight.js` definitions.
- `gradle/`: Build wrapper and configuration for polyglot execution.

## BUILD
- **Polyglot Build Environment**: Requires more than just standard Flutter/Dart tools.
- **Gradle**: Uses Gradle for build orchestration (`build.gradle.kts`).
- **NPM/Node.js**: The `tool/` directory contains TypeScript-based generator logic.
  - Requires `npm install` and `npm start` (which runs `gulp`).
  - This process generates Dart language files from `highlight.js` sources.
- **Dart**: standard `pub get` is required in `highlighting/` and `flutter_highlighting/`.
- **Warning**: Do not attempt to run this build without Node.js and Java (for Gradle) installed.

## TESTING
- **Active Tests**: This package maintains its own suite of tests.
- **Location**: Primary tests are found in `highlighting/test/`.
- **Command**: Run `flutter test` within the `highlighting/` directory to verify core logic.
- **Golden Tests**: Some tests compare rendered output against known "golden" files.

## WARNING (STRICT BOUNDARIES)
- **Treat as 3rd-party/vendor code**: This is not a primary application feature; it is a specialized library.
- **Minimize changes**: Avoid any refactoring, styling changes, or logic modifications within this directory.
- **No Direct Modification**: Do not manually edit the generated language files in `highlighting/lib/languages/`. These should only be updated by running the generator tool.
- **Sync with Upstream**: Any essential changes must be carefully evaluated to ensure they don't break compatibility with the `highlight.js` porting logic.
- **Dependency Status**: Consider this a "black box" dependency. If you find a bug, prefer reporting it or fixing it in the generator tool rather than patching the Dart output.
- **Code Style**: This sub-project may follow different linting rules than the main app. Respect local `analysis_options.yaml`.
- **Fragility**: Highlighting logic is highly sensitive to regex changes. Modification risks breaking syntax support for multiple languages.
