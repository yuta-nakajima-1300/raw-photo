import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/raw_image.dart';
import 'raw_processing_service.dart';

class FileService {
  static const List<String> supportedRawExtensions = [
    'cr2', 'nef', 'arw', 'dng', 'raf', 'rw2', 'orf', 
    'pef', 'srw', '3fr', 'fff', 'iiq', 'mos', 'crw',
    'erf', 'mef', 'mrw', 'x3f'
  ];
  
  final RawProcessingService _rawProcessingService = RawProcessingService.instance;
  
  /// デバイス内のRAW画像をスキャン
  Future<List<RawImage>> scanForRawImages() async {
    debugPrint('Scanning for RAW images...');
    
    try {
      final List<RawImage> rawImages = [];
      
      // 主要なディレクトリをスキャン
      final scanDirectories = await _getScanDirectories();
      
      for (final directory in scanDirectories) {
        if (await directory.exists()) {
          debugPrint('Scanning directory: ${directory.path}');
          final images = await _scanDirectory(directory);
          rawImages.addAll(images);
        }
      }
      
      debugPrint('Found ${rawImages.length} RAW images');
      return rawImages;
    } catch (e) {
      debugPrint('Error scanning for RAW images: $e');
      return [];
    }
  }
  
  /// RAW画像をインポート
  Future<RawImage?> importRawImage(String filePath) async {
    debugPrint('Importing RAW image: $filePath');
    
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('File does not exist: $filePath');
        return null;
      }
      
      // ファイル拡張子をチェック
      final extension = path.extension(filePath).toLowerCase().substring(1);
      if (!supportedRawExtensions.contains(extension)) {
        debugPrint('Unsupported file format: $extension');
        return null;
      }
      
      // ファイル情報を取得
      final fileStat = await file.stat();
      final fileName = path.basename(filePath);
      
      // メタデータを抽出
      final metadata = await _extractMetadataFromFile(filePath);
      
      // サムネイルを生成
      final thumbnailPath = await _generateAndSaveThumbnail(filePath, fileName);
      
      final rawImage = RawImage(
        filePath: filePath,
        fileName: fileName,
        fileSize: fileStat.size,
        dateCreated: fileStat.changed,
        dateModified: fileStat.modified,
        cameraMake: metadata?['camera_make'],
        cameraModel: metadata?['camera_model'],
        lensModel: metadata?['lens_model'],
        iso: metadata?['iso']?.toInt(),
        aperture: metadata?['aperture']?.toDouble(),
        shutterSpeed: metadata?['shutter_speed'],
        focalLength: metadata?['focal_length']?.toDouble(),
        flashUsed: metadata?['flash_used'] == true,
        orientation: metadata?['orientation']?.toInt() ?? 1,
        whiteBalance: metadata?['white_balance'],
        colorSpace: metadata?['color_space'],
        imageWidth: metadata?['image_width']?.toInt(),
        imageHeight: metadata?['image_height']?.toInt(),
        thumbnailPath: thumbnailPath,
      );
      
