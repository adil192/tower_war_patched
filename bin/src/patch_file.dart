import 'dart:io';

import 'method_bodies.dart';

Future<void> patchFile(File file) async {
  final lines = await file.readAsLines();

  bool changed = false;

  /// The body start line number of the current method to patch
  int? bodyStart;

  /// The target method body with which to replace the original
  List<String> replacement = const [];

  /// The target method's name
  String? methodName;

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
          methodName = voidMethod;
          continue line_loop;
        }
      } else if (line.endsWith(')Z')) {
        for (final trueMethod in _trueMethods) {
          if (!line.contains(' $trueMethod(')) continue;

          bodyStart = i + 1;
          replacement = MethodBodies.returnTrue;
          methodName = trueMethod;
          continue line_loop;
        }

        for (final falseMethod in _falseMethods) {
          if (!line.contains(' $falseMethod(')) continue;

          bodyStart = i + 1;
          replacement = MethodBodies.returnFalse;
          methodName = falseMethod;
          continue line_loop;
        }
      } else if (line.endsWith(')I')) {
        for (final bigNumberMethod in _bigNumberMethods) {
          if (!line.contains(' $bigNumberMethod(')) continue;

          bodyStart = i + 1;
          replacement = MethodBodies.returnABigInteger;
          methodName = bigNumberMethod;
          continue line_loop;
        }
      }

      for (final entry in _otherMethods.entries) {
        if (!line.contains(' ${entry.key}(')) continue;

        bodyStart = i + 1;
        replacement = entry.value;
        methodName = entry.key;
        continue line_loop;
      }
    }

    if (bodyStart != null && line == '.end method') {
      changed = true;
      print('Patching $methodName in ${file.path}');

      lines.removeRange(bodyStart, i);
      lines.insertAll(bodyStart, replacement);

      i = bodyStart + replacement.length + 1;
      bodyStart = null;
      continue line_loop;
    }
  }

  if (!changed) return;

  await file.writeAsString(lines.join('\n'), flush: true);
}

/// Known methods we want to replace with
/// [MethodBodies.returnVoid]
const _voidMethods = [
  'loadInterstitialAd',
  'loadRewardedAd',
  'loadRewardedVideo',
  'showAd',
  'showFullscreenAd',
  'showInterstitial',
  'showInterstitialAd',
  'showInterstitialWithPopup',
  'showRewarded',
  'showRewardedAd',
  'showRewardedVideo',
  'showRewardedVideoAd',
  'showRewardedInterstitialAd',
  'showAppOpenAd',
  'showBanner',
  'showRateAppPopup',
  'setPremium',
  'setVip_expire_at',
];

/// Known methods we want to replace with
/// [MethodBodies.returnTrue]
const _trueMethods = [
  'isPremium',
  'getRateAppStatus',
  'eligibleQueryPurchaseHistory',
  'showRewarded',
  'showInterstitial',
  'showInterstitialWithPopup',
];

/// Known methods we want to replace with
/// [MethodBodies.returnFalse]
const _falseMethods = [
  'isInterstitialAvailable',
  'isRewardedAvailable',
  'isRewardedPlacementAvailable',
  'showCustomRateAppPopup',
  'showRateAppPopup',
];

/// Known methods that we want to replace with
/// [MethodBodies.returnABigInteger]
const _bigNumberMethods = [
  'getVip_expire_at',
  'getSubscriptionExpirationTimestamp',
];

const _otherMethods = <String, List<String>>{
  'disablePremium': MethodBodies.enablePremium,
};
