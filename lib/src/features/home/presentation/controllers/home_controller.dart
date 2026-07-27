import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/ytmusic_home_repository.dart';
import '../../domain/models/home_section_model.dart';
import '../../domain/repositories/home_repository.dart';

/// Provider para o repositório da Home.
final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return YtMusicHomeRepository();
});

/// FutureProvider reativo para carregar as seções da Home.
final homeSectionsProvider = FutureProvider<List<HomeSectionModel>>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  return repository.getHomeSections();
});
