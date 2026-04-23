import 'package:paguei/domain/value_objects/money.dart';

/// Parser for EMV PIX "copia e cola" payloads.
///
/// It extracts only stable EMV fields used by Brazilian PIX QR codes. CRC is
/// preserved as part of the raw payload, but not validated here because the app
/// must still open review for user confirmation if bank apps generate unusual
/// payloads.
final class PixPayloadParser {
  const PixPayloadParser._();

  static final _payloadWithCrc = RegExp('000201[\\s\\S]*?6304[0-9A-Fa-f]{4}');
  static final _payloadStart = RegExp('000201');

  static String? extractPayload(String raw) {
    final trimmed = raw.trim();
    final fullMatch = _payloadWithCrc.firstMatch(trimmed);
    if (fullMatch != null) return fullMatch.group(0)!.trim();

    final start = _payloadStart.firstMatch(trimmed);
    if (start == null) return null;

    final tail = trimmed.substring(start.start);
    final lineEnd = tail.indexOf(RegExp('[\\r\\n]'));
    final candidate =
        (lineEnd == -1 ? tail : tail.substring(0, lineEnd)).trim();
    return candidate.length >= 10 ? candidate : null;
  }

  static PixPayloadData parse(String payload) {
    final fields = _parseFields(payload);
    final merchantAccount = _merchantAccount(fields);
    final additionalData = _parseFields(fields['62'] ?? '');
    final amountRaw = fields['54'];
    final amount = amountRaw == null
        ? null
        : double.tryParse(amountRaw.replaceAll(',', '.'));

    return PixPayloadData(
      rawPayload: payload,
      key: merchantAccount['01']?.trim(),
      locationUrl: _normalizeLocationUrl(merchantAccount['25']),
      merchantName: _normalizeMerchantName(_blankToNull(fields['59'])),
      city: _blankToNull(fields['60']),
      txId: _blankToNull(additionalData['05']),
      amount: amount == null || amount <= 0 ? null : Money.fromDouble(amount),
    );
  }

  static Map<String, String> _merchantAccount(Map<String, String> fields) {
    for (var tag = 26; tag <= 51; tag++) {
      final value = fields[tag.toString()];
      if (value == null) continue;
      final nested = _parseFields(value);
      final gui = nested['00']?.toUpperCase();
      if (gui == 'BR.GOV.BCB.PIX') return nested;
    }
    return const {};
  }

  static Map<String, String> _parseFields(String payload) {
    final fields = <String, String>{};
    var index = 0;

    while (index + 4 <= payload.length) {
      final id = payload.substring(index, index + 2);
      final length = int.tryParse(payload.substring(index + 2, index + 4));
      if (length == null || length < 0) break;

      final valueStart = index + 4;
      final valueEnd = valueStart + length;
      if (valueEnd > payload.length) break;

      fields[id] = payload.substring(valueStart, valueEnd);
      index = valueEnd;
    }

    return fields;
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String? _normalizeLocationUrl(String? raw) {
    final location = _blankToNull(raw);
    if (location == null) return null;

    final uri = Uri.tryParse(location);
    if (uri != null && uri.hasScheme) return location;

    final httpsUri = Uri.tryParse('https://$location');
    return httpsUri == null || !httpsUri.hasAuthority
        ? location
        : httpsUri.toString();
  }

  static String? _normalizeMerchantName(String? raw) {
    final value = _blankToNull(raw);
    if (value == null) return null;

    final folded = _fold(value);
    if (folded.contains('EQUATORIAL GOIAS')) {
      return 'EQUATORIAL GOIAS DISTRIBUIDORA DE ENERGIA S/A';
    }

    return value;
  }

  static String _fold(String value) {
    return value
        .toUpperCase()
        .replaceAll('Á', 'A')
        .replaceAll('À', 'A')
        .replaceAll('Â', 'A')
        .replaceAll('Ã', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Ê', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ô', 'O')
        .replaceAll('Õ', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ü', 'U')
        .replaceAll('Ç', 'C');
  }
}

final class PixPayloadData {
  const PixPayloadData({
    required this.rawPayload,
    this.key,
    this.locationUrl,
    this.merchantName,
    this.city,
    this.txId,
    this.amount,
  });

  final String rawPayload;
  final String? key;
  final String? locationUrl;
  final String? merchantName;
  final String? city;
  final String? txId;
  final Money? amount;
}
