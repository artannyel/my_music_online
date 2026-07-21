import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/ytmusic_album_repository.dart';
import '../../domain/models/album_model.dart';
import '../../domain/repositories/album_repository.dart';

/// Provider singleton para o repositório de Álbuns
final albumRepositoryProvider = Provider<AlbumRepository>((ref) {
  return YtMusicAlbumRepository();
});

/// FutureProvider reativo que obtém os detalhes do álbum por ID
final albumDetailProvider = FutureProvider.family.autoDispose<AlbumModel?, String>((ref, albumId) async {
  final repository = ref.watch(albumRepositoryProvider);
  return repository.getAlbumDetails(albumId);
});
