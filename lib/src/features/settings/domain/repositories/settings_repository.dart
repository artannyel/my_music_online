abstract class SettingsRepository {
  Future<void> saveCookies(String cookiesText, {required String userId});
  Future<String?> getCookies({required String userId});
  Stream<String?> watchCookies({required String userId});
  Future<void> removeCookies({required String userId});
}
