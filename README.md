A patching script built to remove the forced fullscreen ads
from the "Tower War" game, though in theory it could work
for many (un-minified) Android games.

## Prerequisites

- [Dart](https://dart.dev/get-dart) (or [Flutter](https://flutter.dev/docs/get-started/install))
- [Apktool](https://apktool.org/docs/install)
- platform-tools and build-tools (i.e. from Android Studio) in your PATH

## Usage

1. Clone this repo.
2. Download the unpatched apk (or xapk) from a website like [APKPure](https://apkpure.com/tower-war-tactical-conquest/games.vaveda.militaryoverturn) into the repo directory and rename it to `original.apk` (or `original.xapk`).
3. Run `dart pub get` in a terminal.
4. Run `dart run` in a terminal.
5. Install `patched.apk` on your Android device.
