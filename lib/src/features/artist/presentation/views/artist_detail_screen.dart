import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/artist_controller.dart';
import '../../../../features/player/presentation/controllers/player_controller.dart';
import '../../../../features/player/domain/models/player_state_model.dart';
import '../../../../features/player/presentation/views/full_player_screen.dart';

class ArtistDetailScreen extends ConsumerStatefulWidget {
  final String artistId;

  const ArtistDetailScreen({super.key, required this.artistId});

  @override
  ConsumerState<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends ConsumerState<ArtistDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  bool _isPlayingLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(artistDetailsProvider.notifier).fetchArtist(widget.artistId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cutuca o provider para carregar as 100 músicas no fundo
    ref.watch(artistSongsProvider(widget.artistId));
    
    final artistAsync = ref.watch(artistDetailsProvider);
    final playerState = ref.watch(playerControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          artistAsync.when(
        data: (artist) {
          if (artist == null) {
            return _buildErrorState('Artista não encontrado.');
          }

          final screenWidth = MediaQuery.of(context).size.width;
          final headerHeight = screenWidth;
          final avatarOrBanner = artist.bannerUrl ?? artist.avatarUrl;

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Header com Parallax e Fading App Bar
              SliverAppBar(
                expandedHeight: headerHeight,
                pinned: true,
                backgroundColor: AppColors.background,
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Opacity(
                    opacity: (_scrollOffset / (headerHeight - kToolbarHeight)).clamp(0.0, 1.0),
                    child: Text(
                      artist.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (avatarOrBanner != null)
                        CachedNetworkImage(
                          imageUrl: avatarOrBanner,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      // Gradiente escuro para baixo
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.background.withValues(alpha: 0.8),
                              AppColors.background,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.4, 0.8, 1.0],
                          ),
                        ),
                      ),
                      // Informações do artista no rodapé do header
                      Positioned(
                        bottom: 24,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              artist.name,
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.1,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: artist.topSongs.isEmpty ? null : () {
                                    _playSongs(artist.topSongs, 0);
                                  },
                                  icon: const Icon(Icons.play_arrow_rounded, color: AppColors.background),
                                  label: const Text(
                                    'Tocar Rádio',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.background),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.background,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    elevation: 8,
                                    shadowColor: AppColors.primary.withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton(
                                  onPressed: () {
                                    // Ação de Seguir (futuro)
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white54, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  child: const Text(
                                    'Seguir',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Conteúdo (Músicas, Álbuns, Singles, etc)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 120), // Espaço para miniplayer
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Músicas Populares
                      if (artist.topSongs.isNotEmpty) ...[
                        _buildSectionHeader(
                          title: 'Músicas Populares',
                          showMore: true,
                          onShowMore: () => context.push('/artist/${artist.id}/songs'),
                        ),
                        _buildTopSongs(artist.topSongs, playerState),
                      ],

                      // Álbuns
                      if (artist.albums.isNotEmpty) ...[
                        _buildSectionHeader(
                          title: 'Álbuns',
                          showMore: artist.albums.length >= 10,
                          onShowMore: () => context.push('/artist/${artist.id}/albums', extra: {'type': 'albums', 'initialData': artist.albums}),
                        ),
                        _buildAlbumsCarousel(artist.albums),
                      ],

                      // Singles
                      if (artist.singles.isNotEmpty) ...[
                        _buildSectionHeader(
                          title: 'Singles',
                          showMore: artist.singles.length >= 10,
                          onShowMore: () => context.push('/artist/${artist.id}/albums', extra: {'type': 'singles', 'initialData': artist.singles}),
                        ),
                        _buildAlbumsCarousel(artist.singles),
                      ],

                      // Incluído em
                      if (artist.featuredOn.isNotEmpty) ...[
                        _buildSectionHeader(
                          title: 'Incluído em',
                          showMore: false,
                          onShowMore: () {},
                        ),
                        _buildPlaylistsCarousel(artist.featuredOn),
                      ],

                      // Playlists do Artista (Extraídas dos similares)
                      if (artist.artistPlaylists.isNotEmpty) ...[
                        _buildSectionHeader(
                          title: 'Playlists de ${artist.name}',
                          showMore: false,
                          onShowMore: () {},
                        ),
                        _buildPlaylistsCarousel(artist.artistPlaylists),
                      ],

                      // Artistas Semelhantes
                      if (artist.similarArtists.isNotEmpty) ...[
                        _buildSectionHeader(
                          title: 'Os fãs também podem gostar de...',
                          showMore: false,
                          onShowMore: () {},
                        ),
                        _buildSimilarArtistsCarousel(artist.similarArtists),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, st) => _buildErrorState('Erro ao carregar artista: $err'),
      ),
      if (_isPlayingLoading)
        Container(
          color: Colors.black54,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        ],
      ),
    );
  }

  Future<void> _playSongs(List<AudioTrackModel> top5, int initialIndex) async {
    setState(() => _isPlayingLoading = true);
    
    try {
      // Espera as 100 músicas terminarem de carregar (geralmente já carregou no fundo)
      final allSongs = await ref.read(artistSongsProvider(widget.artistId).future);
      
      int newIndex = 0;
      if (initialIndex < top5.length) {
        final targetSongId = top5[initialIndex].id;
        final foundIndex = allSongs.indexWhere((s) => s.id == targetSongId);
        
        if (foundIndex != -1) {
          newIndex = foundIndex;
        } else {
          // Fallback: se a música do Top 5 não estiver nas 100 por algum motivo, insere ela
          final mutableAllSongs = List<AudioTrackModel>.from(allSongs);
          mutableAllSongs.insert(0, top5[initialIndex]);
          ref.read(playerControllerProvider.notifier).playQueue(mutableAllSongs, initialIndex: 0);
          if (mounted) FullPlayerScreen.show(context);
          setState(() => _isPlayingLoading = false);
          return;
        }
      }
      
      ref.read(playerControllerProvider.notifier).playQueue(allSongs, initialIndex: newIndex);
      if (mounted) FullPlayerScreen.show(context);
    } catch (e) {
      // Se falhar (sem internet, erro de api), toca apenas o top 5
      ref.read(playerControllerProvider.notifier).playQueue(top5, initialIndex: initialIndex);
      if (mounted) FullPlayerScreen.show(context);
    } finally {
      if (mounted) setState(() => _isPlayingLoading = false);
    }
  }

  Widget _buildErrorState(String message) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required bool showMore, required VoidCallback onShowMore}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 10, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (showMore)
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 18),
              onPressed: onShowMore,
            ),
        ],
      ),
    );
  }

  Widget _buildTopSongs(List<AudioTrackModel> songs, PlayerStateModel playerState) {
    final displaySongs = songs.take(5).toList();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: displaySongs.length,
      itemBuilder: (context, index) {
        final song = displaySongs[index];
        final isPlaying = playerState.currentTrack?.id == song.id;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: song.thumbnailUrl ?? '',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(color: AppColors.surface, width: 48, height: 48),
                ),
              ),
            ],
          ),
          title: Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isPlaying ? AppColors.primary : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            song.artistName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          trailing: const Icon(Icons.more_vert, color: AppColors.textMuted),
          onTap: () => _playSongs(songs, index),
        );
      },
    );
  }

  Widget _buildAlbumsCarousel(List<dynamic> items) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () => context.push('/album/${item.id}'),
            child: SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: item.coverUrl ?? '',
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(color: AppColors.surface, width: 140, height: 140),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.artistName ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaylistsCarousel(List<dynamic> items) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () => context.push('/playlist/${item.id}'),
            child: SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: item.coverUrl ?? '',
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(color: AppColors.surface, width: 140, height: 140),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSimilarArtistsCarousel(List<dynamic> items) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final artist = items[index];
          return GestureDetector(
            onTap: () => context.push('/artist/${artist.id}'),
            child: SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: artist.avatarUrl ?? '',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(color: AppColors.surface, width: 120, height: 120),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    artist.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
