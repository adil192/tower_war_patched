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
    // biggest signed 32-bit integer
    '    const v0, 0x7fffffff',
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
}
