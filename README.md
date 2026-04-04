# coup_boardgame

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Playwright E2E

This repo includes a Playwright setup for the primary web flow:

- create room
- add bot
- start game

Install dependencies and Chromium:

```bash
npm install
npm run test:e2e:install
```

Make sure `fvm` is available in your `PATH` (or set `PLAYWRIGHT_FLUTTER_BIN=flutter` if you want to use a global Flutter SDK).

Run the tests:

```bash
npm run test:e2e
```

If you already run the Flutter web app yourself, you can point Playwright to it:

```bash
PLAYWRIGHT_BASE_URL=http://127.0.0.1:7357 npm run test:e2e
```

Playwright will start Flutter Web automatically with:

```bash
fvm flutter run -d web-server --dart-define=ENABLE_E2E_TAGS=true
```
