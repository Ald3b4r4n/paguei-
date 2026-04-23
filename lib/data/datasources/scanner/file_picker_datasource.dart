import 'dart:io';

import 'package:file_picker/file_picker.dart';

/// Result from a file-pick operation.
final class PickedFile {
  const PickedFile({required this.file, required this.name});

  final File file;
  final String name;
}

abstract interface class FilePickerDatasource {
  Future<PickedFile?> pickImage();
  Future<PickedFile?> pickPdf();
  Future<PickedFile?> pickTxt();
  Future<PickedFile?> pickAny();
}

/// Production implementation using [FilePicker].
final class FlutterFilePickerDatasource implements FilePickerDatasource {
  const FlutterFilePickerDatasource();

  @override
  Future<PickedFile?> pickImage() => _pick(
        type: FileType.image,
      );

  @override
  Future<PickedFile?> pickPdf() => _pick(
        type: FileType.custom,
        extensions: ['pdf'],
      );

  @override
  Future<PickedFile?> pickTxt() => _pick(
        type: FileType.custom,
        extensions: ['txt'],
      );

  @override
  Future<PickedFile?> pickAny() => _pick(
        type: FileType.custom,
        extensions: ['pdf', 'txt', 'jpg', 'jpeg', 'png', 'webp', 'heic'],
      );

  Future<PickedFile?> _pick({
    required FileType type,
    List<String>? extensions,
  }) async {
    final result = await FilePicker.pickFiles(
      type: type,
      allowedExtensions: extensions,
      allowMultiple: false,
      withData: false, // stream from path, avoid loading full file into memory
    );

    final path = result?.files.single.path;
    if (path == null) return null;

    return PickedFile(
      file: File(path),
      name: result!.files.single.name,
    );
  }
}
