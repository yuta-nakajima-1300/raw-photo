import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  late SharedPreferences _prefs;
  
  // UI設定
  bool _isDarkMode = false;
  bool _showHistogram = true;
  bool _enableRealTimePreview = true;
  
  // 処理設定
  int _previewQuality = 2; // 1:低品質, 2:中品質, 3:高品質
  int _maxCacheSize = 1024; // MB
  bool _useGpuAcceleration = true;
  
  // ファイル設定
  String _defaultExportFormat = 'JPEG';
  int _jpegQuality = 95;
  bool _preserveMetadata = true;
  String _defaultOutputDirectory = '';

  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get showHistogram => _showHistogram;
  bool get enableRealTimePreview => _enableRealTimePreview;
  int get previewQuality => _previewQuality;
  int get maxCacheSize => _maxCacheSize;
  bool get useGpuAcceleration => _useGpuAcceleration;
  String get defaultExportFormat => _defaultExportFormat;
  int get jpegQuality => _jpegQuality;
  bool get preserveMetadata => _preserveMetadata;
  String get defaultOutputDirectory => _defaultOutputDirectory;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  void _loadSettings() {
    _isDarkMode = _prefs.getBool('isDarkMode') ?? false;
    _showHistogram = _prefs.getBool('showHistogram') ?? true;
    _enableRealTimePreview = _prefs.getBool('enableRealTimePreview') ?? true;
    _previewQuality = _prefs.getInt('previewQuality') ?? 2;
    _maxCacheSize = _prefs.getInt('maxCacheSize') ?? 1024;
    _useGpuAcceleration = _prefs.getBool('useGpuAcceleration') ?? true;
    _defaultExportFormat = _prefs.getString('defaultExportFormat') ?? 'JPEG';
    _jpegQuality = _prefs.getInt('jpegQuality') ?? 95;
    _preserveMetadata = _prefs.getBool('preserveMetadata') ?? true;
    _defaultOutputDirectory = _prefs.getString('defaultOutputDirectory') ?? '';
    notifyListeners();
  }

  // Setters
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _prefs.setBool('isDarkMode', value);
    notifyListeners();
  }

  Future<void> setShowHistogram(bool value) async {
    _showHistogram = value;
    await _prefs.setBool('showHistogram', value);
    notifyListeners();
  }

  Future<void> setEnableRealTimePreview(bool value) async {
    _enableRealTimePreview = value;
    await _prefs.setBool('enableRealTimePreview', value);
    notifyListeners();
  }

  Future<void> setPreviewQuality(int value) async {
    _previewQuality = value;
    await _prefs.setInt('previewQuality', value);
    notifyListeners();
  }

  Future<void> setMaxCacheSize(int value) async {
    _maxCacheSize = value;
    await _prefs.setInt('maxCacheSize', value);
    notifyListeners();
  }

  Future<void> setUseGpuAcceleration(bool value) async {
    _useGpuAcceleration = value;
    await _prefs.setBool('useGpuAcceleration', value);
    notifyListeners();
  }

  Future<void> setDefaultExportFormat(String value) async {
    _defaultExportFormat = value;
    await _prefs.setString('defaultExportFormat', value);
    notifyListeners();
  }

  Future<void> setJpegQuality(int value) async {
    _jpegQuality = value;
    await _prefs.setInt('jpegQuality', value);
    notifyListeners();
  }

  Future<void> setPreserveMetadata(bool value) async {
    _preserveMetadata = value;
    await _prefs.setBool('preserveMetadata', value);
    notifyListeners();
  }

  Future<void> setDefaultOutputDirectory(String value) async {
    _defaultOutputDirectory = value;
    await _prefs.setString('defaultOutputDirectory', value);
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    await _prefs.clear();
    _loadSettings();
  }
}