#ifndef COMMON_TYPES_H
#define COMMON_TYPES_H

#include <memory>
#include <string>
#include <vector>
#include <cstdint>

namespace raw_editor {

// 基本型定義
using byte = uint8_t;
using u16 = uint16_t;
using u32 = uint32_t;
using u64 = uint64_t;
using f32 = float;
using f64 = double;

// 画像データ構造体
struct ImageData {
    std::vector<byte> data;
    u32 width;
    u32 height;
    u32 channels;
    u32 bit_depth;
    
    ImageData() : width(0), height(0), channels(0), bit_depth(0) {}
    
    ImageData(u32 w, u32 h, u32 c, u32 depth) 
        : width(w), height(h), channels(c), bit_depth(depth) {
        data.resize(w * h * c * (depth / 8));
    }
    
    size_t size() const {
        return data.size();
    }
    
    bool is_valid() const {
        return width > 0 && height > 0 && channels > 0 && bit_depth > 0;
    }
};

// RAWメタデータ構造体
struct RawMetadata {
    std::string camera_make;
    std::string camera_model;
    std::string lens_model;
    u32 iso;
    f32 aperture;
    std::string shutter_speed;
    f32 focal_length;
    bool flash_used;
    u32 orientation;
    std::string white_balance;
    std::string color_space;
    u32 image_width;
    u32 image_height;
    f32 color_temperature;
    
    RawMetadata() 
        : iso(0), aperture(0.0f), focal_length(0.0f), flash_used(false),
          orientation(1), image_width(0), image_height(0), color_temperature(0.0f) {}
};

// 調整パラメータ構造体
struct AdjustmentParams {
    // 基本調整
    f32 exposure = 0.0f;
    f32 highlights = 0.0f;
    f32 shadows = 0.0f;
    f32 whites = 0.0f;
    f32 blacks = 0.0f;
    f32 contrast = 0.0f;
    f32 brightness = 0.0f;
    f32 clarity = 0.0f;
    f32 vibrance = 0.0f;
    f32 saturation = 0.0f;
    
    // 色温度・色調
    f32 temperature = 0.0f;
    f32 tint = 0.0f;
    
    // HSL調整
    f32 hue_red = 0.0f;
    f32 hue_orange = 0.0f;
    f32 hue_yellow = 0.0f;
    f32 hue_green = 0.0f;
    f32 hue_aqua = 0.0f;
    f32 hue_blue = 0.0f;
    f32 hue_purple = 0.0f;
    f32 hue_magenta = 0.0f;
    
    f32 saturation_red = 0.0f;
    f32 saturation_orange = 0.0f;
    f32 saturation_yellow = 0.0f;
    f32 saturation_green = 0.0f;
    f32 saturation_aqua = 0.0f;
    f32 saturation_blue = 0.0f;
    f32 saturation_purple = 0.0f;
    f32 saturation_magenta = 0.0f;
    
    f32 luminance_red = 0.0f;
    f32 luminance_orange = 0.0f;
    f32 luminance_yellow = 0.0f;
    f32 luminance_green = 0.0f;
    f32 luminance_aqua = 0.0f;
    f32 luminance_blue = 0.0f;
    f32 luminance_purple = 0.0f;
    f32 luminance_magenta = 0.0f;
    
    // トーンカーブ
    f32 curve_highlights = 0.0f;
    f32 curve_lights = 0.0f;
    f32 curve_darks = 0.0f;
    f32 curve_shadows = 0.0f;
    
    // ディテール
    f32 sharpening = 0.0f;
    f32 noise_reduction = 0.0f;
    f32 color_noise_reduction = 0.0f;
    
    // レンズ補正
    f32 lens_distortion = 0.0f;
    f32 chromatic_aberration = 0.0f;
    f32 vignetting = 0.0f;
    
    // 変形
    f32 rotation = 0.0f;
    f32 crop_left = 0.0f;
    f32 crop_top = 0.0f;
    f32 crop_right = 1.0f;
    f32 crop_bottom = 1.0f;
};

// 処理オプション構造体
struct ProcessingOptions {
    u32 output_width = 0;      // 0 = 元のサイズ
    u32 output_height = 0;     // 0 = 元のサイズ
    u32 quality = 95;          // JPEG品質 (1-100)
    bool preview_mode = false; // プレビューモード
    bool use_gpu = true;       // GPU加速使用
    u32 thread_count = 0;      // 0 = 自動
    
    ProcessingOptions() = default;
    
    ProcessingOptions(bool preview) : preview_mode(preview) {
        if (preview) {
            output_width = 1920;   // プレビュー時は最大1920x1080
            output_height = 1080;
            quality = 85;
        }
    }
};

// 結果コード
enum class ResultCode {
    SUCCESS = 0,
    ERROR_FILE_NOT_FOUND = -1,
    ERROR_INVALID_FORMAT = -2,
    ERROR_MEMORY_ALLOCATION = -3,
    ERROR_PROCESSING_FAILED = -4,
    ERROR_INVALID_PARAMETERS = -5,
    ERROR_LIBRAW_ERROR = -6,
    ERROR_OPENCV_ERROR = -7,
    ERROR_UNKNOWN = -999
};

// 処理結果構造体
template<typename T>
struct ProcessingResult {
    ResultCode code;
    T data;
    std::string error_message;
    
    ProcessingResult() : code(ResultCode::ERROR_UNKNOWN) {}
    
    ProcessingResult(ResultCode c, const T& d) : code(c), data(d) {}
    
    ProcessingResult(ResultCode c, const std::string& msg) 
        : code(c), error_message(msg) {}
    
    bool is_success() const {
        return code == ResultCode::SUCCESS;
    }
    
    bool is_error() const {
        return code != ResultCode::SUCCESS;
    }
};

// エイリアス
using ImageResult = ProcessingResult<ImageData>;
using MetadataResult = ProcessingResult<RawMetadata>;
using BoolResult = ProcessingResult<bool>;
using StringResult = ProcessingResult<std::string>;

// ユーティリティマクロ
#define RETURN_ON_ERROR(result) \
    if ((result).is_error()) { \
        return result; \
    }

#define LOG_ERROR(tag, msg) \
    __android_log_print(ANDROID_LOG_ERROR, tag, "%s", msg)

#define LOG_INFO(tag, msg) \
    __android_log_print(ANDROID_LOG_INFO, tag, "%s", msg)

#define LOG_DEBUG(tag, msg) \
    __android_log_print(ANDROID_LOG_DEBUG, tag, "%s", msg)

} // namespace raw_editor

#endif // COMMON_TYPES_H