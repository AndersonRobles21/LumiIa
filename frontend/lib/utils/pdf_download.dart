import 'dart:typed_data';

import 'pdf_download_io.dart' if (dart.library.html) 'pdf_download_web.dart';

Future<String?> downloadPdfBytes(
  Uint8List bytes, {
  String filename = 'LUMI_Reporte_Estadisticas.pdf',
}) async {
  return downloadPdfImpl(bytes, filename: filename);
}
