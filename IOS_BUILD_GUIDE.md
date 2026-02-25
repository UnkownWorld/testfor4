# iOS 打包指南

本文档介绍如何在 macOS 上打包 Chatbox AI iOS 应用进行测试分发。

## 环境要求

### 必需软件
- **macOS** 12.0 或更高版本
- **Xcode** 15.0 或更高版本
- **Flutter SDK** 3.5.0 或更高版本
- **CocoaPods** (通常随 Flutter 自动安装)

### Apple 开发者账号
- 免费账号：可用于个人测试（7天有效期）
- 付费账号 ($99/年)：可用于 TestFlight 和 App Store 分发

## 第一步：安装 Flutter

```bash
# 下载 Flutter SDK
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable

# 添加到 PATH (添加到 ~/.zshrc 或 ~/.bash_profile)
export PATH="$PATH:$HOME/development/flutter/bin"

# 验证安装
flutter doctor
```

## 第二步：配置 Xcode

1. 从 App Store 安装 Xcode
2. 打开 Xcode，接受许可协议
3. 安装命令行工具：
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

## 第三步：获取项目代码

```bash
# 克隆项目
git clone https://github.com/UnkownWorld/testfor4.git chatbox_flutter
cd chatbox_flutter

# 安装依赖
flutter pub get

# 生成 iOS 项目文件
cd ios
pod install
cd ..
```

## 第四步：配置签名

### 方法一：自动签名（推荐）

1. 打开 Xcode：
```bash
open ios/Runner.xcworkspace
```

2. 在 Xcode 中：
   - 选择左侧的 "Runner" 项目
   - 选择 "Signing & Capabilities" 标签
   - 勾选 "Automatically manage signing"
   - 选择你的 Team（需要登录 Apple ID）
   - 修改 Bundle Identifier（如：`com.yourname.chatbox`）

### 方法二：手动配置

在 `ios/Runner.xcodeproj/project.pbxproj` 中修改：
```
PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.chatbox;
DEVELOPMENT_TEAM = YOUR_TEAM_ID;
```

## 第五步：构建 iOS 应用

### 开发版本（用于真机调试）

```bash
# 连接 iPhone 设备
flutter devices

# 运行到设备
flutter run

# 或者指定设备
flutter run -d <device_id>
```

### 发布版本（用于分发）

```bash
# 构建 release 版本
flutter build ios --release

# 或构建 ipa 文件
flutter build ipa --release
```

## 第六步：测试分发

### 方法一：TestFlight（推荐，需要付费开发者账号）

1. 在 Xcode 中上传到 App Store Connect：
```bash
# 打开 Xcode
open ios/Runner.xcworkspace

# Product -> Archive
# 然后点击 "Distribute App" -> "App Store Connect"
```

2. 在 App Store Connect 中配置 TestFlight：
   - 登录 https://appstoreconnect.apple.com
   - 选择应用 -> TestFlight
   - 添加内部/外部测试员
   - 分发构建版本

### 方法二：Ad Hoc 分发（需要付费开发者账号）

1. 在 Apple Developer 网站注册测试设备 UDID
2. 创建 Ad Hoc 配置文件
3. 在 Xcode 中构建：
```bash
flutter build ipa --export-options-plist=ExportOptions.plist
```

ExportOptions.plist 示例：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>ad-hoc</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
```

### 方法三：Xcode 直接安装（免费账号）

1. 连接 iPhone 到 Mac
2. 在 Xcode 中打开项目
3. 选择你的设备作为目标
4. 点击运行按钮
5. 首次运行需要在 iPhone 上信任开发者：
   - 设置 -> 通用 -> VPN与设备管理 -> 信任开发者

### 方法四：第三方分发平台

可以使用以下平台分发 IPA：
- **蒲公英** (https://www.pgyer.com)
- **fir.im** (https://fir.im)
- **Diawi** (https://www.diawi.com)

上传 IPA 后生成下载链接，测试人员可通过链接安装。

## 常见问题

### 1. 签名错误
```
No signing certificate "iOS Development" found
```
**解决方案**：在 Xcode 中登录 Apple ID 并创建签名证书

### 2. 设备未识别
```
No devices detected
```
**解决方案**：
- 信任此电脑（在 iPhone 上点击"信任"）
- 安装 Xcode 命令行工具
- 重启设备

### 3. Pod 安装失败
```
[!] CocoaPods could not find compatible versions for pod...
```
**解决方案**：
```bash
cd ios
pod deintegrate
pod install --repo-update
```

### 4. Bundle ID 冲突
**解决方案**：修改 `ios/Runner.xcodeproj/project.pbxproj` 中的 `PRODUCT_BUNDLE_IDENTIFIER`

## 项目配置说明

### 修改应用名称
编辑 `ios/Runner/Info.plist`：
```xml
<key>CFBundleDisplayName</key>
<string>你的应用名</string>
```

### 修改版本号
编辑 `pubspec.yaml`：
```yaml
version: 1.0.0+1
# 格式：version: [版本名]+[构建号]
```

### 添加权限
编辑 `ios/Runner/Info.plist`，添加所需权限：
```xml
<!-- 网络权限 -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>

<!-- 相册权限（如需要） -->
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册以保存图片</string>
```

## 快速命令参考

```bash
# 检查环境
flutter doctor

# 查看设备
flutter devices

# 清理构建
flutter clean

# 获取依赖
flutter pub get

# 运行调试版本
flutter run

# 构建 iOS release
flutter build ios --release

# 构建 IPA
flutter build ipa --release

# 打开 Xcode
open ios/Runner.xcworkspace
```

## 联系支持

如有问题，请访问：
- Flutter 官方文档：https://docs.flutter.dev/deployment/ios
- Apple 开发者文档：https://developer.apple.com/documentation/
