import 'package:uuid/uuid.dart';

class AdjustmentParameters {
  String? id;
  String? sessionId;
  String adjustmentName;
  DateTime? createdAt;

  // 基本調整
  double exposure;
  double highlights;
  double shadows;
  double whites;
  double blacks;
  double contrast;
  double brightness;
  double clarity;
  double vibrance;
  double saturation;

  // 色温度・色調
  double temperature;
  double tint;

  // HSL調整 - 色相
  double hueRed;
  double hueOrange;
  double hueYellow;
  double hueGreen;
  double hueAqua;
  double hueBlue;
  double huePurple;
  double hueMagenta;

  // HSL調整 - 彩度
  double saturationRed;
  double saturationOrange;
  double saturationYellow;
  double saturationGreen;
  double saturationAqua;
  double saturationBlue;
  double saturationPurple;
  double saturationMagenta;

  // HSL調整 - 輝度
  double luminanceRed;
  double luminanceOrange;
  double luminanceYellow;
  double luminanceGreen;
  double luminanceAqua;
  double luminanceBlue;
  double luminancePurple;
  double luminanceMagenta;

  // トーンカーブ
  double curveHighlights;
  double curveLights;
  double curveDarks;
  double curveShadows;

  // ディテール
  double sharpening;
  double noiseReduction;
  double colorNoiseReduction;

  // レンズ補正
  double lensDistortion;
  double chromaticAberration;
  double vignetting;

  // 変形
  double rotation;
  double cropLeft;
  double cropTop;
  double cropRight;
  double cropBottom;

  AdjustmentParameters({
    this.id,
    this.sessionId,
    this.adjustmentName = 'Adjustment',
    this.createdAt,
    
    // 基本調整のデフォルト値
    this.exposure = 0.0,
    this.highlights = 0.0,
    this.shadows = 0.0,
    this.whites = 0.0,
    this.blacks = 0.0,
    this.contrast = 0.0,
    this.brightness = 0.0,
    this.clarity = 0.0,
    this.vibrance = 0.0,
    this.saturation = 0.0,
    
    // 色温度・色調のデフォルト値
    this.temperature = 0.0,
    this.tint = 0.0,
    
    // HSL調整のデフォルト値
    this.hueRed = 0.0,
    this.hueOrange = 0.0,
    this.hueYellow = 0.0,
    this.hueGreen = 0.0,
    this.hueAqua = 0.0,
    this.hueBlue = 0.0,
    this.huePurple = 0.0,
    this.hueMagenta = 0.0,
    
    this.saturationRed = 0.0,
    this.saturationOrange = 0.0,
    this.saturationYellow = 0.0,
    this.saturationGreen = 0.0,
    this.saturationAqua = 0.0,
    this.saturationBlue = 0.0,
    this.saturationPurple = 0.0,
    this.saturationMagenta = 0.0,
    
    this.luminanceRed = 0.0,
    this.luminanceOrange = 0.0,
    this.luminanceYellow = 0.0,
    this.luminanceGreen = 0.0,
    this.luminanceAqua = 0.0,
    this.luminanceBlue = 0.0,
    this.luminancePurple = 0.0,
    this.luminanceMagenta = 0.0,
    
    // トーンカーブのデフォルト値
    this.curveHighlights = 0.0,
    this.curveLights = 0.0,
    this.curveDarks = 0.0,
    this.curveShadows = 0.0,
    
    // ディテールのデフォルト値
    this.sharpening = 0.0,
    this.noiseReduction = 0.0,
    this.colorNoiseReduction = 0.0,
    
    // レンズ補正のデフォルト値
    this.lensDistortion = 0.0,
    this.chromaticAberration = 0.0,
    this.vignetting = 0.0,
    
    // 変形のデフォルト値
    this.rotation = 0.0,
    this.cropLeft = 0.0,
    this.cropTop = 0.0,
    this.cropRight = 1.0,
    this.cropBottom = 1.0,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'adjustment_name': adjustmentName,
      'created_at': createdAt?.toIso8601String(),
      
      // 基本調整
      'exposure': exposure,
      'highlights': highlights,
      'shadows': shadows,
      'whites': whites,
      'blacks': blacks,
      'contrast': contrast,
      'brightness': brightness,
      'clarity': clarity,
      'vibrance': vibrance,
      'saturation': saturation,
      
      // 色温度・色調
      'temperature': temperature,
      'tint': tint,
      
      // HSL調整
      'hue_red': hueRed,
      'hue_orange': hueOrange,
      'hue_yellow': hueYellow,
      'hue_green': hueGreen,
      'hue_aqua': hueAqua,
      'hue_blue': hueBlue,
      'hue_purple': huePurple,
      'hue_magenta': hueMagenta,
      
      'saturation_red': saturationRed,
      'saturation_orange': saturationOrange,
      'saturation_yellow': saturationYellow,
      'saturation_green': saturationGreen,
      'saturation_aqua': saturationAqua,
      'saturation_blue': saturationBlue,
      'saturation_purple': saturationPurple,
      'saturation_magenta': saturationMagenta,
      
      'luminance_red': luminanceRed,
      'luminance_orange': luminanceOrange,
      'luminance_yellow': luminanceYellow,
      'luminance_green': luminanceGreen,
      'luminance_aqua': luminanceAqua,
      'luminance_blue': luminanceBlue,
      'luminance_purple': luminancePurple,
      'luminance_magenta': luminanceMagenta,
      
      // トーンカーブ
      'curve_highlights': curveHighlights,
      'curve_lights': curveLights,
      'curve_darks': curveDarks,
      'curve_shadows': curveShadows,
      
      // ディテール
      'sharpening': sharpening,
      'noise_reduction': noiseReduction,
      'color_noise_reduction': colorNoiseReduction,
      
      // レンズ補正
      'lens_distortion': lensDistortion,
      'chromatic_aberration': chromaticAberration,
      'vignetting': vignetting,
      
      // 変形
      'rotation': rotation,
      'crop_left': cropLeft,
      'crop_top': cropTop,
      'crop_right': cropRight,
      'crop_bottom': cropBottom,
    };
  }

