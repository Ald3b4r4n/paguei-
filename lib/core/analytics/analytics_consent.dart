/// LGPD-compliant analytics consent model.
///
/// Brazil's Lei Geral de Proteção de Dados (LGPD, Law 13.709/2018) requires
/// explicit, informed consent before collecting behavioural data. This model
/// captures:
/// - Whether the user has been **asked** (prevents re-showing the dialog).
/// - The user's **choice** (opted-in or opted-out).
/// - The **timestamp** of consent (needed for audit trails).
///
/// ## Consent flow
///
/// ```
/// App first launch
///   → ConsentDialogScreen shown (T146)
///   → User taps "Permitir" or "Não, obrigado"
///   → AnalyticsConsentRepository.save(consent)
///   → AnalyticsService enabled/disabled accordingly
/// ```
final class AnalyticsConsent {
  const AnalyticsConsent({
    required this.hasBeenAsked,
    required this.isGranted,
    this.grantedAt,
  });

  /// Returns a fresh "never asked" state.
  const AnalyticsConsent.initial()
      : hasBeenAsked = false,
        isGranted = false,
        grantedAt = null;

  /// Whether the consent dialog has been shown at least once.
  final bool hasBeenAsked;

  /// True if the user explicitly opted in.
  final bool isGranted;

  /// UTC timestamp of when consent was last changed.
  final DateTime? grantedAt;

  AnalyticsConsent copyWith({
    bool? hasBeenAsked,
    bool? isGranted,
    DateTime? grantedAt,
  }) =>
      AnalyticsConsent(
        hasBeenAsked: hasBeenAsked ?? this.hasBeenAsked,
        isGranted: isGranted ?? this.isGranted,
        grantedAt: grantedAt ?? this.grantedAt,
      );

  Map<String, dynamic> toMap() => {
        'hasBeenAsked': hasBeenAsked,
        'isGranted': isGranted,
        'grantedAt': grantedAt?.toUtc().toIso8601String(),
      };

  factory AnalyticsConsent.fromMap(Map<String, dynamic> m) => AnalyticsConsent(
        hasBeenAsked: m['hasBeenAsked'] as bool? ?? false,
        isGranted: m['isGranted'] as bool? ?? false,
        grantedAt: m['grantedAt'] != null
            ? DateTime.tryParse(m['grantedAt'] as String)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      other is AnalyticsConsent &&
      other.hasBeenAsked == hasBeenAsked &&
      other.isGranted == isGranted;

  @override
  int get hashCode => Object.hash(hasBeenAsked, isGranted);

  @override
  String toString() =>
      'AnalyticsConsent(asked: $hasBeenAsked, granted: $isGranted)';
}
