abstract class SettingsRepository {
  Future<void> saveCookies(String cookiesText);
  Future<String?> getCookies();
  Stream<String?> watchCookies();
  Future<void> removeCookies();
}
