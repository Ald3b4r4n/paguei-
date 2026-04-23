import 'package:paguei/application/scanner/pix_payload_parser.dart';
import 'package:paguei/domain/entities/parsed_bill_data.dart';
import 'package:paguei/domain/entities/scan_source_type.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/application/scanner/boleto_code_parser.dart';

/// Pure utility class — no dependencies, no I/O.
///
/// Takes raw text (from OCR, PDF or TXT import) and extracts structured
/// boleto/PIX data using regex heuristics. Accuracy is intentionally
/// conservative: confidence scores reflect what was actually found.
final class BillExtractionHeuristics {
  const BillExtractionHeuristics._();

  // -------------------------------------------------------------------------
  // Regex patterns
  // -------------------------------------------------------------------------

  /// 47-digit linha digitável with standard dot-space formatting.
  static final _linhaDigitavel47 = RegExp(
    r'\d{5}\.\d{5}\s+\d{5}\.\d{6}\s+\d{5}\.\d{6}\s+\d\s+\d{14}',
  );

  /// Bare 44 or 47-digit sequences (no other digits immediately adjacent).
  static final _rawBarcode = RegExp(r'(?<!\d)(\d{44}|\d{47})(?!\d)');

  /// PT-BR currency: "R$ 1.234,56" or "R$150,00" (greedy on leading digits).
  static final _amount = RegExp(
    r'R\$\s*(?:\*+\s*)?(\d{1,3}(?:\.\d{3})*,\d{2})(?!\d)',
    caseSensitive: false,
  );

  /// Labeled amount: "Valor:", "Total:", "Cobrado:", etc.
  static final _labeledAmount = RegExp(
    r'(?:valor(?:\s+do\s+documento)?|total(?:\s+a\s+pagar)?|cobrado|documento)'
    r'\s*[:\-]?\s*R\$\s*(?:\*+\s*)?(\d{1,3}(?:\.\d{3})*,\d{2})(?!\d)',
    caseSensitive: false,
  );

  /// Date preceded by due-date labels.
  static final _labeledDate = RegExp(
    r'(?:vencimento|data\s+de\s+vencimento|vence(?:\s+em)?|data\s+limite)'
    r'\s*[:\-]?\s*(\d{2}/\d{2}/\d{4})',
    caseSensitive: false,
  );

  /// Any dd/mm/yyyy date as fallback.
  static final _anyDate = RegExp(r'\b(\d{2}/\d{2}/\d{4})\b');

  /// Beneficiary / cedente labels.
  static final _beneficiary = RegExp(
    r'(?:benefici[aá]rio|cedente|favorecido|raz[aã]o\s+social)'
    r'\s*[:\-]?\s*([^\n\r]{3,100})',
    caseSensitive: false,
  );

  static const _knownBeneficiaries = <_KnownEntity>[
    _KnownEntity(
      match: 'EQUATORIAL GOIAS DISTRIBUIDORA DE ENERGIA S/A',
      displayName: 'Equatorial Goiás Distribuidora de Energia S/A',
    ),
    _KnownEntity(
      match: 'EQUATORIAL GOIAS',
      displayName: 'Equatorial Goiás Distribuidora de Energia S/A',
    ),
  ];

