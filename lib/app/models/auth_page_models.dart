class AuthPageResponse {
  const AuthPageResponse({
    required this.headerBrand,
    required this.headerTitle,
    required this.introTitle,
    required this.introDescription,
    required this.fields,
    this.helpText,
    required this.primaryActionLabel,
    required this.socialActionLabel,
    required this.switchPrompt,
    required this.switchActionLabel,
    required this.footerTagline,
  });

  final String headerBrand;
  final String headerTitle;
  final String introTitle;
  final String introDescription;
  final List<AuthFieldConfig> fields;
  final String? helpText;
  final String primaryActionLabel;
  final String socialActionLabel;
  final String switchPrompt;
  final String switchActionLabel;
  final String footerTagline;

  factory AuthPageResponse.fromJson(Map<String, dynamic> json) {
    return AuthPageResponse(
      headerBrand: (json['headerBrand'] ?? '').toString(),
      headerTitle: (json['headerTitle'] ?? '').toString(),
      introTitle: (json['introTitle'] ?? '').toString(),
      introDescription: (json['introDescription'] ?? '').toString(),
      fields: ((json['fields'] as List?) ?? const [])
          .map((item) => AuthFieldConfig.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      helpText: json['helpText']?.toString(),
      primaryActionLabel: (json['primaryActionLabel'] ?? '').toString(),
      socialActionLabel: (json['socialActionLabel'] ?? '').toString(),
      switchPrompt: (json['switchPrompt'] ?? '').toString(),
      switchActionLabel: (json['switchActionLabel'] ?? '').toString(),
      footerTagline: (json['footerTagline'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'headerBrand': headerBrand,
      'headerTitle': headerTitle,
      'introTitle': introTitle,
      'introDescription': introDescription,
      'fields': fields.map((item) => item.toJson()).toList(),
      'helpText': helpText,
      'primaryActionLabel': primaryActionLabel,
      'socialActionLabel': socialActionLabel,
      'switchPrompt': switchPrompt,
      'switchActionLabel': switchActionLabel,
      'footerTagline': footerTagline,
    };
  }
}

class AuthFieldConfig {
  const AuthFieldConfig({
    required this.label,
  });

  final String label;

  factory AuthFieldConfig.fromJson(Map<String, dynamic> json) {
    return AuthFieldConfig(
      label: (json['label'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'label': label};
  }
}
