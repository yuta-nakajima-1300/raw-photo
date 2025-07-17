import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/file_provider.dart';

class SortFilterSheet extends StatefulWidget {
  const SortFilterSheet({super.key});

  @override
  State<SortFilterSheet> createState() => _SortFilterSheetState();
}

class _SortFilterSheetState extends State<SortFilterSheet> {
  late String _selectedSortBy;
  late bool _sortAscending;
  String _filterText = '';
  String _selectedCameraFilter = '';
  String _selectedLensFilter = '';
  int _selectedRatingFilter = 0;

  final List<String> _sortOptions = [
    'dateModified',
    'dateCreated',
    'fileName',
    'fileSize',
    'rating',
  ];

  final Map<String, String> _sortLabels = {
    'dateModified': '更新日時',
    'dateCreated': '作成日時',
    'fileName': 'ファイル名',
    'fileSize': 'ファイルサイズ',
    'rating': '評価',
  };

  @override
  void initState() {
    super.initState();
    final fileProvider = context.read<FileProvider>();
    _selectedSortBy = fileProvider.sortBy;
    _sortAscending = fileProvider.sortAscending;
    _filterText = fileProvider.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Row(
            children: [
              Text(
                'ソート・フィルター',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ソート設定
                  _buildSortSection(),
                  
                  const SizedBox(height: 24),
                  
                  // フィルター設定
                  _buildFilterSection(),
                ],
              ),
            ),
          ),
          
