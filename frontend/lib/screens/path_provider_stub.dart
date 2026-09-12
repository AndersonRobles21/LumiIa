// Archivo: path_provider_stub.dart

class Directory {
  final String path;
  Directory(this.path);
}

Future<Directory?> getApplicationDocumentsDirectory() async {
  return null;
}

Future<Directory?> getDownloadsDirectory() async {
  return null;
}