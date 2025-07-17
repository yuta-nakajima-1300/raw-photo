import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import '../models/adjustment_parameters.dart';
import '../models/raw_image.dart';

// C APIの関数シグネチャ定義
typedef CreateProcessorC = Int64 Function();
typedef CreateProcessorDart = int Function();

typedef DestroyProcessorC = Void Function(Int64);
typedef DestroyProcessorDart = void Function(int);

typedef LoadFileC = Pointer<FFIResult> Function(Int64, Pointer<Utf8>);
typedef LoadFileDart = Pointer<FFIResult> Function(int, Pointer<Utf8>);

typedef ExtractMetadataC = Pointer<FFIResult> Function(Int64);
typedef ExtractMetadataDart = Pointer<FFIResult> Function(int);

typedef GenerateThumbnailC = Pointer<FFIImageData> Function(Int64, Uint32);
typedef GenerateThumbnailDart = Pointer<FFIImageData> Function(int, int);

typedef GeneratePreviewC = Pointer<FFIImageData> Function(Int64, Pointer<FFIAdjustmentParams>, Pointer<FFIProcessingOptions>);
typedef GeneratePreviewDart = Pointer<FFIImageData> Function(int, Pointer<FFIAdjustmentParams>, Pointer<FFIProcessingOptions>);

typedef ProcessFullImageC = Pointer<FFIImageData> Function(Int64, Pointer<FFIAdjustmentParams>, Pointer<FFIProcessingOptions>);
typedef ProcessFullImageDart = Pointer<FFIImageData> Function(int, Pointer<FFIAdjustmentParams>, Pointer<FFIProcessingOptions>);

typedef SaveImageC = Pointer<FFIResult> Function(Int64, Pointer<FFIImageData>, Pointer<Utf8>, Pointer<Utf8>, Uint32);
typedef SaveImageDart = Pointer<FFIResult> Function(int, Pointer<FFIImageData>, Pointer<Utf8>, Pointer<Utf8>, int);

typedef IsLoadedC = Bool Function(Int64);
typedef IsLoadedDart = bool Function(int);

typedef ClearProcessorC = Void Function(Int64);
typedef ClearProcessorDart = void Function(int);

typedef FreeResultC = Void Function(Pointer<FFIResult>);
typedef FreeResultDart = void Function(Pointer<FFIResult>);

typedef FreeImageDataC = Void Function(Pointer<FFIImageData>);
typedef FreeImageDataDart = void Function(Pointer<FFIImageData>);

// C構造体の定義
class FFIResult extends Struct {
  @Int32()
  external int code;
  
  external Pointer<Utf8> data;
  
  @Int32()
  external int dataLength;
}

class FFIImageData extends Struct {
  external Pointer<Uint8> data;
  
  @Uint32()
  external int width;
  
  @Uint32()
  external int height;
  
  @Uint32()
  external int channels;
  
  @Uint32()
  external int dataLength;
}

class FFIAdjustmentParams extends Struct {
  // 基本調整
  @Float()
  external double exposure;
  @Float()
  external double highlights;
  @Float()
  external double shadows;
  @Float()
  external double whites;
  @Float()
  external double blacks;
  @Float()
  external double contrast;
  @Float()
  external double brightness;
  @Float()
  external double clarity;
  @Float()
  external double vibrance;
  @Float()
  external double saturation;
  
  // 色温度・色調
  @Float()
  external double temperature;
  @Float()
  external double tint;
  
  // HSL調整
  @Float()
  external double hueRed;
  @Float()
  external double hueOrange;
  @Float()
  external double hueYellow;
  @Float()
  external double hueGreen;
  @Float()
  external double hueAqua;
  @Float()
  external double hueBlue;
  @Float()
  external double huePurple;
  @Float()
  external double hueMagenta;
  
  @Float()
  external double saturationRed;
  @Float()
  external double saturationOrange;
  @Float()
  external double saturationYellow;
  @Float()
  external double saturationGreen;
  @Float()
  external double saturationAqua;
  @Float()
  external double saturationBlue;
  @Float()
  external double saturationPurple;
  @Float()
  external double saturationMagenta;
  
  @Float()
  external double luminanceRed;
  @Float()
  external double luminanceOrange;
  @Float()
  external double luminanceYellow;
  @Float()
  external double luminanceGreen;
  @Float()
  external double luminanceAqua;
  @Float()
  external double luminanceBlue;
  @Float()
  external double luminancePurple;
  @Float()
  external double luminanceMagenta;
  
