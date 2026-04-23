import 'package:permission_handler/permission_handler.dart';

enum CameraPermissionStatus { granted, denied, permanentlyDenied, restricted }

abstract interface class CameraPermissionDatasource {
  Future<CameraPermissionStatus> getStatus();
  Future<CameraPermissionStatus> request();
  Future<void> openSettings();
}

final class CameraPermissionDatasourceImpl
    implements CameraPermissionDatasource {
  const CameraPermissionDatasourceImpl();

  @override
  Future<CameraPermissionStatus> getStatus() async {
    final status = await Permission.camera.status;
    return _map(status);
  }

  @override
  Future<CameraPermissionStatus> request() async {
    final status = await Permission.camera.request();
    return _map(status);
  }

  @override
  Future<void> openSettings() => openAppSettings();

  static CameraPermissionStatus _map(PermissionStatus status) =>
      switch (status) {
        PermissionStatus.granted ||
        PermissionStatus.limited =>
          CameraPermissionStatus.granted,
        PermissionStatus.permanentlyDenied =>
          CameraPermissionStatus.permanentlyDenied,
        PermissionStatus.restricted => CameraPermissionStatus.restricted,
        _ => CameraPermissionStatus.denied,
      };
}
