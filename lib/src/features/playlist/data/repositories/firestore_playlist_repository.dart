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
    String ytSearchId = playlistId;
    PlaylistModel? firestorePlaylist;

    // 1. Verifica se já existe um documento de salvamento no Firestore
    try {
      final doc = await _playlistsRef.doc(playlistId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = doc.id;
        firestorePlaylist = PlaylistModel.fromJson(data);

        // Se for do tipo customizado (criada pelo usuário), retorna os dados salvos no Firestore
        if (firestorePlaylist.type == PlaylistType.custom) {
          return firestorePlaylist;
        }

        // Se for salva do YouTube, pega o ID original do YouTube para buscar faixas ao vivo
        if (firestorePlaylist.originalYtPlaylistId != null) {
          ytSearchId = firestorePlaylist.originalYtPlaylistId!;
        }
      }
    } catch (_) {}

    // 2. Busca dados ao vivo do YouTube Music / Álbum
    try {
      await _ytMusic.initialize(gl: 'BR', hl: 'pt-BR');

      // Tenta carregar como Playlist do YouTube Music
      try {
        final rawPlaylist = await _ytMusic.getPlaylist(ytSearchId);
        final String? cover = rawPlaylist.thumbnails.isNotEmpty
            ? (rawPlaylist.thumbnails.length >= 2
                ? rawPlaylist.thumbnails[1].url
                : rawPlaylist.thumbnails.last.url)
            : null;

        final videos = await _ytMusic.getPlaylistVideos(ytSearchId);
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
          id: firestorePlaylist?.id ?? rawPlaylist.playlistId,
          userId: firestorePlaylist?.userId,
          title: firestorePlaylist?.title ?? rawPlaylist.name,
          description: firestorePlaylist?.description ?? rawPlaylist.artist.name,
          coverUrl: firestorePlaylist?.coverUrl ?? cover,
          tracks: tracks,
          createdAt: firestorePlaylist?.createdAt ?? DateTime.now(),
          isPublic: true,
          type: PlaylistType.youtube,
          originalYtPlaylistId: ytSearchId,
        );
      } catch (_) {
        // Se falhou ao buscar como Playlist, tenta carregar como Álbum do YouTube Music
        final rawAlbum = await _ytMusic.getAlbum(ytSearchId);
        final String? cover = rawAlbum.thumbnails.isNotEmpty
            ? (rawAlbum.thumbnails.length >= 2
                ? rawAlbum.thumbnails[1].url
                : rawAlbum.thumbnails.last.url)
            : null;

        final tracks = rawAlbum.songs.map((s) {
          final String? thumb = s.thumbnails.isNotEmpty
              ? (s.thumbnails.length >= 2 ? s.thumbnails[1].url : s.thumbnails.last.url)
              : null;

          return PlaylistTrackModel(
            id: s.videoId,
            title: s.name,
            artistName: s.artist.name,
            albumName: s.album?.name ?? rawAlbum.name,
            thumbnailUrl: thumb,
            videoId: s.videoId,
            duration: s.duration != null ? Duration(seconds: s.duration!) : null,
          );
        }).toList();

        return PlaylistModel(
          id: firestorePlaylist?.id ?? rawAlbum.albumId,
          userId: firestorePlaylist?.userId,
          title: firestorePlaylist?.title ?? rawAlbum.name,
          description: firestorePlaylist?.description ?? rawAlbum.artist.name,
          coverUrl: firestorePlaylist?.coverUrl ?? cover,
          tracks: tracks,
          createdAt: firestorePlaylist?.createdAt ?? DateTime.now(),
          isPublic: true,
          type: PlaylistType.youtube,
          originalYtPlaylistId: ytSearchId,
        );
      }
    } catch (_) {}

    return firestorePlaylist;
  }

  @override
  Future<void> saveYtPlaylistToLibrary({
    required String userId,
    required PlaylistModel ytPlaylist,
  }) async {
    // Procura se já está salva
    final query = await _playlistsRef
        .where('userId', isEqualTo: userId)
        .where('originalYtPlaylistId', isEqualTo: ytPlaylist.id)
        .get();

    if (query.docs.isNotEmpty) return;

    final newDoc = _playlistsRef.doc();
    final savedModel = PlaylistModel(
      id: newDoc.id,
      userId: userId,
      title: ytPlaylist.title,
      description: ytPlaylist.description,
      coverUrl: ytPlaylist.coverUrl,
      tracks: const [], // Músicas continuam sincronizadas via originalYtPlaylistId
      createdAt: DateTime.now(),
      isPublic: true,
      type: PlaylistType.youtube,
      originalYtPlaylistId: ytPlaylist.id,
    );

    await newDoc.set(savedModel.toJson());
  }

  @override
  Future<void> unsaveYtPlaylistFromLibrary({
    required String userId,
    required String playlistId,
  }) async {
    final query = await _playlistsRef
        .where('userId', isEqualTo: userId)
        .where('originalYtPlaylistId', isEqualTo: playlistId)
        .get();

    for (final doc in query.docs) {
      await doc.reference.delete();
    }

    // Também verifica se playlistId foi o ID do próprio documento no Firestore
    final doc = await _playlistsRef.doc(playlistId).get();
    if (doc.exists && doc.data()?['userId'] == userId) {
      await doc.reference.delete();
    }
  }

  @override
  Future<PlaylistModel> duplicatePlaylistAsCustom({
    required String userId,
    required PlaylistModel sourcePlaylist,
  }) async {
    final newDoc = _playlistsRef.doc();
    final customPlaylist = PlaylistModel(
      id: newDoc.id,
      userId: userId,
      title: '${sourcePlaylist.title} (Cópia)',
      description: sourcePlaylist.description,
      coverUrl: sourcePlaylist.coverUrl,
      tracks: sourcePlaylist.tracks,
      createdAt: DateTime.now(),
      isPublic: false,
      type: PlaylistType.custom,
    );

    await newDoc.set(customPlaylist.toJson());
    return customPlaylist;
  }

  @override
  Future<bool> isPlaylistSaved({
    required String userId,
    required String playlistId,
  }) async {
    if (userId.isEmpty) return false;

    final query = await _playlistsRef
        .where('userId', isEqualTo: userId)
        .where('originalYtPlaylistId', isEqualTo: playlistId)
        .get();

    if (query.docs.isNotEmpty) return true;

    final doc = await _playlistsRef.doc(playlistId).get();
    return doc.exists && doc.data()?['userId'] == userId;
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
      type: PlaylistType.custom,
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

      // Permite alterar faixas apenas se for do tipo customizado
      if (playlist.type != PlaylistType.custom) return;

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

      // Permite alterar faixas apenas se for do tipo customizado
      if (playlist.type != PlaylistType.custom) return;

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
