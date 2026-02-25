# Chatbox AI

<div align="center">
  <img src="assets/images/logo.png" alt="Chatbox AI Logo" width="120" height="120">
  
  **跨平台 AI 聊天应用**
  
  支持 OpenAI、Anthropic、OpenRouter、Google Gemini 等多种 AI 提供商
</div>

---

## 功能特性

- 🤖 **多 AI 提供商支持** - OpenAI、Anthropic、OpenRouter、Google Gemini 等
- 💬 **流式响应** - 实时显示 AI 回复，支持中断生成
- 📱 **跨平台** - 支持 iOS、Android、Windows 三端
- 🌙 **深色模式** - 自动跟随系统主题
- 💾 **本地存储** - 聊天记录本地保存，保护隐私
- ⭐ **会话管理** - 收藏、重命名、删除会话
- 🎨 **Markdown 渲染** - 支持代码高亮和富文本显示
- ⚙️ **灵活配置** - 自定义 API 地址、模型参数等

## 平台支持

| 平台 | 状态 | 说明 |
|------|------|------|
| iOS | ✅ 支持 | 需要 macOS + Xcode |
| Android | ✅ 支持 | 需要 Android Studio |
| Windows | ✅ 支持 | 需要 Visual Studio |

## 快速开始

### 环境要求

- Flutter SDK 3.5.0+
- Dart SDK 3.5.0+
- Android Studio / Xcode / Visual Studio（根据目标平台）

### 安装步骤

```bash
# 克隆项目
git clone https://github.com/UnkownWorld/testfor4.git
cd testfor4

# 安装依赖
flutter pub get

# 运行项目
flutter run
```

### iOS 打包

详细的 iOS 打包和分发指南请参考：[IOS_BUILD_GUIDE.md](./IOS_BUILD_GUIDE.md)

快速命令：
```bash
# 安装 iOS 依赖
cd ios && pod install && cd ..

# 构建 iOS release 版本
flutter build ios --release

# 构建 IPA 文件
flutter build ipa --release
```

### Android 打包

```bash
# 构建 APK
flutter build apk --release

# 构建 App Bundle (用于 Google Play)
flutter build appbundle --release
```

### Windows 打包

```bash
# 构建 Windows 版本
flutter build windows --release
```

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── models/                   # 数据模型
│   ├── session.dart          # 会话模型
│   ├── message.dart          # 消息模型
│   └── provider_settings.dart # 提供商配置模型
├── providers/                # 状态管理
│   └── chat_provider.dart    # 聊天状态管理
├── screens/                  # UI 界面
│   ├── main_screen.dart      # 主页面（会话列表）
│   ├── chat_screen.dart      # 聊天界面
│   ├── settings_screen.dart  # 设置页面
│   └── new_chat_dialog.dart  # 新建会话对话框
└── services/                 # 服务层
    ├── api_service.dart      # API 调用服务
    └── database_service.dart # 数据库服务
```

## 配置说明

### 添加 AI 提供商

1. 打开应用，点击右上角设置图标
2. 选择要配置的提供商
3. 输入 API Key 和可选的 API 地址
4. 保存配置

### 支持的提供商

| 提供商 | 默认 API 地址 | 说明 |
|--------|---------------|------|
| OpenAI | https://api.openai.com | GPT-4, GPT-3.5 |
| Anthropic | https://api.anthropic.com | Claude 系列 |
| OpenRouter | https://openrouter.ai/api | 多模型聚合 |
| Google Gemini | https://generativelanguage.googleapis.com | Gemini 系列 |

## 技术栈

- **框架**: Flutter 3.5+
- **语言**: Dart
- **状态管理**: Provider
- **数据库**: SQLite (sqflite)
- **网络请求**: Dio
- **Markdown**: flutter_markdown

## 开发指南

### 代码规范

```bash
# 分析代码
flutter analyze

# 格式化代码
dart format .
```

### 运行测试

```bash
flutter test
```

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

---

<div align="center">
  Made with ❤️ by Chatbox Team
</div>
