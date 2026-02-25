# Android APK 构建指南

本文档介绍如何构建 Chatbox AI Android APK。

## 环境要求

### 必需软件
- **Flutter SDK** 3.5.0 或更高版本
- **Android SDK** (API 34)
- **JDK** 17 或 21（完整 JDK，包含 jlink）
- **Android Studio**（可选，但推荐）

## 快速开始

### 1. 安装 Flutter

```bash
# macOS/Linux
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Windows
# 从 https://docs.flutter.dev/get-started/install 下载安装包

# 验证安装
flutter doctor
```

### 2. 安装 Android SDK

#### 方法一：通过 Android Studio（推荐）
1. 下载并安装 [Android Studio](https://developer.android.com/studio)
2. 打开 Android Studio -> More Actions -> SDK Manager
3. 安装 SDK Platform 34 和 Build Tools 34.0.0

#### 方法二：命令行安装
```bash
# 下载 Android SDK Command Line Tools
mkdir -p ~/android-sdk/cmdline-tools
cd ~/android-sdk/cmdline-tools
curl -O https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip commandlinetools-linux-*.zip

# 设置环境变量
export ANDROID_HOME=~/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin

# 接受许可证
yes | sdkmanager --licenses

# 安装必要组件
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

### 3. 安装 JDK

```bash
# Ubuntu/Debian
sudo apt install openjdk-17-jdk

# macOS
brew install openjdk@17

# 验证安装
java -version
# 确保 jlink 可用
jlink --version
```

## 构建步骤

### 获取项目代码

```bash
git clone https://github.com/UnkownWorld/testfor4.git
cd testfor4
```

### 安装依赖

```bash
flutter pub get
```

### 构建 APK

#### Debug 版本（用于测试）
```bash
flutter build apk --debug
```
输出位置：`build/app/outputs/flutter-apk/app-debug.apk`

#### Release 版本（用于分发）
```bash
flutter build apk --release
```
输出位置：`build/app/outputs/flutter-apk/app-release.apk`

#### 分架构 APK（更小的体积）
```bash
flutter build apk --split-per-abi --release
```
输出：
- `app-armeabi-v7a-release.apk` - 32位 ARM
- `app-arm64-v8a-release.apk` - 64位 ARM（推荐）
- `app-x86_64-release.apk` - x86 模拟器

### 构建 App Bundle（用于 Google Play）
```bash
flutter build appbundle --release
```
输出位置：`build/app/outputs/bundle/release/app-release.aab`

## 签名配置

### 创建签名密钥

```bash
keytool -genkey -v -keystore chatbox-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias chatbox
```

### 配置签名

创建 `android/key.properties`：
```properties
storePassword=你的密码
keyPassword=你的密码
keyAlias=chatbox
storeFile=../chatbox-release.jks
```

修改 `android/app/build.gradle`：
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

## 常见问题

### 1. Kotlin 版本不兼容
```
Your project requires a newer version of the Kotlin Gradle plugin.
```
**解决方案**：更新 `android/settings.gradle` 中的 Kotlin 版本：
```gradle
id "org.jetbrains.kotlin.android" version "1.9.22" apply false
```

### 2. jlink 不存在
```
jlink executable does not exist
```
**解决方案**：安装完整的 JDK（不是 JRE）：
```bash
# Ubuntu/Debian
sudo apt install openjdk-17-jdk

# 验证
which jlink
```

### 3. Gradle 缓存损坏
```
No such file or directory (AAR files)
```
**解决方案**：清理 Gradle 缓存：
```bash
rm -rf ~/.gradle/caches
flutter clean
flutter pub get
flutter build apk
```

### 4. Android SDK 未找到
```
Android SDK not found
```
**解决方案**：设置环境变量：
```bash
export ANDROID_HOME=~/android-sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

### 5. 网络问题（中国用户）
如果下载依赖缓慢，可以配置镜像：

`android/build.gradle`：
```gradle
allprojects {
    repositories {
        maven { url 'https://maven.aliyun.com/repository/google' }
        maven { url 'https://maven.aliyun.com/repository/public' }
        google()
        mavenCentral()
    }
}
```

## 分发方式

### 直接安装
将 APK 文件传输到 Android 设备，点击安装即可。

### 第三方分发平台
- **蒲公英**: https://www.pgyer.com
- **fir.im**: https://fir.im
- **Diawi**: https://www.diawi.com

### Google Play
使用 App Bundle (.aab) 格式上传。

## 快速命令参考

```bash
# 检查环境
flutter doctor -v

# 清理项目
flutter clean

# 获取依赖
flutter pub get

# 运行调试版本
flutter run

# 构建 Debug APK
flutter build apk --debug

# 构建 Release APK
flutter build apk --release

# 构建分架构 APK
flutter build apk --split-per-abi --release

# 构建 App Bundle
flutter build appbundle --release

# 查看连接设备
flutter devices

# 运行到指定设备
flutter run -d <device_id>
```

## 联系支持

如有问题，请访问：
- Flutter 官方文档：https://docs.flutter.dev/deployment/android
- Android 开发者文档：https://developer.android.com/studio/build
