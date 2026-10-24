# KidBook

把熟悉的声音，变成孩子的小小有声书库。Flutter 实现，依据 Pixso 的 18 个参考画面制作，保留原稿插画、深蓝文字、绿色按钮、粉色播放控件与圆角卡片。

[项目架构、主要界面与运行说明](docs/项目说明.md) · [所有界面截图](docs/界面截图.md) · [设计节点映射](docs/design-map.json)

## 快速运行

需要 Flutter 3.41.6 / Dart 3.11.4 或兼容版本。

```sh
flutter pub get
flutter run -d chrome
# 或连接 Android 设备
flutter run -d <device-id>
```

初次启动可创建第一本书，也可点击 **Explore sample library** 导入 6 本带真实试听音频的示例书。每次录音形成一页；可改名、删除、长按排序，再保存为书籍。播放列表支持多本书连续播放。

```sh
flutter analyze
flutter test
flutter build apk --release --target-platform android-arm64
flutter build web --release
```

浏览器流程验证与截图重建：

```sh
node tool/serve.cjs
# 另一个终端
npm install --prefix tool
node tool/browser_smoke.cjs
```

默认使用本机 Google Chrome。其他系统设置 `CHROME_PATH`，其他服务地址设置 `KIDBOOK_URL`。

原生端将录音保存在应用文档目录；Web 端将录音编码后写入浏览器本地存储，适合短录音。照片、录音和书库均在本机，不需要服务器。浏览器录音需 localhost 或 HTTPS。
