import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/artist_controller.dart';
import '../../../../features/album/domain/models/album_model.dart';

class ArtistAlbumsScreen extends ConsumerWidget {
  final String artistId;
  final String type; // 'albums' or 'singles'
  final List<AlbumModel> initialData;

  const ArtistAlbumsScreen({
    super.key,
    required this.artistId,
    required this.type,
    this.initialData = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = type == 'albums' ? 'Todos os Álbuns' : 'Todos os Singles';
    
    // Listen to the provider fetching fresh data
    final asyncData = type == 'albums' 
        ? ref.watch(artistAlbumsProvider(artistId))
        : ref.watch(artistSinglesProvider(artistId));

    // Combine initialData as a fallback while loading or if it fails/returns empty
    final displayData = asyncData.maybeWhen(
      data: (data) => data.isNotEmpty ? data : initialData,
      orElse: () => initialData,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          if (displayData.isEmpty && asyncData.isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (displayData.isEmpty)
            const Center(child: Text('Nenhum item encontrado.', style: TextStyle(color: AppColors.textSecondary)))
          else
            GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 24,
                childAspectRatio: 0.75, // Ajuste para capa + textos
              ),
              itemCount: displayData.length,
              itemBuilder: (context, index) {
                final album = displayData[index];
                return GestureDetector(
                  onTap: () => context.push('/album/${album.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: album.coverUrl ?? '',
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(color: AppColors.surface),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        album.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        album.year?.toString() ?? album.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                );
              },
            ),
          
          // Mostrar overlay de loading se tivermos dados iniciais mas estivermos carregando os frescos silenciosamente
          if (displayData.isNotEmpty && asyncData.isLoading)
             const Positioned(
               top: 0,
               left: 0,
               right: 0,
               child: LinearProgressIndicator(color: AppColors.primary, backgroundColor: Colors.transparent),
             ),
        ],
      ),
    );
  }
}
