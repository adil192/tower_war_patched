import 'dart:io';

import 'method_bodies.dart';

/// The number of times a method is patched.
/// The key is the method name with the type of return value,
/// e.g. `isPremium()Z` or `loadInterstitialAd()V`.
Map<String, int> _methodCounts = {
  for (final voidMethod in _voidMethods) '$voidMethod()V': 0,
  for (final trueMethod in _trueMethods) '$trueMethod()Zt': 0,
  for (final falseMethod in _falseMethods) '$falseMethod()Zf': 0,
  for (final bigNumberMethod in _bigNumberMethods) '$bigNumberMethod()I': 0,
  for (final otherMethod in _otherMethods.keys) '$otherMethod()_': 0,
};

void printMethodCounts() {
  print('Method counts:');
  for (final entry in _methodCounts.entries) {
    print('${entry.key}: ${entry.value}');
  }
}

Future<void> patchSmali(File file) async {
  final lines = await file.readAsLines();

  bool changed = false;

  /// The body start line number of the current method to patch
  int? bodyStart;

  /// The target method body with which to replace the original
  List<String> replacement = const [];

  /// Code to inject into the beginning of the method body
  List<String> injection = const [];

  /// The target method's name
  String? methodName;

  line_loop:
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];

    if (line.isEmpty || line[0] != '.') continue;

    if (line.startsWith('.method ') && !line.contains(' abstract ')) {
      bodyStart = null;
      replacement = const [];
      injection = const [];

      // Check if we have something to inject into the method.
      // We may also want to replace the method body first.
      for (final entry in _injectedMethods.entries) {
        if (!line.contains(' ${entry.key}(')) continue;

        bodyStart = i + 1;
        injection = entry.value;
        methodName = entry.key;
      }

      if (line.endsWith(')V')) {
        for (final voidMethod in _voidMethods) {
          if (!line.contains(' $voidMethod(')) continue;

          bodyStart = i + 1;
          replacement = MethodBodies.returnVoid;
          methodName = voidMethod;
          _methodCounts.update('$voidMethod()V', (c) => c + 1);
          continue line_loop;
        }
      } else if (line.endsWith(')Z')) {
        for (final trueMethod in _trueMethods) {
          if (!line.contains(' $trueMethod(')) continue;

          bodyStart = i + 1;
          replacement = MethodBodies.returnTrue;
          methodName = trueMethod;
          _methodCounts.update('$trueMethod()Zt', (c) => c + 1);
          continue line_loop;
        }

        for (final falseMethod in _falseMethods) {
          if (!line.contains(' $falseMethod(')) continue;

          bodyStart = i + 1;
          replacement = MethodBodies.returnFalse;
          methodName = falseMethod;
          _methodCounts.update('$falseMethod()Zf', (c) => c + 1);
          continue line_loop;
        }
      } else if (line.endsWith(')I')) {
        for (final bigNumberMethod in _bigNumberMethods) {
          if (!line.contains(' $bigNumberMethod(')) continue;

          bodyStart = i + 1;
          replacement = MethodBodies.returnABigInteger;
          methodName = bigNumberMethod;
          _methodCounts.update('$bigNumberMethod()I', (c) => c + 1);
          continue line_loop;
        }
      }

      for (final entry in _otherMethods.entries) {
        if (!line.contains(' ${entry.key}(')) continue;

        bodyStart = i + 1;
        replacement = entry.value;
        methodName = entry.key;
        _methodCounts.update('${entry.key}()_', (c) => c + 1);
        continue line_loop;
      }
    }

    if (bodyStart != null && line == '.end method') {
      changed = true;
      print('Patching $methodName in ${file.path}');

      if (replacement.isNotEmpty) {
        lines.removeRange(bodyStart, i);
        lines.insertAll(bodyStart, replacement);
        i = bodyStart + replacement.length + 1;
      }
      if (injection.isNotEmpty) {
        // We assume lines[bodyStart] is the ".locals 0" line,
        // so we insert the injection after that line.
        lines.insertAll(bodyStart + 1, injection);
        // Add a blank line before the injection
        lines.insert(bodyStart + 1, '    ');
        i += injection.length + 1;
      }

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
  'showRewardedAd',
  'showRewardedVideo',
  'showRewardedVideoAd',
  'showRewardedInterstitialAd',
  'showAppOpenAd',
  'showBanner',
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
  'isRooted',
  'isEmulator',
  'isDebuggerAttached',
  'isAppDebuggable',
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

/// We want to inject some code into the beginning
/// of the existing method body.
const _injectedMethods = <String, List<String>>{
  'isInterstitialAvailable': MethodBodies.injectEnablePremium,
  'isRewardedAvailable': MethodBodies.injectEnablePremium,
  'isRewardedPlacementAvailable': MethodBodies.injectEnablePremium,
};