  factory AdjustmentParameters.fromMap(Map<String, dynamic> map) {
    return AdjustmentParameters(
      id: map['id'],
      sessionId: map['session_id'],
      adjustmentName: map['adjustment_name'] ?? 'Adjustment',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      
      // 基本調整
      exposure: map['exposure']?.toDouble() ?? 0.0,
      highlights: map['highlights']?.toDouble() ?? 0.0,
      shadows: map['shadows']?.toDouble() ?? 0.0,
      whites: map['whites']?.toDouble() ?? 0.0,
      blacks: map['blacks']?.toDouble() ?? 0.0,
      contrast: map['contrast']?.toDouble() ?? 0.0,
      brightness: map['brightness']?.toDouble() ?? 0.0,
      clarity: map['clarity']?.toDouble() ?? 0.0,
      vibrance: map['vibrance']?.toDouble() ?? 0.0,
      saturation: map['saturation']?.toDouble() ?? 0.0,
      
      // 色温度・色調
      temperature: map['temperature']?.toDouble() ?? 0.0,
      tint: map['tint']?.toDouble() ?? 0.0,
      
      // HSL調整
      hueRed: map['hue_red']?.toDouble() ?? 0.0,
      hueOrange: map['hue_orange']?.toDouble() ?? 0.0,
      hueYellow: map['hue_yellow']?.toDouble() ?? 0.0,
      hueGreen: map['hue_green']?.toDouble() ?? 0.0,
      hueAqua: map['hue_aqua']?.toDouble() ?? 0.0,
      hueBlue: map['hue_blue']?.toDouble() ?? 0.0,
      huePurple: map['hue_purple']?.toDouble() ?? 0.0,
      hueMagenta: map['hue_magenta']?.toDouble() ?? 0.0,
      
      saturationRed: map['saturation_red']?.toDouble() ?? 0.0,
      saturationOrange: map['saturation_orange']?.toDouble() ?? 0.0,
      saturationYellow: map['saturation_yellow']?.toDouble() ?? 0.0,
      saturationGreen: map['saturation_green']?.toDouble() ?? 0.0,
      saturationAqua: map['saturation_aqua']?.toDouble() ?? 0.0,
      saturationBlue: map['saturation_blue']?.toDouble() ?? 0.0,
      saturationPurple: map['saturation_purple']?.toDouble() ?? 0.0,
      saturationMagenta: map['saturation_magenta']?.toDouble() ?? 0.0,
      
      luminanceRed: map['luminance_red']?.toDouble() ?? 0.0,
      luminanceOrange: map['luminance_orange']?.toDouble() ?? 0.0,
      luminanceYellow: map['luminance_yellow']?.toDouble() ?? 0.0,
      luminanceGreen: map['luminance_green']?.toDouble() ?? 0.0,
      luminanceAqua: map['luminance_aqua']?.toDouble() ?? 0.0,
      luminanceBlue: map['luminance_blue']?.toDouble() ?? 0.0,
      luminancePurple: map['luminance_purple']?.toDouble() ?? 0.0,
      luminanceMagenta: map['luminance_magenta']?.toDouble() ?? 0.0,
      
      // トーンカーブ
      curveHighlights: map['curve_highlights']?.toDouble() ?? 0.0,
      curveLights: map['curve_lights']?.toDouble() ?? 0.0,
      curveDarks: map['curve_darks']?.toDouble() ?? 0.0,
      curveShadows: map['curve_shadows']?.toDouble() ?? 0.0,
      
      // ディテール
      sharpening: map['sharpening']?.toDouble() ?? 0.0,
      noiseReduction: map['noise_reduction']?.toDouble() ?? 0.0,
      colorNoiseReduction: map['color_noise_reduction']?.toDouble() ?? 0.0,
      
      // レンズ補正
      lensDistortion: map['lens_distortion']?.toDouble() ?? 0.0,
      chromaticAberration: map['chromatic_aberration']?.toDouble() ?? 0.0,
      vignetting: map['vignetting']?.toDouble() ?? 0.0,
      
      // 変形
      rotation: map['rotation']?.toDouble() ?? 0.0,
      cropLeft: map['crop_left']?.toDouble() ?? 0.0,
      cropTop: map['crop_top']?.toDouble() ?? 0.0,
      cropRight: map['crop_right']?.toDouble() ?? 1.0,
      cropBottom: map['crop_bottom']?.toDouble() ?? 1.0,
    );
  }

