import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// FirebaseService encapsula a inicialização segura e em tempo de execução dos serviços do Firebase.
class FirebaseService {
  FirebaseService._();

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase init notice: $e');
    }
  }
}
