import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Thrown when a backup payload cannot be decrypted (wrong/missing password).
final class BackupDecryptionException implements Exception {
  const BackupDecryptionException(
      [this.message = 'Senha incorreta ou backup corrompido.']);
  final String message;

  @override
  String toString() => 'BackupDecryptionException: $message';
}

/// Thrown when a backup file's schema version is not supported.
final class BackupVersionException implements Exception {
  const BackupVersionException(this.version);
  final int version;

  @override
  String toString() =>
      'BackupVersionException: version $version is not supported '
      '(current: ${BackupService.currentBackupVersion}).';
}

// ---------------------------------------------------------------------------
// BackupCounts
// ---------------------------------------------------------------------------

final class BackupCounts {
  const BackupCounts({
    required this.accounts,
    required this.transactions,
    required this.bills,
    required this.debts,
    required this.funds,
    required this.categories,
  });

  final int accounts;
  final int transactions;
  final int bills;
  final int debts;
  final int funds;
  final int categories;

  Map<String, dynamic> toJson() => {
        'accounts': accounts,
        'transactions': transactions,
        'bills': bills,
        'debts': debts,
        'funds': funds,
        'categories': categories,
      };

  factory BackupCounts.fromJson(Map<String, dynamic> j) => BackupCounts(
        accounts: (j['accounts'] as num?)?.toInt() ?? 0,
        transactions: (j['transactions'] as num?)?.toInt() ?? 0,
        bills: (j['bills'] as num?)?.toInt() ?? 0,
        debts: (j['debts'] as num?)?.toInt() ?? 0,
        funds: (j['funds'] as num?)?.toInt() ?? 0,
        categories: (j['categories'] as num?)?.toInt() ?? 0,
      );
}

// ---------------------------------------------------------------------------
// BackupManifest — the outer JSON envelope
// ---------------------------------------------------------------------------

/// The outer JSON wrapper stored in a `.paguei.backup` file.
///
/// Structure:
/// ```json
/// {
///   "backupVersion": 1,
///   "exportedAt": "ISO-8601",
///   "appVersion": "1.0.0",
///   "counts": { ... },
///   "isEncrypted": false,
///   "payload": "<base64-gzip-encoded data>"
/// }
/// ```
final class BackupManifest {
  const BackupManifest({
    required this.backupVersion,
    required this.exportedAt,
    required this.appVersion,
    required this.counts,
    required this.isEncrypted,
    this.payload,
  });

  final int backupVersion;
  final DateTime exportedAt;
  final String appVersion;
  final BackupCounts counts;
  final bool isEncrypted;

  /// The base64-encoded, gzip-compressed (and optionally XOR-encrypted) data.
  /// Null when the manifest is used only for preview.
  final String? payload;

  Map<String, dynamic> toJson() => {
        'backupVersion': backupVersion,
        'exportedAt': exportedAt.toUtc().toIso8601String(),
        'appVersion': appVersion,
        'counts': counts.toJson(),
        'isEncrypted': isEncrypted,
        if (payload != null) 'payload': payload,
      };