  AdjustmentParameters copyWith({
    String? id,
    String? sessionId,
    String? adjustmentName,
    DateTime? createdAt,
    double? exposure,
    double? highlights,
    double? shadows,
    double? whites,
    double? blacks,
    double? contrast,
    double? brightness,
    double? clarity,
    double? vibrance,
    double? saturation,
    double? temperature,
    double? tint,
    double? hueRed,
    double? hueOrange,
    double? hueYellow,
    double? hueGreen,
    double? hueAqua,
    double? hueBlue,
    double? huePurple,
    double? hueMagenta,
    double? saturationRed,
    double? saturationOrange,
    double? saturationYellow,
    double? saturationGreen,
    double? saturationAqua,
    double? saturationBlue,
    double? saturationPurple,
    double? saturationMagenta,
    double? luminanceRed,
    double? luminanceOrange,
    double? luminanceYellow,
    double? luminanceGreen,
    double? luminanceAqua,
    double? luminanceBlue,
    double? luminancePurple,
    double? luminanceMagenta,
    double? curveHighlights,
    double? curveLights,
    double? curveDarks,
    double? curveShadows,
    double? sharpening,
    double? noiseReduction,
    double? colorNoiseReduction,
    double? lensDistortion,
    double? chromaticAberration,
    double? vignetting,
    double? rotation,
    double? cropLeft,
    double? cropTop,
    double? cropRight,
    double? cropBottom,
  }) {
    return AdjustmentParameters(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      adjustmentName: adjustmentName ?? this.adjustmentName,
      createdAt: createdAt ?? this.createdAt,
      exposure: exposure ?? this.exposure,
      highlights: highlights ?? this.highlights,
      shadows: shadows ?? this.shadows,
      whites: whites ?? this.whites,
      blacks: blacks ?? this.blacks,
      contrast: contrast ?? this.contrast,
      brightness: brightness ?? this.brightness,
      clarity: clarity ?? this.clarity,
      vibrance: vibrance ?? this.vibrance,
      saturation: saturation ?? this.saturation,
      temperature: temperature ?? this.temperature,
      tint: tint ?? this.tint,
      hueRed: hueRed ?? this.hueRed,
      hueOrange: hueOrange ?? this.hueOrange,
      hueYellow: hueYellow ?? this.hueYellow,
      hueGreen: hueGreen ?? this.hueGreen,
      hueAqua: hueAqua ?? this.hueAqua,
      hueBlue: hueBlue ?? this.hueBlue,
      huePurple: huePurple ?? this.huePurple,
      hueMagenta: hueMagenta ?? this.hueMagenta,
      saturationRed: saturationRed ?? this.saturationRed,
      saturationOrange: saturationOrange ?? this.saturationOrange,
      saturationYellow: saturationYellow ?? this.saturationYellow,
      saturationGreen: saturationGreen ?? this.saturationGreen,
      saturationAqua: saturationAqua ?? this.saturationAqua,
      saturationBlue: saturationBlue ?? this.saturationBlue,
      saturationPurple: saturationPurple ?? this.saturationPurple,
      saturationMagenta: saturationMagenta ?? this.saturationMagenta,
      luminanceRed: luminanceRed ?? this.luminanceRed,
      luminanceOrange: luminanceOrange ?? this.luminanceOrange,
      luminanceYellow: luminanceYellow ?? this.luminanceYellow,
      luminanceGreen: luminanceGreen ?? this.luminanceGreen,
      luminanceAqua: luminanceAqua ?? this.luminanceAqua,
      luminanceBlue: luminanceBlue ?? this.luminanceBlue,
      luminancePurple: luminancePurple ?? this.luminancePurple,
      luminanceMagenta: luminanceMagenta ?? this.luminanceMagenta,
      curveHighlights: curveHighlights ?? this.curveHighlights,
      curveLights: curveLights ?? this.curveLights,
      curveDarks: curveDarks ?? this.curveDarks,
      curveShadows: curveShadows ?? this.curveShadows,
      sharpening: sharpening ?? this.sharpening,
      noiseReduction: noiseReduction ?? this.noiseReduction,
      colorNoiseReduction: colorNoiseReduction ?? this.colorNoiseReduction,
      lensDistortion: lensDistortion ?? this.lensDistortion,
      chromaticAberration: chromaticAberration ?? this.chromaticAberration,
      vignetting: vignetting ?? this.vignetting,
      rotation: rotation ?? this.rotation,
      cropLeft: cropLeft ?? this.cropLeft,
      cropTop: cropTop ?? this.cropTop,
      cropRight: cropRight ?? this.cropRight,
      cropBottom: cropBottom ?? this.cropBottom,
    );
  }

