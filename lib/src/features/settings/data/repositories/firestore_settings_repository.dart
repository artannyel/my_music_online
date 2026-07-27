import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/settings_repository.dart';

class FirestoreSettingsRepository implements SettingsRepository {
  final FirebaseFirestore _firestore;

  FirestoreSettingsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _cookiesDoc(String userId) =>
      _firestore.collection('users').doc(userId).collection('config').doc('ytmusic_cookies');

  @override
  Future<void> saveCookies(String cookiesText, {required String userId}) async {
    await _cookiesDoc(userId).set({
      'cookiesText': cookiesText,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<String?> getCookies({required String userId}) async {
    final doc = await _cookiesDoc(userId).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    final text = data['cookiesText'] as String?;
    return text?.isNotEmpty == true ? text : null;
  }

  @override
  Stream<String?> watchCookies({required String userId}) {
    return _cookiesDoc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data();
      if (data == null) return null;
      final text = data['cookiesText'] as String?;
      return text?.isNotEmpty == true ? text : null;
    });
  }

  @override
  Future<void> removeCookies({required String userId}) async {
    await _cookiesDoc(userId).delete();
  }
}
