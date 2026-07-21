import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/ytmusic_search_repository.dart';
import '../../domain/models/search_result_model.dart';
import '../../domain/repositories/search_repository.dart';

/// Provider singleton para o repositório de busca
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return YtMusicSearchRepository();
});

/// Provider do texto atual digitado no campo de busca
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Provider do filtro selecionado (Tudo, Músicas, Álbuns, Artistas, Playlists)
final selectedSearchFilterProvider = StateProvider<SearchFilterType>((ref) => SearchFilterType.all);

/// Provider que indica se a busca foi submetida (Enter/Clicou em sugestão)
final isSearchSubmittedProvider = StateProvider<bool>((ref) => false);

/// Provider de sugestões de autocompletar de texto com debounce dinâmico
final searchSuggestionsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.isEmpty) return [];

  // Debounce de 300ms para evitar chamadas excessivas durante a digitação
  await Future.delayed(const Duration(milliseconds: 300));
  if (ref.read(searchQueryProvider).trim() != query) {
    // Se a query mudou enquanto esperávamos, aborta para dar lugar à nova busca
    return [];
  }

  final repository = ref.watch(searchRepositoryProvider);
  return repository.getSearchSuggestions(query);
});

class SearchResultsNotifier extends AutoDisposeAsyncNotifier<List<SearchResultModel>> {
  @override
  FutureOr<List<SearchResultModel>> build() async {
    final query = ref.watch(searchQueryProvider).trim();
    final filter = ref.watch(selectedSearchFilterProvider);

    if (query.isEmpty) return [];

    final repository = ref.watch(searchRepositoryProvider) as YtMusicSearchRepository;
    return repository.search(query, filter: filter);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.hasError) return;
    
    final query = ref.read(searchQueryProvider).trim();
    final filter = ref.read(selectedSearchFilterProvider);
    
    if (query.isEmpty) return;

    final repository = ref.read(searchRepositoryProvider) as YtMusicSearchRepository;
    
    if (!repository.isMore(filter)) return;

    // Coloca state temporário com os dados atuais apenas para refletir loading no UI? 
    // Em Riverpod, AsyncValue.data pode manter o estado isRefreshing. Usaremos update.
    state = const AsyncLoading<List<SearchResultModel>>().copyWithPrevious(state);

    try {
      final newResults = await repository.moreResults(query, filter);
      if (newResults.isEmpty) {
        state = AsyncData(state.value ?? []);
        return;
      }
      
      final currentList = state.value ?? [];
      state = AsyncData([...currentList, ...newResults]);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

// Para manter compatibilidade onde usava-se `searchResultsProvider` (substituir na UI em seguida)
final searchResultsProvider = AsyncNotifierProvider.autoDispose<SearchResultsNotifier, List<SearchResultModel>>(() {
  return SearchResultsNotifier();
});
