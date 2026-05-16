# Dockge App

[English](README_EN.md)

`Dockge App` 是一个给 [louislam/dockge](https://github.com/louislam/dockge) 用的 Flutter 手机客户端。

它不直接连接 Docker Engine，只连接你已经部署好的 Dockge，适合在手机上做这些事：

- 查看 stack 列表和状态
- 查看 stack 详情、服务状态和资源信息
- 启动、停止、重启、更新、删除 stack
- 编辑 `compose.yaml` 和 `.env`
- 查看实时日志
- 进入容器交互终端

## 环境要求

- Flutter 3.x
- Android SDK
- 如果要打 iOS 包，需要本机可用的 Xcode 环境
- 一台已经可访问的 Dockge 服务器

## 本地运行

```bash
flutter pub get
flutter run
```

## 构建 Android

调试包：

```bash
flutter build apk --debug
```

正式包：

```bash
flutter build apk --release
```

默认输出位置：

```text
build/app/outputs/flutter-apk/
```

## 构建 iOS

```bash
flutter build ios
```

## 说明

- 默认支持简体中文和英文
- 服务器信息和 token 会保存在本地
- 目前重点是 Android 端可用性，iOS 依赖本机打包环境
