import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/settings_repository.dart';

class FirestoreSettingsRepository implements SettingsRepository {
  final FirebaseFirestore _firestore;

  FirestoreSettingsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _cookiesDoc =>
      _firestore.collection('config').doc('ytmusic_cookies');

  @override
  Future<void> saveCookies(String cookiesText) async {
    await _cookiesDoc.set({
      'cookiesText': cookiesText,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<String?> getCookies() async {
    final doc = await _cookiesDoc.get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    final text = data['cookiesText'] as String?;
    return text?.isNotEmpty == true ? text : null;
  }

  @override
  Stream<String?> watchCookies() {
    return _cookiesDoc.snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data();
      if (data == null) return null;
      final text = data['cookiesText'] as String?;
      return text?.isNotEmpty == true ? text : null;
    });
  }

  @override
  Future<void> removeCookies() async {
    await _cookiesDoc.delete();
  }
}