  AdjustmentParameters copy() => copyWith();

  bool get hasBasicAdjustments {
    return exposure != 0.0 || highlights != 0.0 || shadows != 0.0 ||
           whites != 0.0 || blacks != 0.0 || contrast != 0.0 ||
           brightness != 0.0 || clarity != 0.0 || vibrance != 0.0 ||
           saturation != 0.0 || temperature != 0.0 || tint != 0.0;
  }

  bool get hasColorAdjustments {
    return hueRed != 0.0 || hueOrange != 0.0 || hueYellow != 0.0 ||
           hueGreen != 0.0 || hueAqua != 0.0 || hueBlue != 0.0 ||
           huePurple != 0.0 || hueMagenta != 0.0 ||
           saturationRed != 0.0 || saturationOrange != 0.0 ||
           saturationYellow != 0.0 || saturationGreen != 0.0 ||
           saturationAqua != 0.0 || saturationBlue != 0.0 ||
           saturationPurple != 0.0 || saturationMagenta != 0.0 ||
           luminanceRed != 0.0 || luminanceOrange != 0.0 ||
           luminanceYellow != 0.0 || luminanceGreen != 0.0 ||
           luminanceAqua != 0.0 || luminanceBlue != 0.0 ||
           luminancePurple != 0.0 || luminanceMagenta != 0.0;
  }

  bool get hasCurveAdjustments {
    return curveHighlights != 0.0 || curveLights != 0.0 ||
           curveDarks != 0.0 || curveShadows != 0.0;
  }

  bool get hasDetailAdjustments {
    return sharpening != 0.0 || noiseReduction != 0.0 ||
           colorNoiseReduction != 0.0;
  }

  bool get hasLensCorrections {
    return lensDistortion != 0.0 || chromaticAberration != 0.0 ||
           vignetting != 0.0;
  }

  bool get hasTransformAdjustments {
    return rotation != 0.0 || cropLeft != 0.0 || cropTop != 0.0 ||
           cropRight != 1.0 || cropBottom != 1.0;
  }

  bool get hasAnyAdjustments {
    return hasBasicAdjustments || hasColorAdjustments ||
           hasCurveAdjustments || hasDetailAdjustments ||
           hasLensCorrections || hasTransformAdjustments;
  }
}