  // トーンカーブ
  @Float()
  external double curveHighlights;
  @Float()
  external double curveLights;
  @Float()
  external double curveDarks;
  @Float()
  external double curveShadows;
  
  // ディテール
  @Float()
  external double sharpening;
  @Float()
  external double noiseReduction;
  @Float()
  external double colorNoiseReduction;
  
  // レンズ補正
  @Float()
  external double lensDistortion;
  @Float()
  external double chromaticAberration;
  @Float()
  external double vignetting;
  
  // 変形
  @Float()
  external double rotation;
  @Float()
  external double cropLeft;
  @Float()
  external double cropTop;
  @Float()
  external double cropRight;
  @Float()
  external double cropBottom;
}

class FFIProcessingOptions extends Struct {
  @Uint32()
  external int outputWidth;
  
  @Uint32()
  external int outputHeight;
  
  @Uint32()
  external int quality;
  
  @Bool()
  external bool previewMode;
  
  @Bool()
  external bool useGpu;
  
  @Uint32()
  external int threadCount;
}

class RawProcessingService {
  static RawProcessingService? _instance;
  static RawProcessingService get instance => _instance ??= RawProcessingService._();
  
  RawProcessingService._();
  
  late DynamicLibrary _library;
  late CreateProcessorDart _createProcessor;
  late DestroyProcessorDart _destroyProcessor;
  late LoadFileDart _loadFile;
  late ExtractMetadataDart _extractMetadata;
  late GenerateThumbnailDart _generateThumbnail;
  late GeneratePreviewDart _generatePreview;
  late ProcessFullImageDart _processFullImage;
  late SaveImageDart _saveImage;
  late IsLoadedDart _isLoaded;
  late ClearProcessorDart _clearProcessor;
  late FreeResultDart _freeResult;
  late FreeImageDataDart _freeImageData;
  
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // プラットフォーム別ライブラリ読み込み
      if (Platform.isAndroid) {
        _library = DynamicLibrary.open('libraw_photo_editor_native.so');
      } else if (Platform.isIOS) {
        _library = DynamicLibrary.process();
      } else {
        throw UnsupportedError('Platform not supported');
      }
      
      // 関数を取得
      _createProcessor = _library.lookup<NativeFunction<CreateProcessorC>>('raw_processor_create').asFunction();
      _destroyProcessor = _library.lookup<NativeFunction<DestroyProcessorC>>('raw_processor_destroy').asFunction();
      _loadFile = _library.lookup<NativeFunction<LoadFileC>>('raw_processor_load_file').asFunction();
      _extractMetadata = _library.lookup<NativeFunction<ExtractMetadataC>>('raw_processor_extract_metadata').asFunction();
      _generateThumbnail = _library.lookup<NativeFunction<GenerateThumbnailC>>('raw_processor_generate_thumbnail').asFunction();
      _generatePreview = _library.lookup<NativeFunction<GeneratePreviewC>>('raw_processor_generate_preview').asFunction();
      _processFullImage = _library.lookup<NativeFunction<ProcessFullImageC>>('raw_processor_process_full_image').asFunction();
      _saveImage = _library.lookup<NativeFunction<SaveImageC>>('raw_processor_save_image').asFunction();
      _isLoaded = _library.lookup<NativeFunction<IsLoadedC>>('raw_processor_is_loaded').asFunction();
      _clearProcessor = _library.lookup<NativeFunction<ClearProcessorC>>('raw_processor_clear').asFunction();
      _freeResult = _library.lookup<NativeFunction<FreeResultC>>('ffi_free_result').asFunction();
      _freeImageData = _library.lookup<NativeFunction<FreeImageDataC>>('ffi_free_image_data').asFunction();
      
