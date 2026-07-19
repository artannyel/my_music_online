import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import 'package:just_audio/just_audio.dart';
import '../../domain/models/player_state_model.dart';

/// Serviço encapsulado do Player de Áudio combinando just_audio com resolução
/// de URLs de stream de áudio via dart_ytmusic_api e cabeçalhos User-Agent adequados.
class AudioPlayerService {
  final AudioPlayer _audioPlayer;
  final YTMusic _ytMusic;

  AudioPlayerService({
    AudioPlayer? audioPlayer,
    YTMusic? ytMusic,
  })  : _audioPlayer = audioPlayer ?? AudioPlayer(),
        _ytMusic = ytMusic ?? YTMusic();

  AudioPlayer get player => _audioPlayer;

  /// Resolve a URL de stream de áudio direta de uma faixa do YouTube Music
  Future<String?> resolveAudioUrl(String videoId) async {
    try {
      await _ytMusic.initialize(gl: 'BR', hl: 'pt-BR');
      final songFull = await _ytMusic.getSong(videoId);

      List<dynamic> allFormats = [
        ...songFull.adaptiveFormats,
        ...songFull.formats,
      ];

      final audioFormats = allFormats.where((f) {
        final mime = f['mimeType']?.toString().toLowerCase() ?? '';
        return mime.contains('audio');
      }).toList();

      if (audioFormats.isNotEmpty) {
        // Ordena por maior bitrate
        audioFormats.sort((a, b) {
          final bitrateA = (a['bitrate'] as num?) ?? 0;
          final bitrateB = (b['bitrate'] as num?) ?? 0;
          return bitrateB.compareTo(bitrateA);
        });

        for (final format in audioFormats) {
          String? url = format['url']?.toString();

          // Tenta extrair a URL se o formato usar signatureCipher / cipher
          if (url == null || url.isEmpty) {
            final cipher = format['signatureCipher']?.toString() ??
                format['cipher']?.toString();
            if (cipher != null && cipher.isNotEmpty) {
              final queryParams = Uri.splitQueryString(cipher);
              url = queryParams['url'];
            }
          }

          if (url != null && url.isNotEmpty) {
            return url;
          }
        }
      }

      // Se nenhum formato de áudio exclusivo for encontrado, tenta qualquer formato com URL
      for (final format in allFormats) {
        final String? url = format['url']?.toString();
        if (url != null && url.isNotEmpty) {
          return url;
        }
      }
    } catch (_) {}

    return null;
  }

  /// Inicia a reprodução de uma nova faixa ou retoma a atual
  Future<void> playTrack(AudioTrackModel track) async {
    String? streamUrl = track.audioUrl;

    if (streamUrl == null || streamUrl.isEmpty) {
      streamUrl = await resolveAudioUrl(track.videoId);
    }

    if (streamUrl != null && streamUrl.isNotEmpty) {
      // Configura o AudioSource com o User-Agent do YouTube para evitar HTTP 403 Forbidden no ExoPlayer
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(streamUrl),
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
          },
        ),
      );
      await _audioPlayer.play();
    } else {
      throw Exception('Não foi possível obter a URL de áudio para ${track.title}');
    }
  }

  Future<void> play() async => await _audioPlayer.play();
  Future<void> pause() async => await _audioPlayer.pause();
  Future<void> stop() async => await _audioPlayer.stop();
  Future<void> seek(Duration position) async => await _audioPlayer.seek(position);

  Future<void> setRepeatMode(RepeatMode mode) async {
    switch (mode) {
      case RepeatMode.off:
        await _audioPlayer.setLoopMode(LoopMode.off);
        break;
      case RepeatMode.one:
        await _audioPlayer.setLoopMode(LoopMode.one);
        break;
      case RepeatMode.all:
        await _audioPlayer.setLoopMode(LoopMode.all);
        break;
    }
  }

  Future<void> setShuffle(bool enabled) async {
    await _audioPlayer.setShuffleModeEnabled(enabled);
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
