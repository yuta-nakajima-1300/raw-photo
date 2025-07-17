import 'package:flutter/material.dart';

import '../models/raw_image.dart';
import '../models/adjustment_parameters.dart';
import '../models/edit_session.dart';
import '../services/raw_processing_service.dart';
import '../services/database_service.dart';

class EditorProvider extends ChangeNotifier {
  final RawProcessingService _rawProcessingService = RawProcessingService();
  final DatabaseService _databaseService = DatabaseService.instance;
  
  RawImage? _currentImage;
  EditSession? _currentSession;
  AdjustmentParameters _adjustments = AdjustmentParameters();
  bool _isProcessing = false;
  bool _hasUnsavedChanges = false;
  String? _previewImagePath;
  List<AdjustmentParameters> _history = [];
  int _historyIndex = -1;

  // Getters
  RawImage? get currentImage => _currentImage;
  EditSession? get currentSession => _currentSession;
  AdjustmentParameters get adjustments => _adjustments;
  bool get isProcessing => _isProcessing;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  String? get previewImagePath => _previewImagePath;
  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  Future<void> openImage(RawImage image) async {
    _setProcessing(true);
    
    try {
      _currentImage = image;
      
      // 既存の編集セッションを検索
      _currentSession = await _databaseService.getEditSessionByImageId(image.id!);
      
      if (_currentSession == null) {
        // 新しい編集セッションを作成
        _currentSession = EditSession(
          imageId: image.id!,
          sessionName: 'Edit ${image.fileName}',
          createdAt: DateTime.now(),
          lastModified: DateTime.now(),
        );
        _currentSession = await _databaseService.insertEditSession(_currentSession!);
        _adjustments = AdjustmentParameters();
      } else {
        // 既存の調整パラメータを読み込み
        _adjustments = await _databaseService.getLatestAdjustments(_currentSession!.id!);
      }
      
      // 履歴をクリア
      _history.clear();
      _history.add(_adjustments.copy());
      _historyIndex = 0;
      
      // プレビュー画像を生成
      await _generatePreview();
      
      _hasUnsavedChanges = false;
    } catch (e) {
      debugPrint('Error opening image: $e');
    } finally {
      _setProcessing(false);
    }
  }

  void updateAdjustment({
    double? exposure,
    double? highlights,
    double? shadows,
    double? whites,
    double? blacks,
    double? clarity,
    double? vibrance,
    double? saturation,
    double? temperature,
    double? tint,
    double? contrast,
  }) {
    _adjustments = _adjustments.copyWith(
      exposure: exposure,
      highlights: highlights,
      shadows: shadows,
      whites: whites,
      blacks: blacks,
      clarity: clarity,
      vibrance: vibrance,
      saturation: saturation,
      temperature: temperature,
      tint: tint,
      contrast: contrast,
    );
    
    _addToHistory(_adjustments);
    _hasUnsavedChanges = true;
    
    // リアルタイムプレビュー更新
    _generatePreview();
    
    notifyListeners();
  }

  Future<void> _generatePreview() async {
    if (_currentImage == null) return;
    
    try {
      _previewImagePath = await _rawProcessingService.generatePreview(
        _currentImage!.filePath,
        _adjustments,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error generating preview: $e');
    }
  }

  void _addToHistory(AdjustmentParameters adjustments) {
    // 現在の位置以降の履歴を削除（新しい編集をした場合）
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    
    _history.add(adjustments.copy());
    _historyIndex = _history.length - 1;
    
    // 履歴の制限（最大50項目）
    if (_history.length > 50) {
      _history.removeAt(0);
      _historyIndex--;
    }
  }

  void undo() {
    if (canUndo) {
      _historyIndex--;
      _adjustments = _history[_historyIndex].copy();
      _hasUnsavedChanges = true;
      _generatePreview();
      notifyListeners();
    }
  }

  void redo() {
    if (canRedo) {
      _historyIndex++;
      _adjustments = _history[_historyIndex].copy();
      _hasUnsavedChanges = true;
      _generatePreview();
      notifyListeners();
    }
  }

  void resetAdjustments() {
    _adjustments = AdjustmentParameters();
    _addToHistory(_adjustments);
    _hasUnsavedChanges = true;
    _generatePreview();
    notifyListeners();
  }

  Future<void> saveSession() async {
    if (_currentSession == null || !_hasUnsavedChanges) return;
    
    try {
      _setProcessing(true);
      
      // 調整パラメータをデータベースに保存
      await _databaseService.insertAdjustment(
        _currentSession!.id!,
        _adjustments,
      );
      
      // セッションの最終更新日時を更新
      _currentSession!.lastModified = DateTime.now();
      await _databaseService.updateEditSession(_currentSession!);
      
      _hasUnsavedChanges = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving session: $e');
    } finally {
      _setProcessing(false);
    }
  }

  Future<String?> exportImage({
    required String outputPath,
    required String format,
    int? quality,
  }) async {
    if (_currentImage == null) return null;
    
    try {
      _setProcessing(true);
      
      final exportedPath = await _rawProcessingService.exportImage(
        _currentImage!.filePath,
        _adjustments,
        outputPath: outputPath,
        format: format,
        quality: quality,
      );
      
      return exportedPath;
    } catch (e) {
      debugPrint('Error exporting image: $e');
      return null;
    } finally {
      _setProcessing(false);
    }
  }

  void applyPreset(AdjustmentParameters preset) {
    _adjustments = preset.copy();
    _addToHistory(_adjustments);
    _hasUnsavedChanges = true;
    _generatePreview();
    notifyListeners();
  }

  Future<void> closeImage() async {
    if (_hasUnsavedChanges) {
      await saveSession();
    }
    
    _currentImage = null;
    _currentSession = null;
    _adjustments = AdjustmentParameters();
    _previewImagePath = null;
    _history.clear();
    _historyIndex = -1;
    _hasUnsavedChanges = false;
    
    notifyListeners();
  }

  void _setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }
}