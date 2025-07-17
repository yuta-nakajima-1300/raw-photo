import 'dart:io';
import 'package:flutter/material.dart';

import '../models/raw_image.dart';

class RawImageGrid extends StatelessWidget {
  final List<RawImage> images;
  final Function(RawImage)? onImageTap;
  final Function(RawImage)? onImageLongPress;
  final ScrollController? scrollController;
  final bool allowSelection;
  final Set<String> selectedImages;
  final Function(RawImage, bool)? onSelectionChanged;

  const RawImageGrid({
    super.key,
    required this.images,
    this.onImageTap,
    this.onImageLongPress,
    this.scrollController,
    this.allowSelection = false,
    this.selectedImages = const {},
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const Center(
        child: Text('画像がありません'),
      );
    }

    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        return RawImageTile(
          image: image,
          onTap: () => onImageTap?.call(image),
          onLongPress: () => onImageLongPress?.call(image),
          isSelected: allowSelection && selectedImages.contains(image.id),
          allowSelection: allowSelection,
          onSelectionChanged: (selected) => onSelectionChanged?.call(image, selected),
        );
      },
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 6;
    if (width > 800) return 4;
    if (width > 600) return 3;
    return 2;
  }
}

class RawImageTile extends StatefulWidget {
  final RawImage image;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool allowSelection;
  final Function(bool)? onSelectionChanged;

  const RawImageTile({
    super.key,
    required this.image,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.allowSelection = false,
    this.onSelectionChanged,
  });

  @override
  State<RawImageTile> createState() => _RawImageTileState();
}

class _RawImageTileState extends State<RawImageTile> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: widget.isSelected ? 8 : 2,
      shadowColor: widget.isSelected 
          ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
          : null,
      child: InkWell(
        onTap: widget.allowSelection 
            ? () => widget.onSelectionChanged?.call(!widget.isSelected)
            : widget.onTap,
        onLongPress: widget.onLongPress,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 画像
            _buildImageWidget(),
            
            // 選択状態のオーバーレイ
            if (widget.allowSelection && widget.isSelected)
              Container(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            
            // 画像情報オーバーレイ
            _buildInfoOverlay(context),
            
            // 選択チェックボックス
            if (widget.allowSelection)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Checkbox(
                    value: widget.isSelected,
                    onChanged: (value) => widget.onSelectionChanged?.call(value ?? false),
                    fillColor: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.selected)) {
                        return Theme.of(context).colorScheme.primary;
                      }
                      return Colors.white;
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    // サムネイルが存在する場合は表示
    if (widget.image.thumbnailPath != null) {
      final thumbnailFile = File(widget.image.thumbnailPath!);
      return Image.file(
        thumbnailFile,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }
    
    // サムネイルが無い場合はプレースホルダー
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            _getFileExtension().toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoOverlay(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black87,
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ファイル名
            Text(
              widget.image.fileName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 2),
            
            // 詳細情報
            Row(
              children: [
                // ファイルサイズ
                Expanded(
                  child: Text(
                    widget.image.formattedFileSize,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
                
                // 評価（星）
                if (widget.image.rating > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      widget.image.rating,
                      (index) => const Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.amber,
                      ),
                    ),
                  ),
              ],
            ),
            
            // カメラ情報（スペースがある場合）
            if (widget.image.cameraModel?.isNotEmpty == true)
              Text(
                widget.image.cameraModel!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white60,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  String _getFileExtension() {
    final fileName = widget.image.fileName;
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex != -1 && lastDotIndex < fileName.length - 1) {
      return fileName.substring(lastDotIndex + 1);
    }
    return 'RAW';
  }
}

// 画像一覧のステータスバー
class RawImageGridStatusBar extends StatelessWidget {
  final int totalImages;
  final int selectedImages;
  final bool selectionMode;
  final VoidCallback? onSelectAll;
  final VoidCallback? onDeselectAll;
  final VoidCallback? onExitSelection;

  const RawImageGridStatusBar({
    super.key,
    required this.totalImages,
    required this.selectedImages,
    required this.selectionMode,
    this.onSelectAll,
    this.onDeselectAll,
    this.onExitSelection,
  });

  @override
  Widget build(BuildContext context) {
    if (!selectionMode) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onExitSelection,
            icon: const Icon(Icons.close),
            tooltip: '選択モード終了',
          ),
          
          const SizedBox(width: 8),
          
          Text(
            '$selectedImages枚選択中',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          
          const Spacer(),
          
          if (selectedImages < totalImages)
            TextButton(
              onPressed: onSelectAll,
              child: const Text('すべて選択'),
            )
          else
            TextButton(
              onPressed: onDeselectAll,
              child: const Text('選択解除'),
            ),
        ],
      ),
    );
  }
}

// 画像グリッド用のローディングインジケーター
class RawImageGridLoading extends StatelessWidget {
  final String? message;

  const RawImageGridLoading({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

// 画像グリッド用のエラー表示
class RawImageGridError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const RawImageGridError({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'エラーが発生しました',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('再試行'),
            ),
          ],
        ],
      ),
    );
  }
}