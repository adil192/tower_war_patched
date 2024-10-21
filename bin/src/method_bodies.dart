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
}
