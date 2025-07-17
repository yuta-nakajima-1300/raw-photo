import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        elevation: 0,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // UI設定
              _buildSectionHeader(context, 'UI設定'),
              
              SwitchListTile(
                title: const Text('ダークモード'),
                subtitle: const Text('アプリのテーマを暗色に設定'),
                value: settings.isDarkMode,
                onChanged: settings.setDarkMode,
              ),
              
              SwitchListTile(
                title: const Text('ヒストグラム表示'),
                subtitle: const Text('画像一覧で統計情報を表示'),
                value: settings.showHistogram,
                onChanged: settings.setShowHistogram,
              ),
              
              SwitchListTile(
                title: const Text('リアルタイムプレビュー'),
                subtitle: const Text('調整中に即座にプレビューを更新'),
                value: settings.enableRealTimePreview,
                onChanged: settings.setEnableRealTimePreview,
              ),
              
              const Divider(),
              
              // 処理設定
              _buildSectionHeader(context, '処理設定'),
              
              ListTile(
                title: const Text('プレビュー品質'),
                subtitle: Text(_getQualityLabel(settings.previewQuality)),
                trailing: DropdownButton<int>(
                  value: settings.previewQuality,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('低品質')),
                    DropdownMenuItem(value: 2, child: Text('中品質')),
                    DropdownMenuItem(value: 3, child: Text('高品質')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      settings.setPreviewQuality(value);
                    }
                  },
                ),
              ),
              
              ListTile(
                title: const Text('キャッシュサイズ'),
                subtitle: Text('${settings.maxCacheSize}MB'),
                trailing: SizedBox(
                  width: 100,
                  child: Slider(
                    value: settings.maxCacheSize.toDouble(),
                    min: 256,
                    max: 4096,
                    divisions: 15,
                    label: '${settings.maxCacheSize}MB',
                    onChanged: (value) {
                      settings.setMaxCacheSize(value.toInt());
                    },
                  ),
                ),
              ),
              
              SwitchListTile(
                title: const Text('GPU加速'),
                subtitle: const Text('可能な場合はGPUを使用して処理を高速化'),
                value: settings.useGpuAcceleration,
                onChanged: settings.setUseGpuAcceleration,
              ),
              
              const Divider(),
              
              // エクスポート設定
              _buildSectionHeader(context, 'エクスポート設定'),
              
              ListTile(
                title: const Text('デフォルト出力形式'),
                subtitle: Text(settings.defaultExportFormat),
                trailing: DropdownButton<String>(
                  value: settings.defaultExportFormat,
                  items: const [
                    DropdownMenuItem(value: 'JPEG', child: Text('JPEG')),
                    DropdownMenuItem(value: 'PNG', child: Text('PNG')),
                    DropdownMenuItem(value: 'TIFF', child: Text('TIFF')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      settings.setDefaultExportFormat(value);
                    }
                  },
                ),
              ),
              
              if (settings.defaultExportFormat == 'JPEG')
                ListTile(
                  title: const Text('JPEG品質'),
                  subtitle: Text('${settings.jpegQuality}%'),
                  trailing: SizedBox(
                    width: 100,
                    child: Slider(
                      value: settings.jpegQuality.toDouble(),
                      min: 50,
                      max: 100,
                      divisions: 10,
                      label: '${settings.jpegQuality}%',
                      onChanged: (value) {
                        settings.setJpegQuality(value.toInt());
                      },
                    ),
                  ),
                ),
              
              SwitchListTile(
                title: const Text('メタデータを保持'),
                subtitle: const Text('エクスポート時にEXIF情報を含める'),
                value: settings.preserveMetadata,
                onChanged: settings.setPreserveMetadata,
              ),
              
              const Divider(),
              
              // アプリ情報
              _buildSectionHeader(context, 'アプリ情報'),
              
              ListTile(
                title: const Text('バージョン'),
                subtitle: const Text('1.0.0'),
                trailing: const Icon(Icons.info_outline),
              ),
              
              ListTile(
                title: const Text('オープンソースライセンス'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  showLicensePage(context: context);
                },
              ),
              
              const SizedBox(height: 32),
              
              // リセットボタン
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => _showResetDialog(context, settings),
                  icon: const Icon(Icons.restore),
                  label: const Text('設定をリセット'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getQualityLabel(int quality) {
    switch (quality) {
      case 1:
        return '低品質 - 高速';
      case 2:
        return '中品質 - バランス';
      case 3:
        return '高品質 - 低速';
      default:
        return '中品質';
    }
  }

  void _showResetDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('設定をリセット'),
        content: const Text('すべての設定をデフォルト値に戻しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              settings.resetToDefaults();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('設定をリセットしました'),
                ),
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
}