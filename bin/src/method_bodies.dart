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
}
