import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/raw_image.dart';
import '../services/file_service.dart';
import '../services/database_service.dart';

class FileProvider extends ChangeNotifier {
  final FileService _fileService = FileService();
  final DatabaseService _databaseService = DatabaseService.instance;
  
  List<RawImage> _rawImages = [];
  List<RawImage> _filteredImages = [];
  bool _isLoading = false;
  String _currentFilter = '';
  String _sortBy = 'dateModified';
  bool _sortAscending = false;

  // Getters
  List<RawImage> get rawImages => _filteredImages;
  bool get isLoading => _isLoading;
  String get currentFilter => _currentFilter;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;
  int get totalImages => _rawImages.length;

  Future<void> loadFiles() async {
    _setLoading(true);
    
    try {
      // データベースから既存の画像リストを読み込み
      _rawImages = await _databaseService.getAllRawImages();
      _applyFilterAndSort();
      
      // バックグラウンドでファイルシステムをスキャン
      _scanFileSystem();
    } catch (e) {
      debugPrint('Error loading files: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _scanFileSystem() async {
    try {
      final newImages = await _fileService.scanForRawImages();
      
      // 新しい画像をデータベースに追加
      for (final image in newImages) {
        final exists = _rawImages.any((existing) => existing.filePath == image.filePath);
        if (!exists) {
          await _databaseService.insertRawImage(image);
          _rawImages.add(image);
        }
      }
      
      _applyFilterAndSort();
    } catch (e) {
      debugPrint('Error scanning file system: $e');
    }
  }

  Future<bool> requestPermissions() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<void> importImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['cr2', 'nef', 'arw', 'dng', 'raf', 'rw2', 'orf'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        _setLoading(true);
        
        for (final file in result.files) {
          if (file.path != null) {
            final rawImage = await _fileService.importRawImage(file.path!);
            if (rawImage != null) {
              await _databaseService.insertRawImage(rawImage);
              _rawImages.add(rawImage);
            }
          }
        }
        
        _applyFilterAndSort();
        _setLoading(false);
      }
    } catch (e) {
      debugPrint('Error importing images: $e');
      _setLoading(false);
    }
  }

  void setFilter(String filter) {
    _currentFilter = filter;
    _applyFilterAndSort();
  }

  void setSorting(String sortBy, bool ascending) {
    _sortBy = sortBy;
    _sortAscending = ascending;
    _applyFilterAndSort();
  }

  void _applyFilterAndSort() {
    // フィルタリング
    if (_currentFilter.isEmpty) {
      _filteredImages = List.from(_rawImages);
    } else {
      _filteredImages = _rawImages.where((image) {
        return image.fileName.toLowerCase().contains(_currentFilter.toLowerCase()) ||
               image.cameraModel.toLowerCase().contains(_currentFilter.toLowerCase()) ||
               image.lensModel.toLowerCase().contains(_currentFilter.toLowerCase());
      }).toList();
    }

    // ソート
    _filteredImages.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case 'fileName':
          comparison = a.fileName.compareTo(b.fileName);
          break;
        case 'dateModified':
          comparison = a.dateModified.compareTo(b.dateModified);
          break;
        case 'dateCreated':
          comparison = a.dateCreated.compareTo(b.dateCreated);
          break;
        case 'fileSize':
          comparison = a.fileSize.compareTo(b.fileSize);
          break;
        case 'rating':
          comparison = a.rating.compareTo(b.rating);
          break;
        default:
          comparison = a.dateModified.compareTo(b.dateModified);
      }
      
      return _sortAscending ? comparison : -comparison;
    });

    notifyListeners();
  }

  Future<void> deleteImage(RawImage image) async {
    try {
      await _databaseService.deleteRawImage(image.id!);
      _rawImages.removeWhere((img) => img.id == image.id);
      _applyFilterAndSort();
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  Future<void> updateImageRating(RawImage image, int rating) async {
    try {
      image.rating = rating;
      await _databaseService.updateRawImage(image);
      _applyFilterAndSort();
    } catch (e) {
      debugPrint('Error updating image rating: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void refresh() {
    loadFiles();
  }

  RawImage? getImageById(String id) {
    try {
      return _rawImages.firstWhere((image) => image.id == id);
    } catch (e) {
      return null;
    }
  }
}