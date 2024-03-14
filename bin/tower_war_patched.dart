import 'dart:io';

import 'package:pool/pool.dart';

import 'src/patch_json.dart';
import 'src/patch_manifest.dart';
import 'src/patch_smali.dart';

final originalApkFile = File('original.apk');
final decompiledDir = Directory('original');

Future<void> prereq() async {
  if (!originalApkFile.existsSync()) {
    throw 'original.apk not found! Please download it from the link in the README.';
  }

  final whichApktool = await Process.run('which', ['apktool']);
  if (whichApktool.exitCode != 0) {
    throw 'apktool not found! Please install it from https://apktool.org/docs/install';
  }

  final whichJava = await Process.run('which', ['java']);
  if (whichJava.exitCode != 0) {
    throw 'java not found! Please install it with e.g. sudo dnf install java-latest-openjdk';
  }

  final whichApksigner = await Process.run('which', ['apksigner']);
  if (whichApksigner.exitCode != 0) {
    throw 'apksigner not found! Please install the Android Build Tools and add them to your PATH';
  }

  final whichZipalign = await Process.run('which', ['zipalign']);
  if (whichZipalign.exitCode != 0) {
    throw 'zipalign not found! Please install the Android Build Tools and add them to your PATH';
  }
}

Future<void> cleanup() async {
  if (decompiledDir.existsSync()) {
    print('Cleaning up old files...');
    await decompiledDir.delete(recursive: true);
  }
}

Future<void> decompile() async {
  print('Decompiling original.apk...');
  final process = await Process.start('apktool', ['d', originalApkFile.path]);
  stdout.addStream(process.stdout);
  stderr.addStream(process.stderr);
  await process.exitCode;
}

Future<void> runPatches() async {
  final smaliFiles = decompiledDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.smali'))
      .toList();

  print('Running patches on ${smaliFiles.length} smali files...');

  final pool = Pool(16);
  await Future.wait([
    for (final file in smaliFiles) pool.withResource(() => patchSmali(file)),
    pool.withResource(patchJson),
    pool.withResource(patchAndroidManifest),
  ]);
  await pool.close();

  printMethodCounts();
}

Future<void> recompile() async {
  print('Recompiling patched files...');
  final process = await Process.start('apktool', ['b', decompiledDir.path]);
  stdout.addStream(process.stdout);
  stderr.addStream(process.stderr);
  await process.exitCode;
}

Future<void> zipalign() async {
  print('Running zipalign...');
  final process = await Process.start('zipalign', [
    '-f',
    '-p',
    '4',
    'original/dist/original.apk',
    'patched.apk',
  ]);
  stdout.addStream(process.stdout);
  stderr.addStream(process.stderr);
  await process.exitCode;
}

Future<void> sign() async {
  print('Signing patched.apk...');
  final process = await Process.start('apksigner', [
    'sign',
    '--ks',
    'keystore.jks',
    '--ks-pass',
    'file:ks-pass.txt',
    'patched.apk',
  ]);
  stdout.addStream(process.stdout);
  stderr.addStream(process.stderr);
  await process.exitCode;
}

void main(List<String> arguments) async {
  final stopwatch = Stopwatch()..start();

  await prereq();
  await cleanup();
  await decompile();
  await runPatches();
  await recompile();
  await zipalign();
  await sign();

  stopwatch.stop();
  print('All done in ${stopwatch.elapsed.inSeconds}s!');
}