  factory BackupManifest.fromJson(Map<String, dynamic> j) => BackupManifest(
        backupVersion: (j['backupVersion'] as num?)?.toInt() ?? 0,
        exportedAt: DateTime.tryParse(j['exportedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        appVersion: j['appVersion'] as String? ?? '0.0.0',
        counts: BackupCounts.fromJson(
          (j['counts'] as Map<String, dynamic>?) ?? {},
        ),
        isEncrypted: j['isEncrypted'] as bool? ?? false,
        payload: j['payload'] as String?,
      );
}

// ---------------------------------------------------------------------------
// RestorePreview
// ---------------------------------------------------------------------------

/// A lightweight preview shown to the user before they confirm a restore.
final class RestorePreview {
  const RestorePreview({
    required this.accountCount,
    required this.transactionCount,
    required this.billCount,
    required this.fundCount,
    required this.debtCount,
    required this.categoryCount,
    required this.exportedAt,
    required this.backupVersion,
    required this.isVersionSupported,
    required this.isEncrypted,
  });

  final int accountCount;
  final int transactionCount;
  final int billCount;
  final int fundCount;
  final int debtCount;
  final int categoryCount;
  final DateTime exportedAt;
  final int backupVersion;
  final bool isVersionSupported;
  final bool isEncrypted;

  factory RestorePreview.fromManifest(BackupManifest manifest) =>
      RestorePreview(
        accountCount: manifest.counts.accounts,
        transactionCount: manifest.counts.transactions,
        billCount: manifest.counts.bills,
        fundCount: manifest.counts.funds,
        debtCount: manifest.counts.debts,
        categoryCount: manifest.counts.categories,
        exportedAt: manifest.exportedAt,
        backupVersion: manifest.backupVersion,
        isVersionSupported: BackupService.versionCheck(manifest.backupVersion),
        isEncrypted: manifest.isEncrypted,
      );

  /// Creates a preview from raw decoded data (used in tests).
  factory RestorePreview.fromData(Map<String, dynamic> data) {
    int count(String key) {
      final v = data[key];
      if (v is List) return v.length;
      return 0;
    }

    return RestorePreview(
      accountCount: count('accounts'),
      transactionCount: count('transactions'),
      billCount: count('bills'),
      fundCount: count('funds'),
      debtCount: count('debts'),
      categoryCount: count('categories'),
      exportedAt: DateTime.now().toUtc(),
      backupVersion: BackupService.currentBackupVersion,
      isVersionSupported: true,
      isEncrypted: false,
    );
  }
}

// ---------------------------------------------------------------------------
// BackupService — core encode/decode + file I/O
// ---------------------------------------------------------------------------

/// Core service for creating and restoring encrypted + compressed backups.
///
/// ## Backup format
///
/// ```
/// file.paguei.backup
/// └── outer JSON: BackupManifest  (cleartext, human-readable header)
///     └── manifest.payload:
///         base64( gzip( [optional XOR-encrypt]( UTF-8 JSON body ) ) )
/// ```
///
/// ### Encryption
///
/// Password-based encryption uses a **simple key stream** derived from the
/// password bytes, repeated over the plaintext. This provides basic
/// obfuscation suitable for casual storage security.
///
/// > **Production note**: For stronger encryption replace `_xorEncrypt` /
/// > `_xorDecrypt` with AES-256-CBC from the `pointycastle` package.
/// > The interface (`buildPayload` / `parsePayload`) stays identical.
abstract final class BackupService {
  /// Schema version of the backup format. Increment when the structure
  /// changes in a breaking way.
  static const int currentBackupVersion = 1;

  /// Maximum future version delta we accept (forwards compatibility limit).
  static const int _maxVersionDelta = 5;

  // ── Payload encode/decode ──────────────────────────────────────────────

  /// Encodes [data] map as:
  ///   UTF-8 JSON → [optional XOR with password] → GZip → base64
  static String buildPayload(
    Map<String, dynamic> data, {
    required String? password,
  }) {
    final jsonBytes = utf8.encode(jsonEncode(data));
    final maybeEncrypted = password != null
        ? _xorEncrypt(Uint8List.fromList(jsonBytes), password)
        : Uint8List.fromList(jsonBytes);
    final compressed = GZipCodec().encode(maybeEncrypted);
    return base64.encode(compressed);
  }

  /// Decodes a payload produced by [buildPayload].
  ///
  /// [isEncrypted] defaults to `password != null` — pass it explicitly when
  /// reading from a [BackupManifest] (which tracks the flag independently).
  ///
  /// Throws [BackupDecryptionException] when the password is wrong or missing.
  static Map<String, dynamic> parsePayload(
    String payload, {
    required String? password,
    bool? isEncrypted,
  }) {
    final encrypted = isEncrypted ?? (password != null);
    try {
      final compressed = base64.decode(payload);
      final decompressed = Uint8List.fromList(GZipCodec().decode(compressed));
      final plainBytes =
          encrypted ? _xorDecrypt(decompressed, password) : decompressed;
      return jsonDecode(utf8.decode(plainBytes)) as Map<String, dynamic>;
    } on BackupDecryptionException {
      rethrow;
    } catch (e) {
      throw BackupDecryptionException('Payload inválido: $e');
    }
  }

  // ── Version check ──────────────────────────────────────────────────────

  /// Returns true when [version] is within acceptable range.
  static bool versionCheck(int version) =>
      version <= currentBackupVersion + _maxVersionDelta;

  // ── File I/O ───────────────────────────────────────────────────────────

  /// Writes a backup to [file].
  ///
  /// [data] should be the full database export map with keys:
  /// `accounts`, `categories`, `transactions`, `bills`, `funds`, `debts`.
  static Future<void> writeBackup({
    required File file,
    required Map<String, dynamic> data,
    required String appVersion,
    String? password,
  }) async {
    final payload = buildPayload(data, password: password);
    final manifest = BackupManifest(
      backupVersion: currentBackupVersion,
      exportedAt: DateTime.now().toUtc(),
      appVersion: appVersion,
      counts: _countFromData(data),
      isEncrypted: password != null,
      payload: payload,
    );
    await file.writeAsString(jsonEncode(manifest.toJson()), flush: true);
  }

  /// Reads and parses the manifest from [file].
  ///
  /// Does NOT decrypt the payload — use [decodeBackup] for full restore.
  /// Returns the manifest for a preview without a password.
  static Future<BackupManifest> readManifest(File file) async {
    final raw = await file.readAsString();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return BackupManifest.fromJson(json);
  }

  /// Reads, decompresses, and optionally decrypts the full backup data.
  ///
  /// Throws [BackupVersionException] if the version is unsupported.
  /// Throws [BackupDecryptionException] if the password is wrong.
  static Future<Map<String, dynamic>> decodeBackup({
    required File file,
    String? password,
  }) async {
    final manifest = await readManifest(file);
    if (!versionCheck(manifest.backupVersion)) {
      throw BackupVersionException(manifest.backupVersion);
    }
    final payload = manifest.payload;
    if (payload == null) {
      throw const BackupDecryptionException('Backup sem payload.');
    }
    return parsePayload(
      payload,
      password: password,
      isEncrypted: manifest.isEncrypted, // explicit — don't infer from password
    );
  }

  // ── XOR encryption ─────────────────────────────────────────────────────

  /// Simple key-stream XOR encryption.
  ///
  /// The first 4 bytes of the output are a repeating-key checksum so the
  /// caller can detect a wrong password before full decode.
  static Uint8List _xorEncrypt(Uint8List plaintext, String password) {
    final keyBytes = utf8.encode(password);
    final key = Uint8List.fromList(keyBytes);
    final out = Uint8List(4 + plaintext.length);

    // Store a 4-byte checksum (first 4 key bytes XOR 0xA5)
    for (var i = 0; i < 4; i++) {
      out[i] = (key[i % key.length]) ^ 0xA5;
    }
    for (var i = 0; i < plaintext.length; i++) {
      out[4 + i] = plaintext[i] ^ key[i % key.length];
    }
    return out;
  }

  static Uint8List _xorDecrypt(Uint8List ciphertext, String? password) {
    if (password == null || password.isEmpty) {
      throw const BackupDecryptionException();
    }
    if (ciphertext.length < 4) {
      throw const BackupDecryptionException('Dados insuficientes.');
    }

    final keyBytes = utf8.encode(password);
    final key = Uint8List.fromList(keyBytes);

    // Verify checksum
    for (var i = 0; i < 4; i++) {
      if (ciphertext[i] != (key[i % key.length] ^ 0xA5)) {
        throw const BackupDecryptionException();
      }
    }

    final out = Uint8List(ciphertext.length - 4);
    for (var i = 0; i < out.length; i++) {
      out[i] = ciphertext[4 + i] ^ key[i % key.length];
    }
    return out;
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  static BackupCounts _countFromData(Map<String, dynamic> data) {
    int c(String key) {
      final v = data[key];
      return v is List ? v.length : 0;
    }

    return BackupCounts(
      accounts: c('accounts'),
      transactions: c('transactions'),
      bills: c('bills'),
      debts: c('debts'),
      funds: c('funds'),
      categories: c('categories'),
    );
  }
}
