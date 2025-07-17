import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/raw_image.dart';
import '../models/edit_session.dart';
import '../models/adjustment_parameters.dart';
import '../models/preset.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'raw_editor.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // RAW画像メタデータテーブル
    await db.execute('''
      CREATE TABLE raw_images (
        id TEXT PRIMARY KEY,
        file_path TEXT NOT NULL UNIQUE,
        file_name TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        date_created TEXT NOT NULL,
        date_modified TEXT NOT NULL,
        camera_make TEXT,
        camera_model TEXT,
        lens_model TEXT,
        iso INTEGER,
        aperture REAL,
        shutter_speed TEXT,
        focal_length REAL,
        flash_used INTEGER DEFAULT 0,
        orientation INTEGER DEFAULT 1,
        white_balance TEXT,
        color_space TEXT,
        image_width INTEGER,
        image_height INTEGER,
        rating INTEGER DEFAULT 0,
        color_labels TEXT,
        keywords TEXT,
        thumbnail_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 編集セッションテーブル
    await db.execute('''
      CREATE TABLE edit_sessions (
        id TEXT PRIMARY KEY,
        image_id TEXT NOT NULL,
        session_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_modified TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (image_id) REFERENCES raw_images (id) ON DELETE CASCADE
      )
    ''');

    // 調整パラメータテーブル
    await db.execute('''
      CREATE TABLE adjustments (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        adjustment_name TEXT DEFAULT 'Adjustment',
        created_at TEXT NOT NULL,
        
        -- 基本調整
        exposure REAL DEFAULT 0.0,
        highlights REAL DEFAULT 0.0,
        shadows REAL DEFAULT 0.0,
        whites REAL DEFAULT 0.0,
        blacks REAL DEFAULT 0.0,
        contrast REAL DEFAULT 0.0,
        brightness REAL DEFAULT 0.0,
        clarity REAL DEFAULT 0.0,
        vibrance REAL DEFAULT 0.0,
        saturation REAL DEFAULT 0.0,
        
        -- 色温度・色調
        temperature REAL DEFAULT 0.0,
        tint REAL DEFAULT 0.0,
        
        -- HSL調整
        hue_red REAL DEFAULT 0.0,
        hue_orange REAL DEFAULT 0.0,
        hue_yellow REAL DEFAULT 0.0,
        hue_green REAL DEFAULT 0.0,
        hue_aqua REAL DEFAULT 0.0,
        hue_blue REAL DEFAULT 0.0,
        hue_purple REAL DEFAULT 0.0,
        hue_magenta REAL DEFAULT 0.0,
        
        saturation_red REAL DEFAULT 0.0,
        saturation_orange REAL DEFAULT 0.0,
        saturation_yellow REAL DEFAULT 0.0,
        saturation_green REAL DEFAULT 0.0,
        saturation_aqua REAL DEFAULT 0.0,
        saturation_blue REAL DEFAULT 0.0,
        saturation_purple REAL DEFAULT 0.0,
        saturation_magenta REAL DEFAULT 0.0,
        
        luminance_red REAL DEFAULT 0.0,
        luminance_orange REAL DEFAULT 0.0,
        luminance_yellow REAL DEFAULT 0.0,
        luminance_green REAL DEFAULT 0.0,
        luminance_aqua REAL DEFAULT 0.0,
        luminance_blue REAL DEFAULT 0.0,
        luminance_purple REAL DEFAULT 0.0,
        luminance_magenta REAL DEFAULT 0.0,
        
        -- トーンカーブ
        curve_highlights REAL DEFAULT 0.0,
        curve_lights REAL DEFAULT 0.0,
        curve_darks REAL DEFAULT 0.0,
        curve_shadows REAL DEFAULT 0.0,
        
        -- ディテール
        sharpening REAL DEFAULT 0.0,
        noise_reduction REAL DEFAULT 0.0,
        color_noise_reduction REAL DEFAULT 0.0,
        
        -- レンズ補正
        lens_distortion REAL DEFAULT 0.0,
        chromatic_aberration REAL DEFAULT 0.0,
        vignetting REAL DEFAULT 0.0,
        
        -- 変形
        rotation REAL DEFAULT 0.0,
        crop_left REAL DEFAULT 0.0,
        crop_top REAL DEFAULT 0.0,
        crop_right REAL DEFAULT 1.0,
        crop_bottom REAL DEFAULT 1.0,
        
        FOREIGN KEY (session_id) REFERENCES edit_sessions (id) ON DELETE CASCADE
      )
    ''');

    // プリセットテーブル
    await db.execute('''
      CREATE TABLE presets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT,
        is_user_preset INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        
        -- 調整パラメータ（adjustmentsテーブルと同じ構造）
        exposure REAL DEFAULT 0.0,
        highlights REAL DEFAULT 0.0,
        shadows REAL DEFAULT 0.0,
        whites REAL DEFAULT 0.0,
        blacks REAL DEFAULT 0.0,
        contrast REAL DEFAULT 0.0,
        brightness REAL DEFAULT 0.0,
        clarity REAL DEFAULT 0.0,
        vibrance REAL DEFAULT 0.0,
        saturation REAL DEFAULT 0.0,
        temperature REAL DEFAULT 0.0,
        tint REAL DEFAULT 0.0,
        
        hue_red REAL DEFAULT 0.0,
        hue_orange REAL DEFAULT 0.0,
        hue_yellow REAL DEFAULT 0.0,
        hue_green REAL DEFAULT 0.0,
        hue_aqua REAL DEFAULT 0.0,
        hue_blue REAL DEFAULT 0.0,
        hue_purple REAL DEFAULT 0.0,
        hue_magenta REAL DEFAULT 0.0,
        
        saturation_red REAL DEFAULT 0.0,
        saturation_orange REAL DEFAULT 0.0,
        saturation_yellow REAL DEFAULT 0.0,
        saturation_green REAL DEFAULT 0.0,
        saturation_aqua REAL DEFAULT 0.0,
        saturation_blue REAL DEFAULT 0.0,
        saturation_purple REAL DEFAULT 0.0,
        saturation_magenta REAL DEFAULT 0.0,
        
        luminance_red REAL DEFAULT 0.0,
        luminance_orange REAL DEFAULT 0.0,
        luminance_yellow REAL DEFAULT 0.0,
        luminance_green REAL DEFAULT 0.0,
        luminance_aqua REAL DEFAULT 0.0,
        luminance_blue REAL DEFAULT 0.0,
        luminance_purple REAL DEFAULT 0.0,
        luminance_magenta REAL DEFAULT 0.0,
        
        curve_highlights REAL DEFAULT 0.0,
        curve_lights REAL DEFAULT 0.0,
        curve_darks REAL DEFAULT 0.0,
        curve_shadows REAL DEFAULT 0.0,
        
        sharpening REAL DEFAULT 0.0,
        noise_reduction REAL DEFAULT 0.0,
        color_noise_reduction REAL DEFAULT 0.0,
        
        lens_distortion REAL DEFAULT 0.0,
        chromatic_aberration REAL DEFAULT 0.0,
        vignetting REAL DEFAULT 0.0,
        
        rotation REAL DEFAULT 0.0,
        crop_left REAL DEFAULT 0.0,
        crop_top REAL DEFAULT 0.0,
        crop_right REAL DEFAULT 1.0,
        crop_bottom REAL DEFAULT 1.0
      )
    ''');

    // インデックス作成
    await db.execute('CREATE INDEX idx_raw_images_file_path ON raw_images (file_path)');
    await db.execute('CREATE INDEX idx_raw_images_date_modified ON raw_images (date_modified)');
    await db.execute('CREATE INDEX idx_edit_sessions_image_id ON edit_sessions (image_id)');
    await db.execute('CREATE INDEX idx_adjustments_session_id ON adjustments (session_id)');
    await db.execute('CREATE INDEX idx_adjustments_created_at ON adjustments (created_at)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 将来のマイグレーション用
  }

  Future<void> initialize() async {
    await database;
  }

  // RAW画像関連のメソッド
  Future<List<RawImage>> getAllRawImages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'raw_images',
      orderBy: 'date_modified DESC',
    );
    return List.generate(maps.length, (i) => RawImage.fromMap(maps[i]));
  }

  Future<RawImage> insertRawImage(RawImage image) async {
    final db = await database;
    await db.insert('raw_images', image.toMap());
    return image;
  }

  Future<void> updateRawImage(RawImage image) async {
    final db = await database;
    await db.update(
      'raw_images',
      image.toMap(),
      where: 'id = ?',
      whereArgs: [image.id],
    );
  }

  Future<void> deleteRawImage(String id) async {
    final db = await database;
    await db.delete('raw_images', where: 'id = ?', whereArgs: [id]);
  }

  // 編集セッション関連のメソッド
  Future<EditSession?> getEditSessionByImageId(String imageId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'edit_sessions',
      where: 'image_id = ? AND is_active = 1',
      whereArgs: [imageId],
      orderBy: 'last_modified DESC',
      limit: 1,
    );
    return maps.isNotEmpty ? EditSession.fromMap(maps.first) : null;
  }

  Future<EditSession> insertEditSession(EditSession session) async {
    final db = await database;
    await db.insert('edit_sessions', session.toMap());
    return session;
  }

  Future<void> updateEditSession(EditSession session) async {
    final db = await database;
    await db.update(
      'edit_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  // 調整パラメータ関連のメソッド
  Future<AdjustmentParameters> getLatestAdjustments(String sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'adjustments',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    return maps.isNotEmpty 
        ? AdjustmentParameters.fromMap(maps.first)
        : AdjustmentParameters();
  }

  Future<void> insertAdjustment(String sessionId, AdjustmentParameters adjustment) async {
    final db = await database;
    final map = adjustment.toMap();
    map['session_id'] = sessionId;
    map['created_at'] = DateTime.now().toIso8601String();
    await db.insert('adjustments', map);
  }

  // プリセット関連のメソッド
  Future<List<Preset>> getAllPresets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'presets',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Preset.fromMap(maps[i]));
  }

  Future<void> insertPreset(Preset preset) async {
    final db = await database;
    await db.insert('presets', preset.toMap());
  }

  Future<void> deletePreset(String id) async {
    final db = await database;
    await db.delete('presets', where: 'id = ?', whereArgs: [id]);
  }
}