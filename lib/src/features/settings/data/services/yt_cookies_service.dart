import 'package:cookie_jar/cookie_jar.dart' as cookie_jar;
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:newpipeextractor_dart/newpipeextractor_dart.dart';

import '../repositories/firestore_settings_repository.dart';
import '../../presentation/controllers/settings_controller.dart';

/// Normaliza o texto bruto de cookies.txt para uma string de pares
/// "nome=valor" separados por "; ".
String _normalizeCookies(String raw) {
  final pairs = <String>{};
  final lines = raw.split('\n');

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

    if (trimmed.contains('\t')) {
      final parts = trimmed.split('\t');
      if (parts.length >= 7) {
        final name = parts[parts.length - 2].trim();
        final value = parts.last.trim();
        if (name.isNotEmpty) {
          pairs.add('$name=$value');
        }
        continue;
      }
    }

    if (trimmed.contains('; ')) {
      for (final segment in trimmed.split('; ')) {
        final seg = segment.trim();
        if (seg.contains('=') && !seg.startsWith('#')) {
          pairs.add(seg);
        }
      }
      continue;
    }

    if (trimmed.contains('=')) {
      pairs.add(trimmed);
    }
  }

  return pairs.join('; ');
}

/// Aplica cookies às bibliotecas que consomem YouTube.
void applyCookies(String rawCookies) {
  if (rawCookies.trim().isEmpty) return;

  final normalized = _normalizeCookies(rawCookies);
  if (normalized.isEmpty) return;

  _applyToYTMusic(normalized);
  _applyToNewpipe(normalized);
}

void _applyToYTMusic(String cookies) {
  final ytMusic = YTMusic();
  final jar = ytMusic.cookieJar;

  for (final cookieString in cookies.split('; ')) {
    try {
      final cookie = cookie_jar.Cookie.fromSetCookieValue(cookieString);
      jar.saveFromResponse(
        Uri.parse('https://www.youtube.com/'),
        [cookie],
      );
    } catch (_) {}
  }
}

void _applyToNewpipe(String cookies) {
  try {
    CookieExtractor.setCookie(cookies);
  } catch (_) {}
}

/// Carrega cookies do Firestore (por usuário) e inicializa as bibliotecas.
/// Chamado em main.dart ANTES do runApp.
Future<void> initializeLibrariesWithCookies() async {
  final repo = FirestoreSettingsRepository();
  final ytMusic = YTMusic();

  // Tenta carregar cookies do usuário atual (Firebase Auth restaura sessão automaticamente)
  String? rawCookies;
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      rawCookies = await repo.getCookies(userId: user.uid);
    } catch (_) {}
  }

  if (rawCookies != null && rawCookies.isNotEmpty) {
    final normalized = _normalizeCookies(rawCookies);
    await ytMusic.initialize(
      cookies: normalized,
      gl: 'BR',
      hl: 'pt-BR',
    );
    _applyToNewpipe(normalized);
  } else {
    await ytMusic.initialize(gl: 'BR', hl: 'pt-BR');
  }
}

/// Provider que observa mudanças nos cookies e reaplica às bibliotecas.
final ytCookiesWatcherProvider = Provider<void>((ref) {
  final rawCookies = ref.watch(ytCookiesProvider).valueOrNull;
  if (rawCookies != null && rawCookies.isNotEmpty) {
    applyCookies(rawCookies);
  }
});
