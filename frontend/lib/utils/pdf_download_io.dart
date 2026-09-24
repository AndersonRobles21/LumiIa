import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const _androidPdfChannel = MethodChannel('lumi/pdf_download');

Future<String?> downloadPdfImpl(
  Uint8List bytes, {
  required String filename,
}) async {
  if (Platform.isAndroid) {
    return _androidPdfChannel.invokeMethod<String>('savePdfToDownloads', {
      'bytes': bytes,
      'filename': filename,
    });
  }

  final directory =
      await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();

  final file = File('${directory.path}/$filename');
  await file.writeAsBytes(bytes);
  return file.path;
}
