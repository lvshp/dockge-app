<p align="center">
  <h1 align="center">Dockge App</h1>
  <p align="center">
    <strong>English</strong> | <a href="#中文说明">中文</a>
  </p>
  <p align="center">
    A Flutter mobile client for <a href="https://github.com/louislam/dockge">louislam/dockge</a>
  </p>
  <p align="center">
    <img src="https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter" alt="Flutter" />
    <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green" alt="Platform" />
    <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License" />
  </p>
</p>

## Features

- **Dashboard** — View server status, stack statistics at a glance
- **Stack Management** — List, search, filter stacks; start / stop / restart / update / down / delete
- **Stack Detail** — Service status, image, ports, CPU & memory stats; service start / stop / restart
- **Compose Editor** — View and edit `docker-compose.yml` and `.env` files with envsubst variable substitution
- **Terminal / Logs** — View combined container logs via real-time terminal (xterm.js powered VT100 emulator)
- **Host Terminal** — Open a host console directly from the dashboard
- **Service Bash** — Open an interactive shell (`sh`) inside any container
- **Theme** — Light / Dark / System theme with Material 3 dynamic colors (teal seed)
- **Localization** — English & Chinese (official ARB + inline FeatureLocalizations)
- **Secure Storage** — Server credentials stored encrypted via `flutter_secure_storage`
- **Real-time** — Socket.IO based live updates for stack list, terminal output, and container stats

## Screenshots

> TODO: Add screenshots here

## Getting Started

### Prerequisites

- Flutter 3.x SDK
- Android SDK / Xcode (for iOS)
- A running [Dockge](https://github.com/louislam/dockge) server

### Install Dependencies

```bash
flutter pub get
```

### Run (Debug)

```bash
flutter run
```

### Build APK (Release)

```bash
flutter build apk
```

### Build iOS

```bash
flutter build ios
```

## Project Structure

```
lib/
  main.dart                         # Entry point
  src/
    app/                            # App shell (MaterialApp, router, theme, navigation)
    core/
      domain/                       # Pure Dart models (Stack, ServiceStatus, DockerStats, etc.)
      network/                      # Socket.IO client (DockgeSocketClient)
      session/                      # Riverpod Notifier (DockgeSessionController)
      storage/                      # Persistent storage facades (SecureStorage, Profile, Language)
      safety_policy.dart            # Operation safety levels (normal / caution / destructive)
    features/
      auth/                         # Login page
      dashboard/                    # Dashboard with stat cards
      stacks/                       # Stack list, detail, compose editor, logs
      settings/                     # Settings (language, theme, disconnect)
      terminal/                     # Host terminal & service bash terminal
      common/                       # Shared widgets & localizations
    l10n/                           # Official ARB localizations (en / zh)
    shared/                         # Global shared dialogs, chips, empty states
```

## Key Architecture Decisions

| Layer | Choice | Notes |
|---|---|---|
| State Management | Riverpod | `NotifierProvider` for session, `StreamProvider` for terminal events |
| Routing | go_router | `StatefulShellRoute.indexedStack` for bottom navigation |
| Real-time | Socket.IO | `DockgeSocketClient` wraps all Dockge server API |
| Storage | FlutterSecureStorage + SharedPreferencesAsync | Encrypted credentials; async language prefs |
| Terminal | xterm.dart | VT100 terminal emulator for logs & interactive shells |
| Theming | Material 3 | Teal seed color `#0EA5A3`, `ThemeExtension` for status colors |

## License

MIT License — see [LICENSE](LICENSE) for details.

---

<a id="中文说明"></a>

<p align="center">
  <h1 align="center">Dockge App</h1>
  <p align="center">
    <a href="#features">English</a> | <strong>中文</strong>
  </p>
  <p align="center">
    <a href="https://github.com/louislam/dockge">louislam/dockge</a> 的 Flutter 移动客户端
  </p>
</p>

## 功能

- **仪表盘** — 一览服务器状态和堆栈统计
- **堆栈管理** — 列表、搜索、筛选堆栈；启动 / 停止 / 重启 / 更新 / Down / 删除
- **堆栈详情** — 服务状态、镜像、端口、CPU 和内存统计；服务启动 / 停止 / 重启
- **Compose 编辑器** — 查看和编辑 `docker-compose.yml` 及 `.env` 文件，支持 envsubst 变量替换
- **终端 / 日志** — 通过实时终端查看容器组合日志（基于 xterm VT100 模拟器）
- **主机终端** — 从仪表盘直接打开宿主机控制台
- **容器 Bash** — 在任意容器内打开交互式 shell（`sh`）
- **主题** — 浅色 / 深色 / 跟随系统，Material 3 动态色彩（青绿种子色）
- **多语言** — 英文与中文（官方 ARB + 内联 FeatureLocalizations）
- **安全存储** — 服务器凭据通过 `flutter_secure_storage` 加密存储
- **实时通信** — 基于 Socket.IO 的堆栈列表、终端输出、容器统计实时更新

## 截图

> TODO: 在此添加截图

## 快速开始

### 前置要求

- Flutter 3.x SDK
- Android SDK / Xcode（iOS 构建）
- 运行中的 [Dockge](https://github.com/louislam/dockge) 服务器

### 安装依赖

```bash
flutter pub get
```

### 调试运行

```bash
flutter run
```

### 构建 Release APK

```bash
flutter build apk
```

### 构建 iOS

```bash
flutter build ios
```

## 项目结构

```
lib/
  main.dart                         # 入口
  src/
    app/                           # 应用壳（MaterialApp、路由、主题、导航）
    core/
      domain/                      # 纯 Dart 模型（Stack、ServiceStatus、DockerStats 等）
      network/                     # Socket.IO 客户端（DockgeSocketClient）
      session/                     # Riverpod Notifier（DockgeSessionController）
      storage/                     # 持久化存储门面（SecureStorage、Profile、Language）
      safety_policy.dart           # 操作安全级别（normal / caution / destructive）
    features/
      auth/                        # 登录页
      dashboard/                  # 仪表盘（统计卡片）
      stacks/                      # 堆栈列表、详情、Compose 编辑器、日志
      settings/                    # 设置（语言、主题、断开连接）
      terminal/                    # 主机终端 & 容器交互终端
      common/                      # 共享组件和本地化
    l10n/                          # 官方 ARB 本地化（en / zh）
    shared/                        # 全局共享对话框、状态芯片、空状态
```

## 核心架构

| 层 | 选型 | 说明 |
|---|---|---|
| 状态管理 | Riverpod | `NotifierProvider` 管理会话，`StreamProvider` 管理终端事件 |
| 路由 | go_router | `StatefulShellRoute.indexedStack` 实现底部导航 |
| 实时通信 | Socket.IO | `DockgeSocketClient` 封装全部 Dockge 服务器 API |
| 存储 | FlutterSecureStorage + SharedPreferencesAsync | 加密凭据；异步语言偏好 |
| 终端 | xterm.dart | VT100 终端模拟器，支持日志和交互式 Shell |
| 主题 | Material 3 | 青绿种子色 `#0EA5A3`，`ThemeExtension` 管理状态色 |

## 许可证

MIT License — 详见 [LICENSE](LICENSE)。