      debugPrint('RAW image imported successfully: $fileName');
      return rawImage;
    } catch (e) {
      debugPrint('Error importing RAW image: $e');
      return null;
    }
  }
  
  /// RAW画像ファイルを削除
  Future<bool> deleteRawImageFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('RAW image file deleted: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting RAW image file: $e');
      return false;
    }
  }
  
  /// RAW画像ファイルを移動
  Future<String?> moveRawImageFile(String sourcePath, String destinationDir) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return null;
      }
      
      final fileName = path.basename(sourcePath);
      final destinationPath = path.join(destinationDir, fileName);
      
      // 同名ファイルが存在する場合は連番を付加
      final finalPath = await _getUniqueFilePath(destinationPath);
      
      await sourceFile.copy(finalPath);
      await sourceFile.delete();
      
      debugPrint('RAW image file moved: $sourcePath -> $finalPath');
      return finalPath;
    } catch (e) {
      debugPrint('Error moving RAW image file: $e');
      return null;
    }
  }
  
  /// RAW画像ファイルをコピー
  Future<String?> copyRawImageFile(String sourcePath, String destinationDir) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return null;
      }
      
      final fileName = path.basename(sourcePath);
      final destinationPath = path.join(destinationDir, fileName);
      
      final finalPath = await _getUniqueFilePath(destinationPath);
      
      await sourceFile.copy(finalPath);
      
      debugPrint('RAW image file copied: $sourcePath -> $finalPath');
      return finalPath;
    } catch (e) {
      debugPrint('Error copying RAW image file: $e');
      return null;
    }
  }
  
  /// ファイルサイズをフォーマット
  String formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    } else if (sizeInBytes < 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
  
  /// 一時ディレクトリを取得
  Future<Directory> getTempDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final rawEditorTempDir = Directory(path.join(tempDir.path, 'raw_editor'));
    
    if (!await rawEditorTempDir.exists()) {
      await rawEditorTempDir.create(recursive: true);
    }
    
    return rawEditorTempDir;
  }
  
  /// アプリケーションドキュメントディレクトリを取得
  Future<Directory> getAppDocumentsDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final rawEditorDocDir = Directory(path.join(appDocDir.path, 'raw_editor'));
    
    if (!await rawEditorDocDir.exists()) {
      await rawEditorDocDir.create(recursive: true);
    }
    
    return rawEditorDocDir;
  }
  
  /// スキャン対象ディレクトリを取得
  Future<List<Directory>> _getScanDirectories() async {
    final directories = <Directory>[];
    
    if (Platform.isAndroid) {
      // Android の一般的なカメラフォルダ
      const androidPaths = [
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/Pictures',
        '/storage/emulated/0/Camera',
        '/sdcard/DCIM',
        '/sdcard/Pictures',
      ];
      
      for (final dirPath in androidPaths) {
        final dir = Directory(dirPath);
        if (await dir.exists()) {
          directories.add(dir);
        }
      }
      
      // 外部ストレージもチェック
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          directories.add(Directory(path.join(externalDir.path, 'DCIM')));
          directories.add(Directory(path.join(externalDir.path, 'Pictures')));
        }
      } catch (e) {
        debugPrint('Error accessing external storage: $e');
      }
    } else if (Platform.isIOS) {
      // iOS では写真ライブラリへの直接アクセスは制限されているため、
      // アプリのドキュメントディレクトリのみをスキャン
      final documentsDir = await getApplicationDocumentsDirectory();
      directories.add(documentsDir);
    }
    
    return directories;
  }
  
  /// ディレクトリをスキャンしてRAW画像を検索
  Future<List<RawImage>> _scanDirectory(Directory directory) async {
    final rawImages = <RawImage>[];
    
    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final extension = path.extension(entity.path).toLowerCase().substring(1);
          
          if (supportedRawExtensions.contains(extension)) {
            final rawImage = await importRawImage(entity.path);
            if (rawImage != null) {
              rawImages.add(rawImage);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning directory ${directory.path}: $e');
    }
    
    return rawImages;
  }
  
  /// ファイルからメタデータを抽出
  Future<Map<String, dynamic>?> _extractMetadataFromFile(String filePath) async {
    try {
      final processorHandle = _rawProcessingService.createProcessor();
      
      final loaded = await _rawProcessingService.loadRawFile(processorHandle, filePath);
      if (!loaded) {
        _rawProcessingService.destroyProcessor(processorHandle);
        return null;
      }
      
      final metadata = await _rawProcessingService.extractMetadata(processorHandle);
      _rawProcessingService.destroyProcessor(processorHandle);
      
      return metadata;
    } catch (e) {
      debugPrint('Error extracting metadata from $filePath: $e');
      return null;
    }
  }
  
  /// サムネイルを生成して保存
  Future<String?> _generateAndSaveThumbnail(String filePath, String fileName) async {
    try {
      final processorHandle = _rawProcessingService.createProcessor();
      
      final loaded = await _rawProcessingService.loadRawFile(processorHandle, filePath);
      if (!loaded) {
        _rawProcessingService.destroyProcessor(processorHandle);
        return null;
      }
      
      final thumbnailData = await _rawProcessingService.generateThumbnail(processorHandle);
      _rawProcessingService.destroyProcessor(processorHandle);
      
      if (thumbnailData != null) {
        // サムネイルを保存
        final tempDir = await getTempDirectory();
        final thumbnailsDir = Directory(path.join(tempDir.path, 'thumbnails'));
        
        if (!await thumbnailsDir.exists()) {
          await thumbnailsDir.create(recursive: true);
        }
        
        final nameWithoutExt = path.basenameWithoutExtension(fileName);
        final thumbnailPath = path.join(thumbnailsDir.path, '${nameWithoutExt}_thumb.jpg');
        
        final thumbnailFile = File(thumbnailPath);
        await thumbnailFile.writeAsBytes(thumbnailData);
        
        return thumbnailPath;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error generating thumbnail for $filePath: $e');
      return null;
    }
  }
  
  /// ユニークなファイルパスを取得（重複回避）
  Future<String> _getUniqueFilePath(String originalPath) async {
    final file = File(originalPath);
    if (!await file.exists()) {
      return originalPath;
    }
    
    final dir = path.dirname(originalPath);
    final nameWithoutExt = path.basenameWithoutExtension(originalPath);
    final extension = path.extension(originalPath);
    
    int counter = 1;
    String uniquePath;
    
    do {
      uniquePath = path.join(dir, '${nameWithoutExt}_$counter$extension');
      counter++;
    } while (await File(uniquePath).exists());
    
    return uniquePath;
  }
  
  /// サポートされているファイル形式かチェック
  bool isSupportedRawFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase().substring(1);
    return supportedRawExtensions.contains(extension);
  }
  
  /// ファイルが存在するかチェック
  Future<bool> fileExists(String filePath) async {
    try {
      return await File(filePath).exists();
    } catch (e) {
      return false;
    }
  }
  
  /// ディレクトリのサイズを計算
  Future<int> calculateDirectorySize(String directoryPath) async {
    int totalSize = 0;
    
    try {
      final directory = Directory(directoryPath);
      
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
    } catch (e) {
      debugPrint('Error calculating directory size: $e');
    }
    
    return totalSize;
  }
  
  /// 一時ファイルをクリーンアップ
  Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTempDirectory();
      
      await for (final entity in tempDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = DateTime.now().difference(stat.modified);
          
          // 7日以上古いファイルを削除
          if (age.inDays > 7) {
            await entity.delete();
            debugPrint('Cleaned up temp file: ${entity.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('Error during temp file cleanup: $e');
    }
  }
}