A patching script built to remove the forced fullscreen ads
from the "Tower War" game, though in theory it could work
for many (un-minified) Android games.

## Prerequisites

- [Dart](https://dart.dev/get-dart) (or [Flutter](https://flutter.dev/docs/get-started/install))
- [Apktool](https://apktool.org/docs/install)
- platform-tools and build-tools (i.e. from Android Studio) in your PATH

## Usage

1. Clone this repo.
2. Download the unpatched APK from a website like [apkcombo](https://apkcombo.com/tower-war-tactical-conquest/games.vaveda.militaryoverturn/download/apk) into the repo directory and rename it to `original.apk`.
3. Run `dart run` in a terminal.
4. You should get a `patched.apk` file in the repo directory.
