import 'dart:io';

Future<void> patchAndroidManifest() async {
  final file = File('original/AndroidManifest.xml');
  final lines = await file.readAsLines();
  bool changed = false;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];

    if (line.contains('<meta-data android:name="unity.splash-enable"')) {
      print('Patching unity.splash-enable in $file...');
      lines[i] = line.replaceFirst('true', 'false');
      changed = true;
      continue;
    }

    lines[i] = line
        .replaceAll(
            'android:isSplitRequired="true"', 'android:isSplitRequired="false"')
        .replaceAll(RegExp('android:requiredSplitTypes="[^"]*"'), '')
        .replaceAll(RegExp('android:splitTypes="[^"]*"'), '');
    if (lines[i] != line) {
      print('Patched leftover split apk metadata in $file...');
      changed = true;
      continue;
    }
  }

  if (!changed) return;
  await file.writeAsString(lines.join('\n'));
}
