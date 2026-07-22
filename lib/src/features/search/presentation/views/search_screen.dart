import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../player/domain/models/player_state_model.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../../player/presentation/views/full_player_screen.dart';
import '../../domain/models/search_result_model.dart';
import '../controllers/search_controller.dart';

/// SearchScreen exibe a interface de busca com autocompletar dinâmico (getSearchSuggestions),
/// chips de filtro e integração nativa com o Rádio Automix do Player.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _textController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    final initialQuery = ref.read(searchQueryProvider);
    _textController.text = initialQuery;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(searchResultsProvider.notifier).loadMore();
    }
  }

  void _submitSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isNotEmpty) {
      _textController.text = trimmed;
      ref.read(searchQueryProvider.notifier).state = trimmed;
      ref.read(isSearchSubmittedProvider.notifier).state = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final isSubmitted = ref.watch(isSearchSubmittedProvider);
    final selectedFilter = ref.watch(selectedSearchFilterProvider);

    final suggestionsAsync = ref.watch(searchSuggestionsProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleSpacing: 16,
        title: Container(
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: _textController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Pesquisar músicas, artistas, álbuns...',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 22),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 20),
                      onPressed: () {
                        _textController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                        ref.read(isSearchSubmittedProvider.notifier).state = false;
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (val) {
              ref.read(searchQueryProvider.notifier).state = val;
              ref.read(isSearchSubmittedProvider.notifier).state = false;
            },
            onSubmitted: _submitSearch,
          ),
        ),
      ),
      body: Column(
        children: [
          // Chips de Filtro (somente visíveis quando a busca for submetida ou houver texto)
          if (query.isNotEmpty && isSubmitted)
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip('Tudo', SearchFilterType.all, selectedFilter),
                  _buildFilterChip('Músicas', SearchFilterType.song, selectedFilter),
                  _buildFilterChip('Álbuns', SearchFilterType.album, selectedFilter),
                  _buildFilterChip('Artistas', SearchFilterType.artist, selectedFilter),
                  _buildFilterChip('Playlists', SearchFilterType.playlist, selectedFilter),
                ],
              ),
            ),

          // Conteúdo da Tela: Autocompletar x Resultados da Busca
          Expanded(
            child: query.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_rounded, size: 80, color: AppColors.divider),
                        SizedBox(height: 12),
                        Text(
                          'O que você quer ouvir hoje?',
                          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : (!isSubmitted)
                    // Visão 1: Autocompletar de Texto (getSearchSuggestions)
                    ? suggestionsAsync.when(
                        data: (suggestions) {
                          if (suggestions.isEmpty) {
                            return const Center(
                              child: Text('Nenhuma sugestão encontrada.',
                                  style: TextStyle(color: AppColors.textSecondary)),
                            );
                          }
                          return ListView.builder(
                            itemCount: suggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = suggestions[index];
                              return ListTile(
                                leading: const Icon(Icons.search, color: AppColors.textMuted),
                                title: Text(
                                  suggestion,
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                                ),
                                trailing: const Icon(Icons.north_west, color: AppColors.textMuted, size: 18),
                                onTap: () => _submitSearch(suggestion),
                              );
                            },
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                        error: (err, stack) => const Center(
                          child: Text('Erro ao carregar sugestões.',
                              style: TextStyle(color: AppColors.error)),
                        ),
                      )
                    // Visão 2: Resultados da Busca Completa (Cards)
                    : resultsAsync.when(
                        data: (results) {
                          if (results.isEmpty) {
                            return const Center(
                              child: Text('Nenhum resultado encontrado.',
                                  style: TextStyle(color: AppColors.textSecondary)),
                            );
                          }
                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: results.length + (resultsAsync.isLoading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == results.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: Center(
                                    child: CircularProgressIndicator(color: AppColors.primary),
                                  ),
                                );
                              }
                              final item = results[index];
                              return _buildResultCard(context, item);
                            },
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                        error: (err, stack) => const Center(
                          child: Text('Erro ao buscar resultados.',
                              style: TextStyle(color: AppColors.error)),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, SearchFilterType type, SearchFilterType currentFilter) {
    final isSelected = type == currentFilter;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        checkmarkColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        onSelected: (_) {
          ref.read(selectedSearchFilterProvider.notifier).state = type;
        },
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, SearchResultModel item) {
    final isArtist = item.type == SearchFilterType.artist;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(isArtist ? 28 : 8),
            child: SizedBox(
              width: 52,
              height: 52,
              child: item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.cardBackground,
                        child: Icon(
                          _getFallbackIcon(item.type),
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.cardBackground,
                      child: Icon(
                        _getFallbackIcon(item.type),
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),
          title: Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            item.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: item.type == SearchFilterType.song
              ? IconButton(
                  icon: const Icon(Icons.play_circle_fill, color: AppColors.primary, size: 32),
                  onPressed: () {
                    final audioTrack = AudioTrackModel(
                      id: item.id,
                      videoId: item.videoId,
                      title: item.title,
                      artistName: item.subtitle,
                      thumbnailUrl: item.thumbnailUrl,
                      duration: item.duration,
                    );
                    ref.read(playerControllerProvider.notifier).playTrackWithRadio(audioTrack);
                    FullPlayerScreen.show(context);
                  },
                )
              : const Icon(Icons.chevron_right, color: AppColors.textMuted),
          onTap: () {
            switch (item.type) {
              case SearchFilterType.song:
                final audioTrack = AudioTrackModel(
                  id: item.id,
                  videoId: item.videoId,
                  title: item.title,
                  artistName: item.subtitle,
                  thumbnailUrl: item.thumbnailUrl,
                  duration: item.duration,
                );
                ref.read(playerControllerProvider.notifier).playTrackWithRadio(audioTrack);
                FullPlayerScreen.show(context);
                break;
              case SearchFilterType.album:
                final albumId = item.albumId ?? item.id;
                context.push('/album/$albumId');
                break;
              case SearchFilterType.artist:
                final artistId = item.artistId ?? item.id;
                context.push('/artist/$artistId');
                break;
              case SearchFilterType.playlist:
                final playlistId = item.playlistId ?? item.id;
                context.push('/playlist/$playlistId', extra: item.url);
                break;
              case SearchFilterType.all:
                break;
            }
          },
        ),
      ),
    );
  }

  IconData _getFallbackIcon(SearchFilterType type) {
    switch (type) {
      case SearchFilterType.song:
        return Icons.music_note;
      case SearchFilterType.album:
        return Icons.album;
      case SearchFilterType.artist:
        return Icons.person;
      case SearchFilterType.playlist:
        return Icons.queue_music;
      case SearchFilterType.all:
        return Icons.search;
    }
  }
}
