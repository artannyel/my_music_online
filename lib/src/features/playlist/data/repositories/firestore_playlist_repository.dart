import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import '../../domain/models/playlist_model.dart';
import '../../domain/repositories/playlist_repository.dart';

/// Implementação do PlaylistRepository que combina a busca de playlists públicas
/// via dart_ytmusic_api e o armazenamento de playlists privadas do usuário no Cloud Firestore.
class FirestorePlaylistRepository implements PlaylistRepository {
  final FirebaseFirestore _firestore;
  final YTMusic _ytMusic;

  FirestorePlaylistRepository({
    FirebaseFirestore? firestore,
    YTMusic? ytMusic,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _ytMusic = ytMusic ?? YTMusic();

  CollectionReference<Map<String, dynamic>> get _playlistsRef =>
      _firestore.collection('playlists');

  @override
  Stream<List<PlaylistModel>> getUserPlaylists(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return _playlistsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PlaylistModel.fromJson(data);
      }).toList();
    });
  }

  @override
  Future<PlaylistModel?> getPlaylistById(String playlistId) async {
    // 1. Se for uma playlist pública do YouTube Music / Álbum
    if (playlistId.startsWith('PL') ||
        playlistId.startsWith('VL') ||
        playlistId.startsWith('OLAK')) {
      try {
        await _ytMusic.initialize(gl: 'BR', hl: 'pt-BR');
        final rawPlaylist = await _ytMusic.getPlaylist(playlistId);

        final String? cover = rawPlaylist.thumbnails.isNotEmpty
            ? (rawPlaylist.thumbnails.length >= 2
                ? rawPlaylist.thumbnails[1].url
                : rawPlaylist.thumbnails.last.url)
            : null;

        // Buscar vídeos/músicas da playlist pública
        final videos = await _ytMusic.getPlaylistVideos(playlistId);

        final tracks = videos.map((v) {
          final String? thumb = v.thumbnails.isNotEmpty
              ? (v.thumbnails.length >= 2 ? v.thumbnails[1].url : v.thumbnails.last.url)
              : null;

          return PlaylistTrackModel(
            id: v.videoId,
            title: v.name,
            artistName: v.artist.name,
            thumbnailUrl: thumb,
            videoId: v.videoId,
            duration: v.duration != null ? Duration(seconds: v.duration!) : null,
          );
        }).toList();

        return PlaylistModel(
          id: rawPlaylist.playlistId,
          title: rawPlaylist.name,
          description: rawPlaylist.artist.name,
          coverUrl: cover,
          tracks: tracks,
          createdAt: DateTime.now(),
          isPublic: true,
        );
      } catch (_) {
        // Ignora e continua para verificar se está salva no Firestore
      }
    }

    // 2. Busca no Cloud Firestore
    try {
      final doc = await _playlistsRef.doc(playlistId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return PlaylistModel.fromJson(data);
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<PlaylistModel> createPlaylist({
    required String userId,
    required String title,
    String? description,
  }) async {
    final now = DateTime.now();
    final newDoc = _playlistsRef.doc();

    final playlist = PlaylistModel(
      id: newDoc.id,
      userId: userId,
      title: title,
      description: description,
      tracks: const [],
      createdAt: now,
      isPublic: false,
    );

    await newDoc.set(playlist.toJson());
    return playlist;
  }

  @override
  Future<void> addTrackToPlaylist({
    required String playlistId,
    required PlaylistTrackModel track,
  }) async {
    final docRef = _playlistsRef.doc(playlistId);
    final doc = await docRef.get();

    if (doc.exists && doc.data() != null) {
      final playlist = PlaylistModel.fromJson({...doc.data()!, 'id': doc.id});

      // Evita duplicatas da mesma música
      if (playlist.tracks.any((t) => t.id == track.id)) {
        return;
      }

      final updatedTracks = [...playlist.tracks, track];
      final coverUrl = playlist.coverUrl ?? track.thumbnailUrl;

      await docRef.update({
        'tracks': updatedTracks.map((t) => t.toJson()).toList(),
        'coverUrl': ?coverUrl,
      });
    }
  }

  @override
  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    final docRef = _playlistsRef.doc(playlistId);
    final doc = await docRef.get();

    if (doc.exists && doc.data() != null) {
      final playlist = PlaylistModel.fromJson({...doc.data()!, 'id': doc.id});
      final updatedTracks = playlist.tracks.where((t) => t.id != trackId).toList();

      await docRef.update({
        'tracks': updatedTracks.map((t) => t.toJson()).toList(),
      });
    }
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    await _playlistsRef.doc(playlistId).delete();
  }
}