  static const _knownBanks = <_KnownEntity>[
    _KnownEntity(match: 'BANCO ITAU', displayName: 'Banco Itaú'),
    _KnownEntity(match: 'ITAU', displayName: 'Banco Itaú'),
    _KnownEntity(match: 'BANCO DO BRASIL', displayName: 'Banco do Brasil'),
    _KnownEntity(match: 'BRADESCO', displayName: 'Banco Bradesco'),
    _KnownEntity(match: 'SANTANDER', displayName: 'Banco Santander'),
    _KnownEntity(
        match: 'CAIXA ECONOMICA FEDERAL',
        displayName: 'Caixa Econômica Federal'),
  ];

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  static ParsedBillData extractFromText(
    String rawText, {
    ScanSourceType source = ScanSourceType.image,
  }) {
    if (rawText.trim().isEmpty) {
      return ParsedBillData(source: source, confidence: 0.0, rawText: rawText);
    }

    final barcode = _extractBarcode(rawText);
    final boleto = barcode == null ? null : BoletoCodeParser.tryParse(barcode);
    final pixCode = PixPayloadParser.extractPayload(rawText);
    final pix = pixCode == null ? null : PixPayloadParser.parse(pixCode);

    final textAmount = _extractAmount(rawText);
    final textDueDate = _extractDueDate(rawText);
    final amount = boleto?.amount ?? pix?.amount ?? textAmount;
    final dueDate = boleto?.dueDate ?? textDueDate;
    final beneficiary =
        _extractBeneficiary(rawText, pixMerchant: pix?.merchantName);
    final issuer = boleto?.bankName ?? _extractBankName(rawText);
    final warnings = _buildWarnings(
      boleto: boleto,
      amountCandidates: _extractAmountCandidates(rawText),
      dateCandidates: _extractDateCandidates(rawText),
    );

    final confidence = _score(
      hasBarcode: barcode != null,
      hasPixCode: pixCode != null,
      hasAmount: amount != null,
      hasDueDate: dueDate != null,
      hasBeneficiary: beneficiary != null,
      hasIssuer: issuer != null,
    );

    return ParsedBillData(
      source: source,
      confidence: confidence,
      barcode: barcode,
      pixCode: pixCode,
      amount: amount,
      dueDate: dueDate,
      beneficiary: beneficiary,
      issuer: issuer,
      pixKey: pix?.key ?? pix?.locationUrl,
      pixLocationUrl: pix?.locationUrl,
      pixMerchantName: pix?.merchantName,
      pixCity: pix?.city,
      pixTxId: pix?.txId,
      rawText: rawText,
      warnings: warnings,
    );
  }

  // -------------------------------------------------------------------------
  // Private extraction helpers
  // -------------------------------------------------------------------------

  static String? _extractBarcode(String text) {
    // Try formatted 47-digit first (most precise match).
    final formatted47 = _linhaDigitavel47.firstMatch(text);
    if (formatted47 != null) {
      final stripped = formatted47.group(0)!.replaceAll(RegExp(r'[\s.]'), '');
      if (stripped.length == 47) return stripped;
    }

    // Try raw 44/47 digit sequence.
    final raw = _rawBarcode.firstMatch(text);
    if (raw != null) {
      final digits = raw.group(1)!;
      if (digits.length == 44 || digits.length == 47) return digits;
    }
    return null;
  }

  static Money? _extractAmount(String text) {
    // Prefer labeled match (higher precision).
    final labeled = _labeledAmount.firstMatch(text);
    final raw = labeled ?? _amount.firstMatch(text);
    if (raw == null) return null;

    final group = labeled != null ? raw.group(1) : raw.group(1);
    if (group == null) return null;

    final parsed = _parsePtBrAmount(group);
    if (parsed == null || parsed == 0.0) return null;
    return Money.fromDouble(parsed);
  }

  static List<Money> _extractAmountCandidates(String text) {
    final candidates = <Money>[];
    final seen = <int>{};

    void add(String? raw) {
      if (raw == null) return;
      final parsed = _parsePtBrAmount(raw);
      if (parsed == null || parsed == 0.0) return;
      final money = Money.fromDouble(parsed);
      if (seen.add(money.cents)) candidates.add(money);
    }

    for (final match in _labeledAmount.allMatches(text)) {
      add(match.group(1));
    }
    for (final match in _amount.allMatches(text)) {
      add(match.group(1));
    }
    return candidates;
  }