          // アクションボタン
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetFilters,
                  child: const Text('リセット'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('適用'),
                ),
              ),
            ],
          ),
          
          // 安全エリア対応
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ソート',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // ソート項目選択
        ...(_sortOptions.map((option) {
          return RadioListTile<String>(
            title: Text(_sortLabels[option]!),
            value: option,
            groupValue: _selectedSortBy,
            onChanged: (value) {
              setState(() {
                _selectedSortBy = value!;
              });
            },
            contentPadding: EdgeInsets.zero,
          );
        }).toList()),
        
        const SizedBox(height: 16),
        
        // ソート順序
        SwitchListTile(
          title: const Text('昇順で並び替え'),
          subtitle: Text(_sortAscending ? '古い順・小さい順' : '新しい順・大きい順'),
          value: _sortAscending,
          onChanged: (value) {
            setState(() {
              _sortAscending = value;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'フィルター',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // テキストフィルター
        TextField(
          decoration: const InputDecoration(
            labelText: 'ファイル名・カメラ・レンズで検索',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _filterText = value;
            });
          },
          controller: TextEditingController(text: _filterText),
        ),
        
        const SizedBox(height: 16),
        
        // カメラフィルター
        Consumer<FileProvider>(
          builder: (context, fileProvider, child) {
            final cameras = _getUniqueCameras(fileProvider);
            
            return DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'カメラで絞り込み',
                border: OutlineInputBorder(),
              ),
              value: _selectedCameraFilter.isEmpty ? null : _selectedCameraFilter,
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('すべてのカメラ'),
                ),
                ...cameras.map((camera) {
                  return DropdownMenuItem(
                    value: camera,
                    child: Text(camera),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCameraFilter = value ?? '';
                });
              },
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        // レンズフィルター
        Consumer<FileProvider>(
          builder: (context, fileProvider, child) {
            final lenses = _getUniqueLenses(fileProvider);
            
            return DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'レンズで絞り込み',
                border: OutlineInputBorder(),
              ),
              value: _selectedLensFilter.isEmpty ? null : _selectedLensFilter,
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('すべてのレンズ'),
                ),
                ...lenses.map((lens) {
                  return DropdownMenuItem(
                    value: lens,
                    child: Text(lens),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedLensFilter = value ?? '';
                });
              },
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        // 評価フィルター
        Text(
          '評価フィルター',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        
        const SizedBox(height: 8),
        
        ...([0, 1, 2, 3, 4, 5].map((rating) {
          return RadioListTile<int>(
            title: Row(
              children: [
                if (rating == 0)
                  const Text('すべての評価')
                else ...[
                  Text('$rating'),
                  const SizedBox(width: 8),
                  ...List.generate(rating, (index) {
                    return const Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    );
                  }),
                  const Text(' 以上'),
                ],
              ],
            ),
            value: rating,
            groupValue: _selectedRatingFilter,
            onChanged: (value) {
              setState(() {
                _selectedRatingFilter = value!;
              });
            },
            contentPadding: EdgeInsets.zero,
          );
        }).toList()),
      ],
    );
  }

  List<String> _getUniqueCameras(FileProvider fileProvider) {
    final cameras = <String>{};
    
    for (final image in fileProvider.rawImages) {
      if (image.cameraModel?.isNotEmpty == true) {
        cameras.add('${image.cameraMake} ${image.cameraModel}');
      }
    }
    
    return cameras.toList()..sort();
  }

  List<String> _getUniqueLenses(FileProvider fileProvider) {
    final lenses = <String>{};
    
    for (final image in fileProvider.rawImages) {
      if (image.lensModel?.isNotEmpty == true) {
        lenses.add(image.lensModel!);
      }
    }
    
    return lenses.toList()..sort();
  }

  void _resetFilters() {
    setState(() {
      _selectedSortBy = 'dateModified';
      _sortAscending = false;
      _filterText = '';
      _selectedCameraFilter = '';
      _selectedLensFilter = '';
      _selectedRatingFilter = 0;
    });
    
    // プロバイダーにも適用
    final fileProvider = context.read<FileProvider>();
    fileProvider.setSorting(_selectedSortBy, _sortAscending);
    fileProvider.setFilter('');
    
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('フィルターをリセットしました'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _applyFilters() {
    // フィルターテキストを構築
    String combinedFilter = _filterText;
    
    if (_selectedCameraFilter.isNotEmpty) {
      combinedFilter = combinedFilter.isEmpty 
          ? _selectedCameraFilter 
          : '$combinedFilter $_selectedCameraFilter';
    }
    
    if (_selectedLensFilter.isNotEmpty) {
      combinedFilter = combinedFilter.isEmpty 
          ? _selectedLensFilter 
          : '$combinedFilter $_selectedLensFilter';
    }
    
    // プロバイダーに適用
    final fileProvider = context.read<FileProvider>();
    fileProvider.setSorting(_selectedSortBy, _sortAscending);
    fileProvider.setFilter(combinedFilter);
    
    // TODO: 評価フィルターの実装
    
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('フィルターを適用しました'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// 検索バーウィジェット
class SearchBarWidget extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;
  final VoidCallback? onClear;

  const SearchBarWidget({
    super.key,
    this.initialValue = '',
    required this.onChanged,
    this.onClear,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: 'ファイル名、カメラ、レンズで検索...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    widget.onClear?.call();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        onChanged: widget.onChanged,
        onSubmitted: (value) {
          _focusNode.unfocus();
        },
      ),
    );
  }
}

// クイックフィルターチップ
class QuickFilterChips extends StatelessWidget {
  final Function(String) onFilterSelected;
  final String currentFilter;

  const QuickFilterChips({
    super.key,
    required this.onFilterSelected,
    this.currentFilter = '',
  });

  @override
  Widget build(BuildContext context) {
    final quickFilters = [
      {'label': '今日', 'filter': 'today'},
      {'label': '今週', 'filter': 'week'},
      {'label': '評価済み', 'filter': 'rated'},
      {'label': 'Canon', 'filter': 'Canon'},
      {'label': 'Nikon', 'filter': 'Nikon'},
      {'label': 'Sony', 'filter': 'Sony'},
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: quickFilters.map((filter) {
          final isSelected = currentFilter.contains(filter['filter']!);
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter['label']!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onFilterSelected(filter['filter']!);
                } else {
                  onFilterSelected('');
                }
              },
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          );
        }).toList(),
      ),
    );
  }
}