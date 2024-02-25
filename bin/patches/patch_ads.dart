import 'dart:io';

Future<void> patchAds(List<File> smaliFiles) async {
  await Future.wait(smaliFiles.map(_patchAdMethods));
}

/// Removes the method bodies of known ad methods that return void.
Future<void> _patchAdMethods(File file) async {
  final lines = await file.readAsLines();

  bool changed = false;

  /// The body start line number of the current method to patch
  int? bodyStart;

  line_loop:
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];

    if (line.isEmpty || line[0] != '.') continue;

    if (line.startsWith('.method public')) {
      bodyStart = null;

      // Method must return void
      if (!line.endsWith(')V')) continue;

      for (final voidMethod in _voidMethods) {
        if (!line.contains(' $voidMethod(')) continue;

        bodyStart = i + 1;
        continue line_loop;
      }
    }

    if (bodyStart != null && line == '.end method') {
      const replacement = [
        '    .locals 0',
        '    ',
        '    return-void',
      ];

      changed = true;
      lines.removeRange(bodyStart, i);
      lines.insertAll(bodyStart, replacement);

      i = bodyStart + replacement.length + 1;
      bodyStart = null;
      continue line_loop;
    }
  }

  if (!changed) return;

  print('Patched ${file.path}');
  await file.writeAsString(lines.join('\n'));
}

/// Known methods we want to remove that return void
const _voidMethods = [
  'loadInterstitialAd',
  'loadRewardedAd',
  'loadRewardedVideo',
  'showInterstitialAd',
  'showInterstitial',
  'showRewardedAd',
  'showRewardedVideo',
  'grantGdprConsent',
];