      _initialized = true;
      debugPrint('RawProcessingService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize RawProcessingService: $e');
      rethrow;
    }
  }
  
  /// RAWプロセッサーを作成
  int createProcessor() {
    _checkInitialized();
    return _createProcessor();
  }
  
  /// RAWプロセッサーを破棄
  void destroyProcessor(int handle) {
    _checkInitialized();
    _destroyProcessor(handle);
  }
  
  /// RAWファイルを読み込み
  Future<bool> loadRawFile(int handle, String filePath) async {
    _checkInitialized();
    
    final pathPointer = filePath.toNativeUtf8();
    try {
      final resultPointer = _loadFile(handle, pathPointer);
      final result = resultPointer.ref;
      
      final success = result.code == 0; // SUCCESS
      _freeResult(resultPointer);
      
      return success;
    } finally {
      malloc.free(pathPointer);
    }
  }
  
  /// メタデータを抽出
  Future<Map<String, dynamic>?> extractMetadata(int handle) async {
    _checkInitialized();
    
    final resultPointer = _extractMetadata(handle);
    final result = resultPointer.ref;
    
    if (result.code == 0 && result.data != nullptr) {
      final jsonString = result.data.toDartString();
      _freeResult(resultPointer);
      
      try {
        return json.decode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('Failed to parse metadata JSON: $e');
        return null;
      }
    } else {
      _freeResult(resultPointer);
      return null;
    }
  }
  
  /// サムネイル画像を生成
  Future<Uint8List?> generateThumbnail(int handle, {int maxSize = 512}) async {
    _checkInitialized();
    
    final imageDataPointer = _generateThumbnail(handle, maxSize);
    final imageData = imageDataPointer.ref;
    
    if (imageData.data != nullptr && imageData.dataLength > 0) {
      final data = Uint8List.fromList(
        imageData.data.asTypedList(imageData.dataLength)
      );
      _freeImageData(imageDataPointer);
      return data;
    } else {
      _freeImageData(imageDataPointer);
      return null;
    }
  }
  
  /// プレビュー画像を生成
  Future<Uint8List?> generatePreview(
    int handle,
    AdjustmentParameters adjustments, {
    int? outputWidth,
    int? outputHeight,
    int quality = 85,
    bool previewMode = true,
  }) async {
    _checkInitialized();
    
    // 調整パラメータを変換
    final paramsPointer = _convertAdjustmentParams(adjustments);
    
    // 処理オプションを設定
    final optionsPointer = malloc<FFIProcessingOptions>();
    optionsPointer.ref
      ..outputWidth = outputWidth ?? 1920
      ..outputHeight = outputHeight ?? 1080
      ..quality = quality
      ..previewMode = previewMode
      ..useGpu = true
      ..threadCount = 0;
    
    try {
      final imageDataPointer = _generatePreview(handle, paramsPointer, optionsPointer);
      final imageData = imageDataPointer.ref;
      
      if (imageData.data != nullptr && imageData.dataLength > 0) {
        final data = Uint8List.fromList(
          imageData.data.asTypedList(imageData.dataLength)
        );
        _freeImageData(imageDataPointer);
        return data;
      } else {
        _freeImageData(imageDataPointer);
        return null;
      }
    } finally {
      malloc.free(paramsPointer);
      malloc.free(optionsPointer);
    }
  }
  
  /// フル解像度画像を処理
  Future<Uint8List?> processFullImage(
    int handle,
    AdjustmentParameters adjustments, {
    int? outputWidth,
    int? outputHeight,
    int quality = 95,
  }) async {
    _checkInitialized();
    
    final paramsPointer = _convertAdjustmentParams(adjustments);
    
    final optionsPointer = malloc<FFIProcessingOptions>();
    optionsPointer.ref
      ..outputWidth = outputWidth ?? 0
      ..outputHeight = outputHeight ?? 0
      ..quality = quality
      ..previewMode = false
      ..useGpu = true
      ..threadCount = 0;
    
    try {
      final imageDataPointer = _processFullImage(handle, paramsPointer, optionsPointer);
      final imageData = imageDataPointer.ref;
      
      if (imageData.data != nullptr && imageData.dataLength > 0) {
        final data = Uint8List.fromList(
          imageData.data.asTypedList(imageData.dataLength)
        );
        _freeImageData(imageDataPointer);
        return data;
      } else {
        _freeImageData(imageDataPointer);
        return null;
      }
    } finally {
      malloc.free(paramsPointer);
      malloc.free(optionsPointer);
    }
  }
  
  /// 画像をファイルに保存
  Future<bool> saveImage(
    int handle,
    Uint8List imageData,
    int width,
    int height,
    int channels,
    String outputPath, {
    String format = 'JPEG',
    int quality = 95,
  }) async {
    _checkInitialized();
    
    // 画像データを準備
    final dataPointer = malloc<Uint8>(imageData.length);
    dataPointer.asTypedList(imageData.length).setAll(0, imageData);
    
    final imageDataPointer = malloc<FFIImageData>();
    imageDataPointer.ref
      ..data = dataPointer
      ..width = width
      ..height = height
      ..channels = channels
      ..dataLength = imageData.length;
    
    final pathPointer = outputPath.toNativeUtf8();
    final formatPointer = format.toNativeUtf8();
    
    try {
      final resultPointer = _saveImage(handle, imageDataPointer, pathPointer, formatPointer, quality);
      final result = resultPointer.ref;
      
      final success = result.code == 0;
      _freeResult(resultPointer);
      
      return success;
    } finally {
      malloc.free(dataPointer);
      malloc.free(imageDataPointer);
      malloc.free(pathPointer);
      malloc.free(formatPointer);
    }
  }
  
  /// プロセッサーが読み込み済みかチェック
  bool isLoaded(int handle) {
    _checkInitialized();
    return _isLoaded(handle);
  }
  
  /// プロセッサーをクリア
  void clearProcessor(int handle) {
    _checkInitialized();
    _clearProcessor(handle);
  }
  
  /// 調整パラメータをFFI構造体に変換
  Pointer<FFIAdjustmentParams> _convertAdjustmentParams(AdjustmentParameters params) {
    final paramsPointer = malloc<FFIAdjustmentParams>();
    final ffiParams = paramsPointer.ref;
    
    // 基本調整
    ffiParams.exposure = params.exposure;
    ffiParams.highlights = params.highlights;
    ffiParams.shadows = params.shadows;
    ffiParams.whites = params.whites;
    ffiParams.blacks = params.blacks;
    ffiParams.contrast = params.contrast;
    ffiParams.brightness = params.brightness;
    ffiParams.clarity = params.clarity;
    ffiParams.vibrance = params.vibrance;
    ffiParams.saturation = params.saturation;
    
    // 色温度・色調
    ffiParams.temperature = params.temperature;
    ffiParams.tint = params.tint;
    
    // HSL調整
    ffiParams.hueRed = params.hueRed;
    ffiParams.hueOrange = params.hueOrange;
    ffiParams.hueYellow = params.hueYellow;
    ffiParams.hueGreen = params.hueGreen;
    ffiParams.hueAqua = params.hueAqua;
    ffiParams.hueBlue = params.hueBlue;
    ffiParams.huePurple = params.huePurple;
    ffiParams.hueMagenta = params.hueMagenta;
    
    ffiParams.saturationRed = params.saturationRed;
    ffiParams.saturationOrange = params.saturationOrange;
    ffiParams.saturationYellow = params.saturationYellow;
    ffiParams.saturationGreen = params.saturationGreen;
    ffiParams.saturationAqua = params.saturationAqua;
    ffiParams.saturationBlue = params.saturationBlue;
    ffiParams.saturationPurple = params.saturationPurple;
    ffiParams.saturationMagenta = params.saturationMagenta;
    
    ffiParams.luminanceRed = params.luminanceRed;
    ffiParams.luminanceOrange = params.luminanceOrange;
    ffiParams.luminanceYellow = params.luminanceYellow;
    ffiParams.luminanceGreen = params.luminanceGreen;
    ffiParams.luminanceAqua = params.luminanceAqua;
    ffiParams.luminanceBlue = params.luminanceBlue;
    ffiParams.luminancePurple = params.luminancePurple;
    ffiParams.luminanceMagenta = params.luminanceMagenta;
    
    // トーンカーブ
    ffiParams.curveHighlights = params.curveHighlights;
    ffiParams.curveLights = params.curveLights;
    ffiParams.curveDarks = params.curveDarks;
    ffiParams.curveShadows = params.curveShadows;
    
    // ディテール
    ffiParams.sharpening = params.sharpening;
    ffiParams.noiseReduction = params.noiseReduction;
    ffiParams.colorNoiseReduction = params.colorNoiseReduction;
    
    // レンズ補正
    ffiParams.lensDistortion = params.lensDistortion;
    ffiParams.chromaticAberration = params.chromaticAberration;
    ffiParams.vignetting = params.vignetting;
    
    // 変形
    ffiParams.rotation = params.rotation;
    ffiParams.cropLeft = params.cropLeft;
    ffiParams.cropTop = params.cropTop;
    ffiParams.cropRight = params.cropRight;
    ffiParams.cropBottom = params.cropBottom;
    
    return paramsPointer;
  }
  
  void _checkInitialized() {
    if (!_initialized) {
      throw StateError('RawProcessingService not initialized. Call initialize() first.');
    }
  }
}