  static double? _parsePtBrAmount(String formatted) {
    // "1.234,56" → 1234.56
    final normalized = formatted.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  static DateTime? _extractDueDate(String text) {
    // Prefer labeled date.
    final labeled = _labeledDate.firstMatch(text);
    final match = labeled ?? _anyDate.firstMatch(text);
    if (match == null) return null;

    final dateStr = match.group(1)!;
    return _parsePtBrDate(dateStr);
  }

  static List<DateTime> _extractDateCandidates(String text) {
    final dates = <DateTime>[];
    final seen = <String>{};
    for (final match in _anyDate.allMatches(text)) {
      final date = _parsePtBrDate(match.group(1)!);
      if (date == null) continue;
      final key = '${date.year}-${date.month}-${date.day}';
      if (seen.add(key)) dates.add(date);
    }
    return dates;
  }

  static DateTime? _parsePtBrDate(String ddMmYyyy) {
    final parts = ddMmYyyy.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  static String? _extractBeneficiary(String text, {String? pixMerchant}) {
    final foldedText = _fold(text);
    for (final entity in _knownBeneficiaries) {
      if (foldedText.contains(entity.match)) return entity.displayName;
    }

    final match = _beneficiary.firstMatch(text);
    final labeled = match == null ? null : _cleanBeneficiary(match.group(1));
    if (labeled != null && !_looksLikeCustomer(labeled)) return labeled;

    if (pixMerchant != null && !_looksLikeCustomer(pixMerchant)) {
      return pixMerchant.trim();
    }
    return null;
  }

  static String? _extractBankName(String text) {
    final foldedText = _fold(text);
    for (final bank in _knownBanks) {
      if (foldedText.contains(bank.match)) return bank.displayName;
    }
    return null;
  }

  static String? _cleanBeneficiary(String? value) {
    if (value == null) return null;
    final cleaned = value
        .split(RegExp(
          r'\s{2,}|CNPJ|CPF|Ag[êe]ncia|Código|Nosso\s+Número',
          caseSensitive: false,
        ))
        .first
        .trim();
    if (cleaned.length < 3) return null;
    return cleaned;
  }

  static bool _looksLikeCustomer(String value) {
    final folded = _fold(value);
    return folded.contains('RAYLANE DE NORONHA CARDOSO') ||
        folded.contains('CNPJ/CPF') ||
        folded.contains('CLIENTE') ||
        folded.contains('RUA ') ||
        folded.contains('CEP:');
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

  static List<String> _buildWarnings({
    required BoletoCodeParseResult? boleto,
    required List<Money> amountCandidates,
    required List<DateTime> dateCandidates,
  }) {
    final warnings = <String>[];

    if (boleto != null && !boleto.hasValidChecksum) {
      warnings.add('Código de barras lido, mas com validação incompleta.');
    }

    final boletoAmount = boleto?.amount;
    if (boletoAmount != null &&
        amountCandidates.any(
          (candidate) => (candidate.amount - boletoAmount.amount).abs() >= 0.01,
        )) {
      warnings.add(
        'Outros valores apareceram no documento; o valor do código validado foi usado.',
      );
    }

    final boletoDueDate = boleto?.dueDate;
    if (boletoDueDate != null &&
        dateCandidates
            .any((candidate) => !_sameDate(candidate, boletoDueDate))) {
      warnings.add(
        'Outras datas apareceram no documento; o vencimento do código validado foi usado.',
      );
    }

    return warnings;
  }

  static bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // -------------------------------------------------------------------------
  // Confidence scoring
  // -------------------------------------------------------------------------

  /// Higher weight for structural proof (barcode/PIX); supplementary weight
  /// for metadata fields. Maximum score = 1.0.
  static double _score({
    required bool hasBarcode,
    required bool hasPixCode,
    required bool hasAmount,
    required bool hasDueDate,
    required bool hasBeneficiary,
    required bool hasIssuer,
  }) {
    var score = 0.0;

    if (hasBarcode) score += 0.55;
    if (hasPixCode) score += 0.15;
    if (hasAmount) score += 0.15;
    if (hasDueDate) score += 0.12;
    if (hasBeneficiary) score += 0.10;
    if (hasIssuer) score += 0.05;

    return score.clamp(0.0, 1.0);
  }
}

final class _KnownEntity {
  const _KnownEntity({
    required this.match,
    required this.displayName,
  });

  final String match;
  final String displayName;
}
