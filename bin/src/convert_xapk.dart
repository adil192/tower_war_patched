import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

final apkEditor = File('bin/APKEditor.jar');

Future<void> convertXapk(File xapkFile, File apkFile) async {
  print('Converting $xapkFile to $apkFile...');

  if (!apkEditor.existsSync()) {
    print('Downloading APKEditor from GitHub...');
    await _downloadApkEditor();
  }

  await _convertXapk(xapkFile, apkFile);
}

Future<void> _downloadApkEditor() async {
  // Use the GitHub API to get the download URL
  final response = await http.get(Uri.parse(
      'https://api.github.com/repos/REAndroid/APKEditor/releases/latest'));
  if (response.statusCode != 200) {
    throw 'Failed to download APKEditor: '
        '${response.statusCode} ${response.body}';
  }
  final json = jsonDecode(response.body) as Map<String, dynamic>;

  final url = json['assets'][0]['browser_download_url'];
  return await _download(url);
}

Future<void> _download(String url) async {
  print('Downloading $url...');
  final process =
      await Process.start('curl', ['-L', '-o', apkEditor.path, url]);
  stdout.addStream(process.stdout);
  stderr.addStream(process.stderr);
  await process.exitCode;
}

Future<void> _convertXapk(File xapkFile, File apkFile) async {
  final process = await Process.start('java', [
    '-jar',
    apkEditor.path,
    'm',
    '-i',
    xapkFile.path,
    '-o',
    apkFile.path,
  ]);
  stdout.addStream(process.stdout);
  stderr.addStream(process.stderr);
  await process.exitCode;
}
