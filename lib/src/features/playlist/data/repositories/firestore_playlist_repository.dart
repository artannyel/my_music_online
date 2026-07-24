import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import 'package:flutter/foundation.dart';
import 'package:newpipeextractor_dart/newpipeextractor_dart.dart' as newpipe;
import '../../domain/models/playlist_model.dart';
import '../../domain/repositories/playlist_repository.dart';

/// Implementação do PlaylistRepository que combina a busca de playlists públicas
/// via dart_ytmusic_api e o armazenamento de playlists privadas do usuário no Cloud Firestore.
class FirestorePlaylistRepository implements PlaylistRepository {
  final FirebaseFirestore _firestore;
  final YTMusic _ytMusic;

  FirestorePlaylistRepository({FirebaseFirestore? firestore, YTMusic? ytMusic})
    : _firestore = firestore ?? FirebaseFirestore.instance,
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
  Future<PlaylistModel?> getPlaylistById(String playlistId, [String? url]) async {
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

    // Fallback imediato para IDs de demonstração (evita requisitar 'demo_...' na API do YouTube)
    if (ytSearchId.startsWith('demo_')) {
      return PlaylistModel(
        id: ytSearchId,
        title: firestorePlaylist?.title ?? 'Playlist em Destaque',
        description: 'Playlist demonstrativa offline',
        tracks: const [
          PlaylistTrackModel(
            id: 'demo_track_1',
            title: 'Midnight Beats',
            artistName: 'Lo-Fi Chill',
          ),
          PlaylistTrackModel(
            id: 'demo_track_2',
            title: 'Cyberpunk Odyssey',
            artistName: 'Electronic Pulse',
          ),
        ],
        createdAt: DateTime.now(),
        isPublic: true,
        type: PlaylistType.youtube,
      );
    }

    // Ajusta o prefixo para chamadas no YouTube InnerTube API (PL..., RD... -> VLPL..., VLRD...)
    if (ytSearchId.startsWith('PL') || ytSearchId.startsWith('RD')) {
      ytSearchId = 'VL$ytSearchId';
    }

    // 2. Busca dados ao vivo do YouTube Music / Álbum
    try {
      await _ytMusic.initialize(gl: 'BR', hl: 'pt-BR');

      // Se for um Álbum do YouTube Music (IDs começando com OLAK ou MPREb)
      if (ytSearchId.startsWith('OLAK') || ytSearchId.startsWith('MPREb')) {
        try {
          final rawAlbum = await _ytMusic.getAlbum(ytSearchId);
          final String? cover = rawAlbum.thumbnails.isNotEmpty
              ? (rawAlbum.thumbnails.length >= 2
                    ? rawAlbum.thumbnails[1].url
                    : rawAlbum.thumbnails.last.url)
              : null;

          final tracks = rawAlbum.songs.map((s) {
            final String? thumb = s.thumbnails.isNotEmpty
                ? (s.thumbnails.length >= 2
                      ? s.thumbnails[1].url
                      : s.thumbnails.last.url)
                : null;

            return PlaylistTrackModel(
              id: s.videoId,
              title: s.name,
              artistName: s.artist.name,
              albumName: s.album?.name ?? rawAlbum.name,
              thumbnailUrl: thumb,
              videoId: s.videoId,
              duration: s.duration != null
                  ? Duration(seconds: s.duration!)
                  : null,
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
        } catch (_) {}
      }

      // Tenta carregar como Playlist do YouTube Music (oficial ou comunidade)
      try {
        final rawPlaylist = await _ytMusic.getPlaylist(ytSearchId);
        final String? cover = rawPlaylist.thumbnails.isNotEmpty
            ? (rawPlaylist.thumbnails.length >= 2
                  ? rawPlaylist.thumbnails[1].url
                  : rawPlaylist.thumbnails.last.url)
            : null;

        List<PlaylistTrackModel> tracks = [];
        try {
          final videos = await _ytMusic.getPlaylistVideos(ytSearchId);
          tracks = videos.map((v) {
            final String? thumb = v.thumbnails.isNotEmpty
                ? (v.thumbnails.length >= 2
                      ? v.thumbnails[1].url
                      : v.thumbnails.last.url)
                : null;

            return PlaylistTrackModel(
              id: v.videoId,
              title: v.name,
              artistName: v.artist.name,
              thumbnailUrl: thumb,
              videoId: v.videoId,
              duration: v.duration != null
                  ? Duration(seconds: v.duration!)
                  : null,
            );
          }).toList();
        } catch (_) {}

        return PlaylistModel(
          id: firestorePlaylist?.id ?? rawPlaylist.playlistId,
          userId: firestorePlaylist?.userId,
          title: firestorePlaylist?.title ?? rawPlaylist.name,
          description:
              firestorePlaylist?.description ?? rawPlaylist.artist.name,
          coverUrl: firestorePlaylist?.coverUrl ?? cover,
          tracks: tracks,
          createdAt: firestorePlaylist?.createdAt ?? DateTime.now(),
          isPublic: true,
          type: PlaylistType.youtube,
          originalYtPlaylistId: ytSearchId,
        );
      } catch (_) {}

      // Fallback para Álbum se a requisição de playlist falhar
      try {
        final rawAlbum = await _ytMusic.getAlbum(ytSearchId);
        final String? cover = rawAlbum.thumbnails.isNotEmpty
            ? (rawAlbum.thumbnails.length >= 2
                  ? rawAlbum.thumbnails[1].url
                  : rawAlbum.thumbnails.last.url)
            : null;

        final tracks = rawAlbum.songs.map((s) {
          final String? thumb = s.thumbnails.isNotEmpty
              ? (s.thumbnails.length >= 2
                    ? s.thumbnails[1].url
                    : s.thumbnails.last.url)
              : null;

          return PlaylistTrackModel(
            id: s.videoId,
            title: s.name,
            artistName: s.artist.name,
            albumName: s.album?.name ?? rawAlbum.name,
            thumbnailUrl: thumb,
            videoId: s.videoId,
            duration: s.duration != null
                ? Duration(seconds: s.duration!)
                : null,
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
      } catch (_) {}
    } catch (_) {}

    if (url != null && url.isNotEmpty) {
      try {
        final rawMix = await newpipe.PlaylistExtractor.getPlaylistDetails(url);
        
        final isMix = rawMix.playlistType == newpipe.PlaylistType.mixStream;
        
        final streamsTuple = await newpipe.PlaylistExtractor.getPlaylistStreams(url);
        
        List<PlaylistTrackModel> tracks = streamsTuple.items.map((s) {
          String? thumb;
          if (s.thumbnails.isNotEmpty) {
            thumb = s.thumbnails.last;
          }
          String? videoId;
          if (s.url != null && s.url!.contains('v=')) {
            videoId = s.url!.split('v=').last.split('&').first;
          }
          return PlaylistTrackModel(
            id: videoId ?? s.url ?? '',
            title: s.name ?? '',
            artistName: s.uploaderName ?? '',
            thumbnailUrl: thumb,
            videoId: videoId ?? s.url,
            duration: s.duration != null 
                ? Duration(seconds: s.duration!) 
                : null,
          );
        }).toList();

        String? coverUrl;
        if (rawMix.thumbnails.isNotEmpty) {
          coverUrl = rawMix.thumbnails.last;
        }

        String? serializedToken;
        final nextToken = streamsTuple.next;
        if (nextToken != null) {
          serializedToken = jsonEncode({
            if (nextToken.url != null) 'url': nextToken.url,
            if (nextToken.id != null) 'id': nextToken.id,
            if (nextToken.ids != null) 'ids': nextToken.ids,
            if (nextToken.cookies != null) 'cookies': nextToken.cookies,
            if (nextToken.body != null) 'body': base64Encode(nextToken.body!),
          });
        }

        return PlaylistModel(
          id: firestorePlaylist?.id ?? playlistId,
          title: firestorePlaylist?.title ?? rawMix.name ?? 'Mix',
          description: firestorePlaylist?.description ?? 'Playlist Infinita',
          coverUrl: firestorePlaylist?.coverUrl ?? coverUrl,
          tracks: tracks,
          createdAt: firestorePlaylist?.createdAt ?? DateTime.now(),
          isPublic: true,
          type: PlaylistType.youtube,
          originalYtPlaylistId: playlistId,
          isMix: isMix,
          nextPageUrl: serializedToken,
        );
      } catch (e) {
        debugPrint('Fallback NewPipe falhou: $e');
      }
    }

    return firestorePlaylist;
  }

  @override
  Future<({List<PlaylistTrackModel> tracks, String? nextPageUrl})> getMixNextPage(String url, String serializedToken) async {
    try {
      final tokenMap = jsonDecode(serializedToken) as Map<String, dynamic>;
      final pageToken = newpipe.PageToken(
        url: tokenMap['url'] as String?,
        id: tokenMap['id'] as String?,
        ids: (tokenMap['ids'] as List<dynamic>?)?.map((e) => e as String).toList(),
        cookies: (tokenMap['cookies'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as String)),
        body: tokenMap['body'] != null ? base64Decode(tokenMap['body'] as String) : null,
      );

      final streamsTuple = await newpipe.PlaylistExtractor.getPlaylistNextPage(url, pageToken);
      
      final tracks = streamsTuple.items.map((s) {
        String? thumb;
        if (s.thumbnails.isNotEmpty) {
          thumb = s.thumbnails.last;
        }
        String? videoId;
        if (s.url != null && s.url!.contains('v=')) {
          videoId = s.url!.split('v=').last.split('&').first;
        }
        return PlaylistTrackModel(
          id: videoId ?? s.url ?? '',
          title: s.name ?? '',
          artistName: s.uploaderName ?? '',
          thumbnailUrl: thumb,
          videoId: videoId ?? s.url,
          duration: s.duration != null ? Duration(seconds: s.duration!) : null,
        );
      }).toList();

      String? newSerializedToken;
      final nextToken = streamsTuple.next;
      if (nextToken != null) {
        newSerializedToken = jsonEncode({
          if (nextToken.url != null) 'url': nextToken.url,
          if (nextToken.id != null) 'id': nextToken.id,
          if (nextToken.ids != null) 'ids': nextToken.ids,
          if (nextToken.cookies != null) 'cookies': nextToken.cookies,
          if (nextToken.body != null) 'body': base64Encode(nextToken.body!),
        });
      }

      return (tracks: tracks, nextPageUrl: newSerializedToken);
    } catch (e) {
      debugPrint('Falha ao carregar próxima página do Mix: $e');
      return (tracks: <PlaylistTrackModel>[], nextPageUrl: null);
    }
  }

  @override
  Future<void> saveYtPlaylistToLibrary({
    required String userId,
    required PlaylistModel ytPlaylist,
  }) async {
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
      tracks: const [],
      trackCount: ytPlaylist.trackCount,
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

    final doc = await _playlistsRef.doc(playlistId).get();
    if (doc.exists && doc.data()?['userId'] == userId) {
      await doc.reference.delete();
    }
  }

  @override
  Future<PlaylistModel> duplicatePlaylistAsCustom({
    required String userId,
    required PlaylistModel sourcePlaylist,
    String? customTitle,
    String? customDescription,
  }) async {
    final newDoc = _playlistsRef.doc();
    final customPlaylist = PlaylistModel(
      id: newDoc.id,
      userId: userId,
      title: customTitle ?? '${sourcePlaylist.title} (Cópia)',
      description: customDescription ?? sourcePlaylist.description,
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

      if (playlist.type != PlaylistType.custom) return;

      if (playlist.tracks.any((t) => t.id == track.id)) {
        return;
      }

      final updatedTracks = [...playlist.tracks, track];
      final coverUrl = playlist.coverUrl ?? track.thumbnailUrl;

      await docRef.update({
        'tracks': updatedTracks.map((t) => t.toJson()).toList(),
        'trackCount': updatedTracks.length,
        'coverUrl': coverUrl,
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

      if (playlist.type != PlaylistType.custom) return;

      final updatedTracks = playlist.tracks
          .where((t) => t.id != trackId)
          .toList();

      await docRef.update({
        'tracks': updatedTracks.map((t) => t.toJson()).toList(),
        'trackCount': updatedTracks.length,
      });
    }
  }

  @override
  Future<void> updatePlaylist({
    required String playlistId,
    String? title,
    String? description,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (updates.isNotEmpty) {
      await _playlistsRef.doc(playlistId).update(updates);
    }
  }

  @override
  Future<void> reorderPlaylistTracks({
    required String playlistId,
    required List<PlaylistTrackModel> tracks,
  }) async {
    final docRef = _playlistsRef.doc(playlistId);
    final doc = await docRef.get();
    if (doc.exists && doc.data() != null) {
      final playlist = PlaylistModel.fromJson({...doc.data()!, 'id': doc.id});
      if (playlist.type != PlaylistType.custom) return;
      await docRef.update({
        'tracks': tracks.map((t) => t.toJson()).toList(),
        'trackCount': tracks.length,
      });
    }
  }

  @override
  Future<void> saveAlbumToLibrary({
    required String userId,
    required AlbumSaveData album,
  }) async {
    final query = await _playlistsRef
        .where('userId', isEqualTo: userId)
        .where('originalYtPlaylistId', isEqualTo: album.id)
        .get();

    if (query.docs.isNotEmpty) return;

    final newDoc = _playlistsRef.doc();
    final savedModel = PlaylistModel(
      id: newDoc.id,
      userId: userId,
      title: album.title,
      description: album.artistName,
      coverUrl: album.coverUrl,
      tracks: const [],
      trackCount: album.trackCount,
      createdAt: DateTime.now(),
      isPublic: true,
      type: PlaylistType.album,
      originalYtPlaylistId: album.id,
    );

    await newDoc.set(savedModel.toJson());
  }

  @override
  Future<void> unsaveAlbumFromLibrary({
    required String userId,
    required String albumId,
  }) async {
    final query = await _playlistsRef
        .where('userId', isEqualTo: userId)
        .where('originalYtPlaylistId', isEqualTo: albumId)
        .get();

    for (final doc in query.docs) {
      await doc.reference.delete();
    }

    final doc = await _playlistsRef.doc(albumId).get();
    if (doc.exists && doc.data()?['userId'] == userId) {
      await doc.reference.delete();
    }
  }

  @override
  Future<bool> isAlbumSaved({
    required String userId,
    required String albumId,
  }) async {
    if (userId.isEmpty) return false;

    final query = await _playlistsRef
        .where('userId', isEqualTo: userId)
        .where('originalYtPlaylistId', isEqualTo: albumId)
        .get();

    if (query.docs.isNotEmpty) return true;

    final doc = await _playlistsRef.doc(albumId).get();
    return doc.exists && doc.data()?['userId'] == userId;
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    await _playlistsRef.doc(playlistId).delete();
  }
}
