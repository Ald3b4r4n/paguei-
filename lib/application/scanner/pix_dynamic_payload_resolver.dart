import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:paguei/application/scanner/pix_payload_parser.dart';
import 'package:paguei/domain/entities/parsed_bill_data.dart';
import 'package:paguei/domain/value_objects/money.dart';

typedef PixDynamicPayloadFetcher = Future<String> Function(Uri uri);

final class PixDynamicPayloadResolver {
  PixDynamicPayloadResolver({
    PixDynamicPayloadFetcher? fetcher,
    this.timeout = const Duration(seconds: 8),
  }) : _fetcher = fetcher ?? _defaultFetch;

  final PixDynamicPayloadFetcher _fetcher;
  final Duration timeout;

  Future<ParsedBillData> enrich(ParsedBillData data) async {
    final pixCode = data.pixCode;
    if (pixCode == null) return data;

    final PixPayloadData parsed;
    try {
      parsed = PixPayloadParser.parse(pixCode);
    } on Object catch (error, stackTrace) {
      _log('Falha ao parsear payload PIX antes do enriquecimento: $error',
          stackTrace);
      return data.copyWith(
        warnings: [
          ...data.warnings,
          'QR PIX lido, mas o payload esta incompleto para extrair metadados.',
        ],
      );
    }

    final location = parsed.locationUrl;
    if (location == null) {
      _log(
        'PIX parse sem URL dinamica: amount=${data.amount != null}, '
        'merchant=${data.pixMerchantName != null}, txid=${data.pixTxId != null}',
      );
      return data.copyWith(
        pixKey: data.pixKey ?? parsed.key,
        pixLocationUrl: data.pixLocationUrl ?? parsed.locationUrl,
      );
    }

    final uri = Uri.tryParse(location);
    if (uri == null || !uri.hasAuthority) {
      _log('PIX dinamico com URL invalida: $location');
      return data.copyWith(
        pixLocationUrl: data.pixLocationUrl ?? location,
        warnings: [
          ...data.warnings,
          'QR PIX dinamico encontrado, mas a URL de consulta e invalida.',
        ],
      );
    }

    try {
      _log('PIX dinamico consultando PSP: host=${uri.host}');
      final body = await _fetcher(uri).timeout(timeout);
      final dynamicData = PixDynamicPayloadData.fromJsonString(body);

      _log(
        'PIX dinamico resolvido: amount=${dynamicData.amount != null}, '
        'merchant=${dynamicData.merchantName != null}, '
        'key=${dynamicData.key != null}, txid=${dynamicData.txId != null}',
      );

      return data.copyWith(
        confidence: data.confidence < 0.99 ? 0.99 : data.confidence,
        amount: data.amount ?? dynamicData.amount,
        beneficiary:
            dynamicData.merchantName ?? data.beneficiary ?? parsed.merchantName,
        pixKey: dynamicData.key ?? data.pixKey ?? parsed.key ?? location,
        pixLocationUrl: data.pixLocationUrl ?? location,
        pixMerchantName: dynamicData.merchantName ??
            data.pixMerchantName ??
            parsed.merchantName,
        pixCity: dynamicData.city ?? data.pixCity ?? parsed.city,
        pixTxId: dynamicData.txId ?? data.pixTxId ?? parsed.txId,
      );
    } on FormatException catch (error, stackTrace) {
      _log('Falha ao parsear resposta do PIX dinamico: $error', stackTrace);
      return _withDynamicWarning(data, location);
    } on TimeoutException catch (error, stackTrace) {
      _log('Timeout ao consultar PIX dinamico: $error', stackTrace);
      return _withDynamicWarning(data, location);
    } on Object catch (error, stackTrace) {
      _log('Falha ao consultar PIX dinamico: $error', stackTrace);
      return _withDynamicWarning(data, location);
    }
  }

  ParsedBillData _withDynamicWarning(ParsedBillData data, String location) {
    return data.copyWith(
      pixKey: data.pixKey ?? location,
      pixLocationUrl: data.pixLocationUrl ?? location,
      warnings: [
        ...data.warnings,
        'QR PIX dinamico lido, mas nao foi possivel consultar valor e recebedor agora.',
      ],
    );
  }

  static Future<String> _defaultFetch(Uri uri) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'HTTP ${response.statusCode} ao consultar PIX dinamico',
          uri: uri,
        );
      }

      return body;
    } finally {
      client.close(force: true);
    }
  }

  void _log(String message, [StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'paguei.scanner.pix',
      stackTrace: stackTrace,
    );
  }
}

final class PixDynamicPayloadData {
  const PixDynamicPayloadData({
    this.amount,
    this.key,
    this.merchantName,
    this.city,
    this.txId,
  });

  factory PixDynamicPayloadData.fromJsonString(String body) {
    final decoded = jsonDecode(_extractJsonPayload(body));
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Resposta PIX dinamico nao e JSON objeto.');
    }

    final receiver = _map(decoded['recebedor']);
    final value = _map(decoded['valor']);

    return PixDynamicPayloadData(
      amount: _moneyFrom(value?['original'] ?? decoded['valor']),
      key: _string(decoded['chave']) ?? _string(decoded['pixKey']),
      merchantName: _string(receiver?['nome']) ??
          _string(decoded['nomeRecebedor']) ??
          _string(decoded['merchantName']),
      city: _string(receiver?['cidade']) ?? _string(decoded['cidade']),
      txId: _string(decoded['txid']) ?? _string(decoded['txId']),
    );
  }

  final Money? amount;
  final String? key;
  final String? merchantName;
  final String? city;
  final String? txId;

  static Map<String, Object?>? _map(Object? value) {
    return value is Map ? value.cast<String, Object?>() : null;
  }

  static String? _string(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static Money? _moneyFrom(Object? value) {
    final raw = _string(value);
    if (raw == null) return null;

    final parsed = double.tryParse(raw.replaceAll(',', '.'));
    return parsed == null || parsed <= 0 ? null : Money.fromDouble(parsed);
  }

  static String _extractJsonPayload(String body) {
    final trimmed = body.trim();
    if (trimmed.startsWith('{')) return trimmed;

    final parts = trimmed.split('.');
    if (parts.length < 2) {
      throw const FormatException('Resposta PIX dinamico nao e JSON nem JWS.');
    }

    try {
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      final remainder = payload.length % 4;
      if (remainder != 0) {
        payload = payload.padRight(payload.length + 4 - remainder, '=');
      }
      return utf8.decode(base64.decode(payload));
    } on Object catch (error) {
      throw FormatException('Resposta PIX dinamico JWS invalida: $error');
    }
  }
}
