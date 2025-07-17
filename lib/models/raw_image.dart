import 'package:uuid/uuid.dart';

class RawImage {
  String? id;
  String filePath;
  String fileName;
  int fileSize;
  DateTime dateCreated;
  DateTime dateModified;
  String? cameraMake;
  String? cameraModel;
  String? lensModel;
  int? iso;
  double? aperture;
  String? shutterSpeed;
  double? focalLength;
  bool flashUsed;
  int orientation;
  String? whiteBalance;
  String? colorSpace;
  int? imageWidth;
  int? imageHeight;
  int rating;
  List<String> colorLabels;
  List<String> keywords;
  String? thumbnailPath;
  DateTime createdAt;
  DateTime updatedAt;

  RawImage({
    this.id,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.dateCreated,
    required this.dateModified,
    this.cameraMake,
    this.cameraModel,
    this.lensModel,
    this.iso,
    this.aperture,
    this.shutterSpeed,
    this.focalLength,
    this.flashUsed = false,
    this.orientation = 1,
    this.whiteBalance,
    this.colorSpace,
    this.imageWidth,
    this.imageHeight,
    this.rating = 0,
    this.colorLabels = const [],
    this.keywords = const [],
    this.thumbnailPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_path': filePath,
      'file_name': fileName,
      'file_size': fileSize,
      'date_created': dateCreated.toIso8601String(),
      'date_modified': dateModified.toIso8601String(),
      'camera_make': cameraMake,
      'camera_model': cameraModel,
      'lens_model': lensModel,
      'iso': iso,
      'aperture': aperture,
      'shutter_speed': shutterSpeed,
      'focal_length': focalLength,
      'flash_used': flashUsed ? 1 : 0,
      'orientation': orientation,
      'white_balance': whiteBalance,
      'color_space': colorSpace,
      'image_width': imageWidth,
      'image_height': imageHeight,
      'rating': rating,
      'color_labels': colorLabels.join(','),
      'keywords': keywords.join(','),
      'thumbnail_path': thumbnailPath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory RawImage.fromMap(Map<String, dynamic> map) {
    return RawImage(
      id: map['id'],
      filePath: map['file_path'],
      fileName: map['file_name'],
      fileSize: map['file_size'],
      dateCreated: DateTime.parse(map['date_created']),
      dateModified: DateTime.parse(map['date_modified']),
      cameraMake: map['camera_make'],
      cameraModel: map['camera_model'] ?? '',
      lensModel: map['lens_model'] ?? '',
      iso: map['iso'],
      aperture: map['aperture'],
      shutterSpeed: map['shutter_speed'],
      focalLength: map['focal_length'],
      flashUsed: map['flash_used'] == 1,
      orientation: map['orientation'] ?? 1,
      whiteBalance: map['white_balance'],
      colorSpace: map['color_space'],
      imageWidth: map['image_width'],
      imageHeight: map['image_height'],
      rating: map['rating'] ?? 0,
      colorLabels: map['color_labels'] != null 
          ? (map['color_labels'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      keywords: map['keywords'] != null 
          ? (map['keywords'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      thumbnailPath: map['thumbnail_path'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  RawImage copyWith({
    String? id,
    String? filePath,
    String? fileName,
    int? fileSize,
    DateTime? dateCreated,
    DateTime? dateModified,
    String? cameraMake,
    String? cameraModel,
    String? lensModel,
    int? iso,
    double? aperture,
    String? shutterSpeed,
    double? focalLength,
    bool? flashUsed,
    int? orientation,
    String? whiteBalance,
    String? colorSpace,
    int? imageWidth,
    int? imageHeight,
    int? rating,
    List<String>? colorLabels,
    List<String>? keywords,
    String? thumbnailPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RawImage(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      cameraMake: cameraMake ?? this.cameraMake,
      cameraModel: cameraModel ?? this.cameraModel,
      lensModel: lensModel ?? this.lensModel,
      iso: iso ?? this.iso,
      aperture: aperture ?? this.aperture,
      shutterSpeed: shutterSpeed ?? this.shutterSpeed,
      focalLength: focalLength ?? this.focalLength,
      flashUsed: flashUsed ?? this.flashUsed,
      orientation: orientation ?? this.orientation,
      whiteBalance: whiteBalance ?? this.whiteBalance,
      colorSpace: colorSpace ?? this.colorSpace,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      rating: rating ?? this.rating,
      colorLabels: colorLabels ?? this.colorLabels,
      keywords: keywords ?? this.keywords,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get formattedAperture {
    return aperture != null ? 'f/${aperture!.toStringAsFixed(1)}' : '';
  }

  String get formattedFocalLength {
    return focalLength != null ? '${focalLength!.toStringAsFixed(0)}mm' : '';
  }

  String get formattedDimensions {
    if (imageWidth != null && imageHeight != null) {
      return '${imageWidth}x$imageHeight';
    }
    return '';
  }
}