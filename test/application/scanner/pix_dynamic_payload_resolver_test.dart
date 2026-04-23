import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/scanner/pix_dynamic_payload_resolver.dart';
import 'package:paguei/application/scanner/scan_barcode_use_case.dart';
import 'package:paguei/domain/entities/parsed_bill_data.dart';
import 'package:paguei/domain/entities/scan_source_type.dart';

void main() {
  const dynamicEquatorialPix =
      '00020101021226770014br.gov.bcb.pix2555api.itau/pix/qr/v2/fa875b9c-fd8a-4bba-a1f0-fbaae681769c5204000053039865802BR5916EQUATORIAL GOIAS6007GOIANIA6217051320260358352146304AA0F';

  test('enriches dynamic PIX with amount, receiver, key, city and txid',
      () async {
    final base = const ScanBarcodeUseCase().execute(
      raw: dynamicEquatorialPix,
      source: ScanSourceType.qrCode,
    );
    final resolver = PixDynamicPayloadResolver(
      fetcher: (uri) async {
        expect(uri.host, 'api.itau');
        return jsonEncode({
          'txid': '2026035835214',
          'chave': '01.543.032/0001-04',
          'valor': {'original': '69.12'},
          'recebedor': {
            'nome': 'EQUATORIAL GOIAS DISTRIBUIDORA DE ENERGIA S/A',
            'cidade': 'GOIANIA',
          },
        });
      },
    );

    final enriched = await resolver.enrich(base);

    expect(enriched.pixCode, dynamicEquatorialPix);
    expect(enriched.pixLocationUrl,
        'https://api.itau/pix/qr/v2/fa875b9c-fd8a-4bba-a1f0-fbaae681769c');
    expect(enriched.amount?.amount, closeTo(69.12, 0.01));
    expect(enriched.pixKey, '01.543.032/0001-04');
    expect(
      enriched.beneficiary,
      'EQUATORIAL GOIAS DISTRIBUIDORA DE ENERGIA S/A',
    );
    expect(
      enriched.pixMerchantName,
      'EQUATORIAL GOIAS DISTRIBUIDORA DE ENERGIA S/A',
    );
    expect(enriched.pixCity, 'GOIANIA');
    expect(enriched.pixTxId, '2026035835214');
    expect(enriched.confidence, 0.99);
  });

  test('keeps dynamic PIX valid when remote details cannot be fetched',
      () async {
    final base = const ScanBarcodeUseCase().execute(
      raw: dynamicEquatorialPix,
      source: ScanSourceType.qrCode,
    );
    final resolver = PixDynamicPayloadResolver(
      fetcher: (_) => throw const FormatException('bad json'),
    );

    final enriched = await resolver.enrich(base);

    expect(enriched.hasPixCode, isTrue);
    expect(enriched.hasBarcode, isFalse);
    expect(enriched.pixLocationUrl, startsWith('https://api.itau/'));
    expect(enriched.warnings, isNotEmpty);
  });

  test('decodes Itaú-style JWS dynamic PIX response without using debtor name',
      () async {
    final base = const ScanBarcodeUseCase().execute(
      raw: dynamicEquatorialPix,
      source: ScanSourceType.qrCode,
    );
    final resolver = PixDynamicPayloadResolver(
      fetcher: (_) async => _jws({
        'valor': {'original': '69.12'},
        'devedor': {'nome': 'RAYLANE DE NORONHA CARDOSO'},
        'txid': 'BL29380056331109000000096078094',
        'chave': 'cccaf607-184c-4395-8a4e-a0d2c112d144',
      }),
    );

    final enriched = await resolver.enrich(base);

    expect(enriched.amount?.amount, closeTo(69.12, 0.01));
    expect(
      enriched.beneficiary,
      'EQUATORIAL GOIAS DISTRIBUIDORA DE ENERGIA S/A',
    );
    expect(enriched.beneficiary, isNot(contains('RAYLANE')));
    expect(enriched.pixKey, 'cccaf607-184c-4395-8a4e-a0d2c112d144');
    expect(enriched.pixTxId, 'BL29380056331109000000096078094');
  });

  test('parses JWS compact response aliases used by PSPs', () {
    final dynamicData = PixDynamicPayloadData.fromJsonString(_jws({
      'txid': 'ABC123',
      'chave': 'pix@example.com',
      'valor': {'original': '12.34'},
      'recebedor': {
        'nome': 'Loja Teste',
        'cidade': 'BRASILIA',
      },
    }));

    expect(dynamicData.amount?.amount, closeTo(12.34, 0.01));
    expect(dynamicData.key, 'pix@example.com');
    expect(dynamicData.merchantName, 'Loja Teste');
    expect(dynamicData.city, 'BRASILIA');
    expect(dynamicData.txId, 'ABC123');
  });

  test('does not fetch when PIX payload has no dynamic location URL', () async {
    const staticPix =
        '00020126580014BR.GOV.BCB.PIX0136123e4567-e89b-12d3-a456-426655440000520400005303986540569.125802BR5913Empresa Teste6007GOIANIA62140510TX123456786304B14F';
    final base = const ScanBarcodeUseCase().execute(
      raw: staticPix,
      source: ScanSourceType.qrCode,
    );
    final resolver = PixDynamicPayloadResolver(
      fetcher: (_) => fail('static PIX should not fetch PSP details'),
    );

    final enriched = await resolver.enrich(base);

    expect(enriched.amount?.amount, closeTo(69.12, 0.01));
    expect(enriched.pixKey, '123e4567-e89b-12d3-a456-426655440000');
    expect(enriched.pixLocationUrl, isNull);
  });

  test('parses dynamic PSP response aliases used by PIX providers', () {
    final dynamicData = PixDynamicPayloadData.fromJsonString(jsonEncode({
      'txId': 'ABC123',
      'pixKey': 'pix@example.com',
      'valor': '12,34',
      'merchantName': 'Loja Teste',
      'cidade': 'BRASILIA',
    }));

    expect(dynamicData.amount?.amount, closeTo(12.34, 0.01));
    expect(dynamicData.key, 'pix@example.com');
    expect(dynamicData.merchantName, 'Loja Teste');
    expect(dynamicData.city, 'BRASILIA');
    expect(dynamicData.txId, 'ABC123');
  });

  test('returns original data when there is no PIX code', () async {
    const data = ParsedBillData(
      source: ScanSourceType.image,
      confidence: 0,
    );
    final resolver = PixDynamicPayloadResolver(
      fetcher: (_) => fail('non-PIX data should not fetch PSP details'),
    );

    expect(await resolver.enrich(data), same(data));
  });
}

String _jws(Map<String, Object?> payload) {
  String encode(Map<String, Object?> value) {
    return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  }

  return '${encode({'alg': 'PS256'})}.${encode(payload)}.signature';
}
