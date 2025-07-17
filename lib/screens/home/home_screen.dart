import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/file_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/raw_image.dart';
import '../editor/editor_screen.dart';
import '../../widgets/raw_image_grid.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/sort_filter_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('RAW Photo Editor'),
        elevation: 0,
        actions: [
          // 検索ボタン
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
            tooltip: '検索',
          ),
          // ソート・フィルターボタン
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortFilterSheet(context),
            tooltip: 'ソート・フィルター',
          ),
          // 更新ボタン
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshImages(context),
            tooltip: '更新',
          ),
          // その他メニュー
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.add_photo_alternate),
                  title: Text('画像をインポート'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'scan',
                child: ListTile(
                  leading: Icon(Icons.scanner),
                  title: Text('デバイスをスキャン'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'select_all',
                child: ListTile(
                  leading: Icon(Icons.select_all),
                  title: Text('すべて選択'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete_selected',
                child: ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('選択項目を削除'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer2<FileProvider, SettingsProvider>(
        builder: (context, fileProvider, settingsProvider, child) {
          if (fileProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('RAW画像を読み込み中...'),
                ],
              ),
            );
          }

          if (fileProvider.rawImages.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              // 統計情報バー
              if (settingsProvider.showHistogram)
                _buildStatsBar(fileProvider),
              
              // 画像グリッド
              Expanded(
                child: RawImageGrid(
                  images: fileProvider.rawImages,
                  onImageTap: (image) => _openEditor(context, image),
                  onImageLongPress: (image) => _showImageMenu(context, image),
                  scrollController: _scrollController,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _importImages(context),
        tooltip: '画像をインポート',
        child: const Icon(Icons.add_photo_alternate),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'RAW画像がありません',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'RAW画像をインポートするか、\nデバイスをスキャンしてください',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _importImages(context),
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('インポート'),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _scanDevice(context),
                icon: const Icon(Icons.scanner),
                label: const Text('スキャン'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(FileProvider fileProvider) {
    final totalImages = fileProvider.totalImages;
    final filteredImages = fileProvider.rawImages.length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.photo_library,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            filteredImages == totalImages
                ? '$totalImages枚の画像'
                : '$filteredImages枚 / $totalImages枚の画像',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (fileProvider.currentFilter.isNotEmpty) ...[
            Icon(
              Icons.filter_alt,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'フィルター適用中',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: RawImageSearchDelegate(),
    );
  }

  void _showSortFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const SortFilterSheet(),
    );
  }

  void _refreshImages(BuildContext context) {
    context.read<FileProvider>().refresh();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('画像一覧を更新しました'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'import':
        _importImages(context);
        break;
      case 'scan':
        _scanDevice(context);
        break;
      case 'select_all':
        // TODO: 複数選択機能の実装
        break;
      case 'delete_selected':
        // TODO: 選択削除機能の実装
        break;
    }
  }

  void _importImages(BuildContext context) async {
    try {
      await context.read<FileProvider>().importImages();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('画像をインポートしました'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('インポートに失敗しました: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _scanDevice(BuildContext context) async {
    // 権限チェック
    final hasPermission = await context.read<FileProvider>().requestPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ストレージアクセス権限が必要です'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (mounted) {
      // スキャン開始を通知
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('デバイスをスキャン中...'),
          duration: Duration(seconds: 3),
        ),
      );

      // ファイル一覧を更新（内部でスキャンが実行される）
      await context.read<FileProvider>().loadFiles();
    }
  }

  void _openEditor(BuildContext context, RawImage image) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditorScreen(image: image),
      ),
    );
  }

  void _showImageMenu(BuildContext context, RawImage image) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => RawImageMenuSheet(image: image),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

// 検索デリゲート
class RawImageSearchDelegate extends SearchDelegate<RawImage?> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    return Consumer<FileProvider>(
      builder: (context, fileProvider, child) {
        // 検索フィルターを適用
        fileProvider.setFilter(query);
        
        return RawImageGrid(
          images: fileProvider.rawImages,
          onImageTap: (image) {
            close(context, image);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EditorScreen(image: image),
              ),
            );
          },
        );
      },
    );
  }
}

// 画像メニューシート
class RawImageMenuSheet extends StatelessWidget {
  final RawImage image;

  const RawImageMenuSheet({
    super.key,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            image.fileName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '${image.formattedFileSize} • ${image.formattedDimensions}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('編集'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditorScreen(image: image),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('詳細情報'),
            onTap: () {
              Navigator.of(context).pop();
              _showImageDetails(context, image);
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_border),
            title: const Text('評価'),
            onTap: () {
              Navigator.of(context).pop();
              _showRatingDialog(context, image);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              '削除',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            onTap: () {
              Navigator.of(context).pop();
              _confirmDelete(context, image);
            },
          ),
        ],
      ),
    );
  }

  void _showImageDetails(BuildContext context, RawImage image) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('画像詳細'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow('ファイル名', image.fileName),
              _DetailRow('サイズ', image.formattedFileSize),
              _DetailRow('解像度', image.formattedDimensions),
              _DetailRow('カメラ', '${image.cameraMake} ${image.cameraModel}'),
              _DetailRow('レンズ', image.lensModel ?? 'N/A'),
              _DetailRow('ISO', image.iso?.toString() ?? 'N/A'),
              _DetailRow('絞り', image.formattedAperture),
              _DetailRow('シャッター', image.shutterSpeed ?? 'N/A'),
              _DetailRow('焦点距離', image.formattedFocalLength),
              _DetailRow('作成日時', image.dateCreated.toString()),
              _DetailRow('更新日時', image.dateModified.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, RawImage image) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('評価'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final rating = index + 1;
            return ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (starIndex) {
                  return Icon(
                    starIndex < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  );
                }),
              ),
              title: Text('$rating つ星'),
              onTap: () {
                context.read<FileProvider>().updateImageRating(image, rating);
                Navigator.of(context).pop();
              },
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, RawImage image) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('${image.fileName} を削除しますか？\nこの操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              context.read<FileProvider>().deleteImage(image);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('画像を削除しました')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}