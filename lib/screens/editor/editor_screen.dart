import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/raw_image.dart';
import '../../providers/editor_provider.dart';

class EditorScreen extends StatefulWidget {
  final RawImage image;

  const EditorScreen({
    super.key,
    required this.image,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditorProvider>().openImage(widget.image);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.image.fileName),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () {
              context.read<EditorProvider>().undo();
            },
            tooltip: '元に戻す',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: () {
              context.read<EditorProvider>().redo();
            },
            tooltip: 'やり直し',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              context.read<EditorProvider>().saveSession();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('セッションを保存しました')),
              );
            },
            tooltip: '保存',
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('エクスポート'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: ListTile(
                  leading: Icon(Icons.restore),
                  title: Text('リセット'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<EditorProvider>(
        builder: (context, editorProvider, child) {
          if (editorProvider.isProcessing) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('RAW画像を処理中...'),
                ],
              ),
            );
          }

          if (editorProvider.currentImage == null) {
            return const Center(
              child: Text('画像を読み込めませんでした'),
            );
          }

          return Column(
            children: [
              // プレビュー領域
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  color: Colors.black,
                  child: Center(
                    child: editorProvider.previewImagePath != null
                        ? Image.network(
                            editorProvider.previewImagePath!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPreviewPlaceholder();
                            },
                          )
                        : _buildPreviewPlaceholder(),
                  ),
                ),
              ),
              
              // 調整パネル
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: _buildAdjustmentPanel(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPreviewPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.photo,
          size: 64,
          color: Colors.white54,
        ),
        const SizedBox(height: 16),
        Text(
          'プレビューを生成中...',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.image.fileName,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAdjustmentPanel() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: '基本'),
              Tab(text: '色調'),
              Tab(text: 'ディテール'),
              Tab(text: '変形'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildBasicAdjustments(),
                _buildColorAdjustments(),
                _buildDetailAdjustments(),
                _buildTransformAdjustments(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicAdjustments() {
    return Consumer<EditorProvider>(
      builder: (context, editorProvider, child) {
        final adjustments = editorProvider.adjustments;
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSlider(
              '露出',
              adjustments.exposure,
              -2.0,
              2.0,
              (value) => editorProvider.updateAdjustment(exposure: value),
            ),
            _buildSlider(
              'ハイライト',
              adjustments.highlights,
              -100.0,
              100.0,
              (value) => editorProvider.updateAdjustment(highlights: value),
            ),
            _buildSlider(
              'シャドウ',
              adjustments.shadows,
              -100.0,
              100.0,
              (value) => editorProvider.updateAdjustment(shadows: value),
            ),
            _buildSlider(
              'ホワイト',
              adjustments.whites,
              -100.0,
              100.0,
              (value) => editorProvider.updateAdjustment(whites: value),
            ),
            _buildSlider(
              'ブラック',
              adjustments.blacks,
              -100.0,
              100.0,
              (value) => editorProvider.updateAdjustment(blacks: value),
            ),
            _buildSlider(
              'コントラスト',
              adjustments.contrast,
              -100.0,
              100.0,
              (value) => editorProvider.updateAdjustment(contrast: value),
            ),
            _buildSlider(
              '彩度',
              adjustments.saturation,
              -100.0,
              100.0,
              (value) => editorProvider.updateAdjustment(saturation: value),
            ),
            _buildSlider(
              '自然な彩度',
              adjustments.vibrance,
              -100.0,
              100.0,
              (value) => editorProvider.updateAdjustment(vibrance: value),
            ),
          ],
        );
      },
    );
  }

  Widget _buildColorAdjustments() {
    return Consumer<EditorProvider>(
      builder: (context, editorProvider, child) {
        final adjustments = editorProvider.adjustments;
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSlider(
              '色温度',
              adjustments.temperature,
              -1000.0,
              1000.0,
              (value) => editorProvider.updateAdjustment(temperature: value),
            ),
            _buildSlider(
              '色調',
              adjustments.tint,
              -100.0,
              100.0,
              (value) => editorProvider.updateAdjustment(tint: value),
            ),
            const SizedBox(height: 16),
            Text(
              'HSL調整（今後のアップデートで実装予定）',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailAdjustments() {
    return Consumer<EditorProvider>(
      builder: (context, editorProvider, child) {
        final adjustments = editorProvider.adjustments;
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSlider(
              'シャープ',
              adjustments.clarity,
              0.0,
              100.0,
              (value) => editorProvider.updateAdjustment(clarity: value),
            ),
            const SizedBox(height: 16),
            Text(
              'ノイズ除去（今後のアップデートで実装予定）',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransformAdjustments() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Text(
          '変形機能（今後のアップデートで実装予定）',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value.toStringAsFixed(1),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 10).toInt(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'export':
        _showExportDialog(context);
        break;
      case 'reset':
        _showResetDialog(context);
        break;
    }
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エクスポート'),
        content: const Text('エクスポート機能は今後のアップデートで実装予定です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('調整をリセット'),
        content: const Text('すべての調整をリセットしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              context.read<EditorProvider>().resetAdjustments();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('調整をリセットしました')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('リセット'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditorProvider>().closeImage();
    });
    super.dispose();
  }
}