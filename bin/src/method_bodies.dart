abstract class MethodBodies {
  static const returnVoid = [
    '    .locals 0',
    '    ',
    '    return-void',
  ];

  static const returnTrue = [
    '    .locals 1',
    '    ',
    '    const/4 v0, 0x1',
    '    ',
    '    return v0',
  ];

  static const returnFalse = [
    '    .locals 1',
    '    ',
    '    const/4 v0, 0x0',
    '    ',
    '    return v0',
  ];

  static const returnABigInteger = [
    '    .locals 1',
    '    ',
    // biggest signed 32-bit integer: January 19, 2038
    '    const v0, 0x7fffffff',
    '    ',
    '    return v0',
  ];

  static const returnZero = [
    '    .locals 1',
    '    ',
    '    const/4 v0, 0x0',
    '    ',
    '    return v0',
  ];

  static const returnZeroString = [
    '    .locals 1',
    '    ',
    '    const-string v0, "0"',
    '    ',
    '    return-object v0',
  ];

  static const returnNull = [
    '    .locals 1',
    '    ',
    '    const/4 v0, 0x0',
    '    ',
    '    return-object v0',
  ];

  /// Instead of showing an ad, directly invoke the callback as if the ad was watched successfully
  static const grantRewardAndReturnTrue = [
    '    .locals 1',
    '    ',
    '    const/4 v0, 0x1',
    '    ',
    '    invoke-interface {p1, v0}, Lsaygames/saykit/SayKitRewardedClosedCallback;->onRewardedClosed(Z)V',
    '    ',
    '    return v0',
  ];

  /// Equivalent to the method body of the original `enablePremium` method
  /// in `smali_classes7/saygames/bridge/unity/SayKitBridge.smali`.
  ///
  /// This just calls the `enablePremium` method in
  /// `smali_classes7/saygames/saykit/SayKit.smali`.
  static const enablePremium = [
    '    .locals 0',
    '    .annotation runtime Lkotlin/jvm/JvmStatic;',
    '    .end annotation',
    '    ',
    '    invoke-static {}, Lsaygames/saykit/SayKit;->enablePremium()V',
    '    ',
    '    return-void',
  ];

  /// Calls the `enablePremium` method.
  /// For injecting into the SayKitBridgeActivity.smali file.
  static const injectEnablePremium = [
    '    invoke-static {}, Lsaygames/saykit/SayKit;->enablePremium()V',
  ];
}
