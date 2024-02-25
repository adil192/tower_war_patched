import 'dart:io';

import 'method_bodies.dart';

Future<void> patchFile(File file) async {
  final lines = await file.readAsLines();

  bool changed = false;

  /// The body start line number of the current method to patch
  int? bodyStart;

  /// The target method body with which to replace the original
  List<String> replacement = const [];

  line_loop:
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];

    if (line.isEmpty || line[0] != '.') continue;

    if (line.startsWith('.method public') && !line.contains(' abstract ')) {
      bodyStart = null;

      if (line.endsWith(')V')) {
        for (final voidMethod in _voidMethods) {
          if (!line.contains(' $voidMethod(')) continue;

          bodyStart = i + 1;
          replacement = MethodBodies.returnVoid;
          continue line_loop;
        }
      } else if (line.endsWith(')Z')) {
        for (final trueMethod in _trueMethods) {
          if (!line.contains(' $trueMethod(')) continue;

          bodyStart = i + 1;
          replacement = MethodBodies.returnTrue;
          continue line_loop;
        }

        for (final falseMethod in _falseMethods) {
          if (!line.contains(' $falseMethod(')) continue;

          bodyStart = i + 1;
          replacement = MethodBodies.returnFalse;
          continue line_loop;
        }
      } else if (line.endsWith(')I')) {
        if (line.contains(' getVip_expire_at(')) {
          bodyStart = i + 1;
          replacement = MethodBodies.returnABigInteger;
          continue line_loop;
        }
      }
    }

    if (bodyStart != null && line == '.end method') {
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
  await file.writeAsString(lines.join('\n'), flush: true);
}

/// Known methods we want to replace with
/// [MethodBodies.returnVoid]
const _voidMethods = [
  'loadInterstitialAd',
  'loadRewardedAd',
  'loadRewardedVideo',
  'showInterstitial',
  'showInterstitialAd',
  'showInterstitialWithPopup',
  'showRewarded',
  'showRewardedAd',
  'showRewardedVideo',
  'showBanner',
  'showCustomRateAppPopup',
  'showRateAppPopup',
  'disablePremium',
  'setPremium',
  'setVip_expire_at',
];

/// Known methods we want to replace with
/// [MethodBodies.returnTrue]
const _trueMethods = [
  'isPremium',
  'getRateAppStatus',
];

/// Known methods we want to replace with
/// [MethodBodies.returnFalse]
const _falseMethods = [
  'isInterstitialAvailable',
  'isRewardedAvailable',
  'isRewardedPlacementAvailable',
];
