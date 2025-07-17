import 'package:uuid/uuid.dart';
import 'adjustment_parameters.dart';

class Preset {
  String? id;
  String name;
  String? description;
  String? category;
  bool isUserPreset;
  DateTime createdAt;
  DateTime updatedAt;
  AdjustmentParameters adjustments;

  Preset({
    this.id,
    required this.name,
    this.description,
    this.category,
    this.isUserPreset = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    AdjustmentParameters? adjustments,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now(),
    adjustments = adjustments ?? AdjustmentParameters();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'is_user_preset': isUserPreset ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    
    // adjustmentsの値を追加（session_idとcreated_atを除く）
    final adjustmentMap = adjustments.toMap();
    adjustmentMap.remove('id');
    adjustmentMap.remove('session_id');
    adjustmentMap.remove('created_at');
    adjustmentMap.remove('adjustment_name');
    
    map.addAll(adjustmentMap);
    return map;
  }

  factory Preset.fromMap(Map<String, dynamic> map) {
    return Preset(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      category: map['category'],
      isUserPreset: map['is_user_preset'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      adjustments: AdjustmentParameters.fromMap(map),
    );
  }

  Preset copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    bool? isUserPreset,
    DateTime? createdAt,
    DateTime? updatedAt,
    AdjustmentParameters? adjustments,
  }) {
    return Preset(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      isUserPreset: isUserPreset ?? this.isUserPreset,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adjustments: adjustments ?? this.adjustments,
    );
  }

  // プリセットカテゴリの定数
  static const String categoryPortrait = 'ポートレート';
  static const String categoryLandscape = '風景';
  static const String categoryStreet = 'ストリート';
  static const String categoryBnw = 'モノクローム';
  static const String categoryVintage = 'ビンテージ';
  static const String categoryDramatic = 'ドラマチック';
  static const String categoryNatural = 'ナチュラル';
  static const String categoryUser = 'ユーザー作成';

  static List<String> get allCategories => [
    categoryPortrait,
    categoryLandscape,
    categoryStreet,
    categoryBnw,
    categoryVintage,
    categoryDramatic,
    categoryNatural,
    categoryUser,
  ];

  // よく使われるプリセットのファクトリーメソッド
  static Preset createPortraitPreset() {
    return Preset(
      name: 'ポートレート',
      description: '肌を滑らかに、目を鮮やかに',
      category: categoryPortrait,
      isUserPreset: false,
      adjustments: AdjustmentParameters(
        exposure: 0.3,
        shadows: 20.0,
        clarity: -10.0,
        vibrance: 15.0,
        saturation: 5.0,
        temperature: 200.0,
        luminanceRed: 10.0,
        luminanceOrange: 15.0,
      ),
    );
  }

  static Preset createLandscapePreset() {
    return Preset(
      name: '風景',
      description: '自然の色彩を豊かに表現',
      category: categoryLandscape,
      isUserPreset: false,
      adjustments: AdjustmentParameters(
        exposure: 0.2,
        highlights: -30.0,
        shadows: 30.0,
        clarity: 25.0,
        vibrance: 20.0,
        saturation: 10.0,
        saturationGreen: 15.0,
        saturationBlue: 10.0,
      ),
    );
  }

  static Preset createBnwPreset() {
    return Preset(
      name: 'モノクローム',
      description: 'クラシックな白黒写真',
      category: categoryBnw,
      isUserPreset: false,
      adjustments: AdjustmentParameters(
        exposure: 0.1,
        highlights: -20.0,
        shadows: 15.0,
        contrast: 20.0,
        clarity: 15.0,
        saturation: -100.0,
        luminanceRed: 20.0,
        luminanceOrange: 10.0,
        luminanceYellow: 15.0,
      ),
    );
  }

  static Preset createVintagePreset() {
    return Preset(
      name: 'ビンテージ',
      description: 'レトロで温かみのある色調',
      category: categoryVintage,
      isUserPreset: false,
      adjustments: AdjustmentParameters(
        exposure: -0.2,
        highlights: -40.0,
        shadows: 20.0,
        contrast: -10.0,
        saturation: -20.0,
        temperature: 500.0,
        tint: 10.0,
        hueYellow: 15.0,
        hueOrange: 10.0,
        vignetting: -30.0,
      ),
    );
  }

  static Preset createDramaticPreset() {
    return Preset(
      name: 'ドラマチック',
      description: '迫力のあるコントラスト',
      category: categoryDramatic,
      isUserPreset: false,
      adjustments: AdjustmentParameters(
        exposure: 0.1,
        highlights: -60.0,
        shadows: 40.0,
        whites: 20.0,
        blacks: -30.0,
        contrast: 40.0,
        clarity: 30.0,
        vibrance: 25.0,
      ),
    );
  }

  // デフォルトプリセット一覧を取得
  static List<Preset> getDefaultPresets() {
    return [
      createPortraitPreset(),
      createLandscapePreset(),
      createBnwPreset(),
      createVintagePreset(),
      createDramaticPreset(),
    ];
  }
}