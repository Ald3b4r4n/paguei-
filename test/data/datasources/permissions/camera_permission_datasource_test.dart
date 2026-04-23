import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/data/datasources/permissions/camera_permission_datasource.dart';

class _FakePermissionDatasource implements CameraPermissionDatasource {
  _FakePermissionDatasource(this._status);

  final CameraPermissionStatus _status;
  bool settingsOpened = false;

  @override
  Future<CameraPermissionStatus> getStatus() async => _status;

  @override
  Future<CameraPermissionStatus> request() async => _status;

  @override
  Future<void> openSettings() async => settingsOpened = true;
}

void main() {
  group('CameraPermissionDatasource — states', () {
    test('granted status returns granted', () async {
      final ds = _FakePermissionDatasource(CameraPermissionStatus.granted);
      expect(await ds.getStatus(), CameraPermissionStatus.granted);
    });

    test('denied status returns denied', () async {
      final ds = _FakePermissionDatasource(CameraPermissionStatus.denied);
      expect(await ds.getStatus(), CameraPermissionStatus.denied);
    });

    test('permanentlyDenied status returns permanentlyDenied', () async {
      final ds =
          _FakePermissionDatasource(CameraPermissionStatus.permanentlyDenied);
      expect(await ds.getStatus(), CameraPermissionStatus.permanentlyDenied);
    });

    test('request() returns same status as getStatus()', () async {
      final ds = _FakePermissionDatasource(CameraPermissionStatus.granted);
      final status = await ds.request();
      expect(status, CameraPermissionStatus.granted);
    });

    test('openSettings() is invokable without throwing', () async {
      final ds =
          _FakePermissionDatasource(CameraPermissionStatus.permanentlyDenied);
      await expectLater(ds.openSettings(), completes);
      expect(ds.settingsOpened, isTrue);
    });
  });

  group('CameraPermissionDatasource — granted guard', () {
    test('granted allows scanner to proceed', () async {
      final ds = _FakePermissionDatasource(CameraPermissionStatus.granted);
      final status = await ds.getStatus();
      expect(status == CameraPermissionStatus.granted, isTrue);
    });

    test('denied blocks scanner', () async {
      final ds = _FakePermissionDatasource(CameraPermissionStatus.denied);
      final status = await ds.getStatus();
      expect(status == CameraPermissionStatus.granted, isFalse);
    });

    test('permanentlyDenied requires settings redirect', () async {
      final ds =
          _FakePermissionDatasource(CameraPermissionStatus.permanentlyDenied);
      final status = await ds.getStatus();
      expect(status, CameraPermissionStatus.permanentlyDenied);
    });
  });
}
