import 'dart:io';

final _converterDir = Directory('xapk-to-apk/');
final _converterExe = File('${_converterDir.path}xapktoapk.py');

Future<void> convertXapk(File xapkFile) async {
  print('Converting $xapkFile to apk...');

  if (!_converterDir.existsSync()) {
    print('Cloning xapk-to-apk from GitHub...');
    await _cloneRepo();
    await Process.run('chmod', ['+x', _converterExe.path]);
  }

  await _convertXapk(xapkFile);
}

Future<void> _cloneRepo() async {
  final process = await Process.start(
      'git', ['clone', 'https://github.com/LuigiVampa92/xapk-to-apk']);
  stdout.addStream(process.stdout);
  stderr.addStream(process.stderr);
  await process.exitCode;
}

Future<void> _convertXapk(File xapkFile) async {
  final process =
      await Process.start('python', [_converterExe.path, xapkFile.path]);
  stdout.addStream(process.stdout);
  stderr.addStream(process.stderr);
  await process.exitCode;
}
