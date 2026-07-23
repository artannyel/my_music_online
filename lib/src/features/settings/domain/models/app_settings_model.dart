class AppSettingsModel {
  final String ytCookiesText;
  final DateTime updatedAt;
  final bool isValid;

  const AppSettingsModel({
    required this.ytCookiesText,
    required this.updatedAt,
    this.isValid = false,
  });

  bool get hasCookies => ytCookiesText.isNotEmpty;
}
