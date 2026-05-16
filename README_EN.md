# Dockge App

[中文](README.md)

`Dockge App` is a Flutter mobile client for [louislam/dockge](https://github.com/louislam/dockge).

It does not talk to Docker Engine directly. The app connects to an existing Dockge server and lets you manage stacks from your phone.

Main functions:

- Browse stacks and their status
- View stack details, services, and basic stats
- Start, stop, restart, update, and delete stacks
- Edit `compose.yaml` and `.env`
- View live logs
- Open an interactive container terminal

## Requirements

- Flutter 3.x
- Android SDK
- Xcode if you want to build for iOS
- A reachable Dockge server

## Run locally

```bash
flutter pub get
flutter run
```

## Build for Android

Debug APK:

```bash
flutter build apk --debug
```

Release APK:

```bash
flutter build apk --release
```

Default output:

```text
build/app/outputs/flutter-apk/
```

## Build for iOS

```bash
flutter build ios
```

## Notes

- The app supports English and Simplified Chinese
- Server profile and token are stored locally
- Android is the main delivery target right now
