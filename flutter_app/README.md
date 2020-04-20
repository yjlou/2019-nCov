# covid19

Notify you if you have potential contact with COVID-19 patient.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


## Update Icon
- Copy the new icon to `assets/icon/icon.png`
- ~~`flutter pub get`~~
- ~~`flutter pub run flutter_launcher_icons:main`~~
- In Android Studio, right click on "android" folder > New > Image Asset
  - Name: "ic_launcher"
  - Foreground layer:
    - Path: "/path/to/assets/icon/icon.png"
  - Background layer:
    - Use white color

## iOS
- Run `flutter build ios --debug --simulator` once, then you should be able to
    build with Xcode
- Open `ios/Runner.xcodeproj/project.pbxproj` with Xcode
