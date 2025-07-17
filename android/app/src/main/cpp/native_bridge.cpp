#include "native_bridge.h"
#include <android/log.h>
#include <unordered_map>
#include <mutex>
#include <cstring>
#include <sstream>
#include <iomanip>

namespace raw_editor {

static const char* TAG = "NativeBridge";

// グローバル状態管理
static std::unordered_map<int64_t, std::unique_ptr<RawProcessor>> g_processors;
static std::mutex g_processors_mutex;
static int64_t g_next_handle = 1;

namespace bridge_internal {

RawProcessor* get_processor_from_handle(int64_t handle) {
    std::lock_guard<std::mutex> lock(g_processors_mutex);
    auto it = g_processors.find(handle);
    return (it != g_processors.end()) ? it->second.get() : nullptr;
}

template<>
FFIResult convert_result<bool>(const ProcessingResult<bool>& result) {
    FFIResult ffi_result;
    ffi_result.code = static_cast<int32_t>(result.code);
    
    if (result.is_success()) {
        std::string json = create_json_string("success", result.data ? "true" : "false");
        ffi_result.data_length = static_cast<int32_t>(json.length() + 1);
        ffi_result.data = new char[ffi_result.data_length];
        std::strcpy(ffi_result.data, json.c_str());
    } else {
        std::string error_json = create_error_json(result.error_message);
        ffi_result.data_length = static_cast<int32_t>(error_json.length() + 1);
        ffi_result.data = new char[ffi_result.data_length];
        std::strcpy(ffi_result.data, error_json.c_str());
    }
    
    return ffi_result;
}

template<>
FFIResult convert_result<std::string>(const ProcessingResult<std::string>& result) {
    FFIResult ffi_result;
    ffi_result.code = static_cast<int32_t>(result.code);
    
    if (result.is_success()) {
        ffi_result.data_length = static_cast<int32_t>(result.data.length() + 1);
        ffi_result.data = new char[ffi_result.data_length];
        std::strcpy(ffi_result.data, result.data.c_str());
    } else {
        std::string error_json = create_error_json(result.error_message);
        ffi_result.data_length = static_cast<int32_t>(error_json.length() + 1);
        ffi_result.data = new char[ffi_result.data_length];
        std::strcpy(ffi_result.data, error_json.c_str());
    }
    
    return ffi_result;
}

template<>
FFIResult convert_result<RawMetadata>(const ProcessingResult<RawMetadata>& result) {
    FFIResult ffi_result;
    ffi_result.code = static_cast<int32_t>(result.code);
    
    if (result.is_success()) {
        // メタデータをJSON形式に変換
        std::ostringstream json;
        json << "{"
             << "\"camera_make\":\"" << result.data.camera_make << "\","
             << "\"camera_model\":\"" << result.data.camera_model << "\","
             << "\"lens_model\":\"" << result.data.lens_model << "\","
             << "\"iso\":" << result.data.iso << ","
             << "\"aperture\":" << std::fixed << std::setprecision(1) << result.data.aperture << ","
             << "\"shutter_speed\":\"" << result.data.shutter_speed << "\","
             << "\"focal_length\":" << std::fixed << std::setprecision(1) << result.data.focal_length << ","
             << "\"flash_used\":" << (result.data.flash_used ? "true" : "false") << ","
             << "\"orientation\":" << result.data.orientation << ","
             << "\"white_balance\":\"" << result.data.white_balance << "\","
             << "\"color_space\":\"" << result.data.color_space << "\","
             << "\"image_width\":" << result.data.image_width << ","
             << "\"image_height\":" << result.data.image_height << ","
             << "\"color_temperature\":" << std::fixed << std::setprecision(0) << result.data.color_temperature
             << "}";
        
        std::string json_str = json.str();
        ffi_result.data_length = static_cast<int32_t>(json_str.length() + 1);
        ffi_result.data = new char[ffi_result.data_length];
        std::strcpy(ffi_result.data, json_str.c_str());
    } else {
        std::string error_json = create_error_json(result.error_message);
        ffi_result.data_length = static_cast<int32_t>(error_json.length() + 1);
        ffi_result.data = new char[ffi_result.data_length];
        std::strcpy(ffi_result.data, error_json.c_str());
    }
    
    return ffi_result;
}

FFIImageData convert_image_data(const ImageData& image_data) {
    FFIImageData ffi_data;
    
    if (!image_data.is_valid()) {
        ffi_data.data = nullptr;
        ffi_data.width = 0;
        ffi_data.height = 0;
        ffi_data.channels = 0;
        ffi_data.data_length = 0;
        return ffi_data;
    }
    
    ffi_data.width = image_data.width;
    ffi_data.height = image_data.height;
    ffi_data.channels = image_data.channels;
    ffi_data.data_length = static_cast<uint32_t>(image_data.data.size());
    
    // データをコピー
    ffi_data.data = new uint8_t[ffi_data.data_length];
    std::memcpy(ffi_data.data, image_data.data.data(), ffi_data.data_length);
    
    return ffi_data;
}

AdjustmentParams convert_adjustment_params(const FFIAdjustmentParams& ffi_params) {
    AdjustmentParams params;
    
    // 基本調整
    params.exposure = ffi_params.exposure;
    params.highlights = ffi_params.highlights;
    params.shadows = ffi_params.shadows;
    params.whites = ffi_params.whites;
    params.blacks = ffi_params.blacks;
    params.contrast = ffi_params.contrast;
    params.brightness = ffi_params.brightness;
    params.clarity = ffi_params.clarity;
    params.vibrance = ffi_params.vibrance;
    params.saturation = ffi_params.saturation;
    
    // 色温度・色調
    params.temperature = ffi_params.temperature;
    params.tint = ffi_params.tint;
    
    // HSL調整
    params.hue_red = ffi_params.hue_red;
    params.hue_orange = ffi_params.hue_orange;
    params.hue_yellow = ffi_params.hue_yellow;
    params.hue_green = ffi_params.hue_green;
    params.hue_aqua = ffi_params.hue_aqua;
    params.hue_blue = ffi_params.hue_blue;
    params.hue_purple = ffi_params.hue_purple;
    params.hue_magenta = ffi_params.hue_magenta;
    
    params.saturation_red = ffi_params.saturation_red;
    params.saturation_orange = ffi_params.saturation_orange;
    params.saturation_yellow = ffi_params.saturation_yellow;
    params.saturation_green = ffi_params.saturation_green;
    params.saturation_aqua = ffi_params.saturation_aqua;
    params.saturation_blue = ffi_params.saturation_blue;
    params.saturation_purple = ffi_params.saturation_purple;
    params.saturation_magenta = ffi_params.saturation_magenta;
    
    params.luminance_red = ffi_params.luminance_red;
    params.luminance_orange = ffi_params.luminance_orange;
    params.luminance_yellow = ffi_params.luminance_yellow;
    params.luminance_green = ffi_params.luminance_green;
    params.luminance_aqua = ffi_params.luminance_aqua;
    params.luminance_blue = ffi_params.luminance_blue;
    params.luminance_purple = ffi_params.luminance_purple;
    params.luminance_magenta = ffi_params.luminance_magenta;
    
    // トーンカーブ
    params.curve_highlights = ffi_params.curve_highlights;
    params.curve_lights = ffi_params.curve_lights;
    params.curve_darks = ffi_params.curve_darks;
    params.curve_shadows = ffi_params.curve_shadows;
    
    // ディテール
    params.sharpening = ffi_params.sharpening;
    params.noise_reduction = ffi_params.noise_reduction;
    params.color_noise_reduction = ffi_params.color_noise_reduction;
    
    // レンズ補正
    params.lens_distortion = ffi_params.lens_distortion;
    params.chromatic_aberration = ffi_params.chromatic_aberration;
    params.vignetting = ffi_params.vignetting;
    
    // 変形
    params.rotation = ffi_params.rotation;
    params.crop_left = ffi_params.crop_left;
    params.crop_top = ffi_params.crop_top;
    params.crop_right = ffi_params.crop_right;
    params.crop_bottom = ffi_params.crop_bottom;
    
    return params;
}

ProcessingOptions convert_processing_options(const FFIProcessingOptions& ffi_options) {
    ProcessingOptions options;
    options.output_width = ffi_options.output_width;
    options.output_height = ffi_options.output_height;
    options.quality = ffi_options.quality;
    options.preview_mode = ffi_options.preview_mode;
    options.use_gpu = ffi_options.use_gpu;
    options.thread_count = ffi_options.thread_count;
    return options;
}

ImageData convert_from_ffi_image_data(const FFIImageData& ffi_data) {
    if (ffi_data.data == nullptr || ffi_data.data_length == 0) {
        return ImageData();
    }
    
    ImageData image_data(ffi_data.width, ffi_data.height, ffi_data.channels, 8);
    
    size_t copy_size = std::min(static_cast<size_t>(ffi_data.data_length), image_data.data.size());
    std::memcpy(image_data.data.data(), ffi_data.data, copy_size);
    
    return image_data;
}

std::string create_json_string(const std::string& key, const std::string& value) {
    return "{\"" + key + "\":\"" + value + "\"}";
}

std::string create_error_json(const std::string& message) {
    return "{\"error\":\"" + message + "\"}";
}

} // namespace bridge_internal

// extern "C" API実装

extern "C" {

int64_t raw_processor_create() {
    LOG_INFO(TAG, "Creating new RawProcessor instance");
    
    std::lock_guard<std::mutex> lock(g_processors_mutex);
    
    int64_t handle = g_next_handle++;
    g_processors[handle] = std::make_unique<RawProcessor>();
    
    LOG_INFO(TAG, ("RawProcessor created with handle: " + std::to_string(handle)).c_str());
    return handle;
}

void raw_processor_destroy(int64_t handle) {
    LOG_INFO(TAG, ("Destroying RawProcessor with handle: " + std::to_string(handle)).c_str());
    
    std::lock_guard<std::mutex> lock(g_processors_mutex);
    auto it = g_processors.find(handle);
    if (it != g_processors.end()) {
        g_processors.erase(it);
        LOG_INFO(TAG, "RawProcessor destroyed successfully");
    } else {
        LOG_ERROR(TAG, "Invalid handle for destruction");
    }
}

FFIResult raw_processor_load_file(int64_t handle, const char* file_path) {
    RawProcessor* processor = bridge_internal::get_processor_from_handle(handle);
    if (!processor) {
        FFIResult result;
        result.code = static_cast<int32_t>(ResultCode::ERROR_INVALID_PARAMETERS);
        std::string error = bridge_internal::create_error_json("Invalid processor handle");
        result.data_length = static_cast<int32_t>(error.length() + 1);
        result.data = new char[result.data_length];
        std::strcpy(result.data, error.c_str());
        return result;
    }
    
    if (!file_path) {
        FFIResult result;
        result.code = static_cast<int32_t>(ResultCode::ERROR_INVALID_PARAMETERS);
        std::string error = bridge_internal::create_error_json("Null file path");
        result.data_length = static_cast<int32_t>(error.length() + 1);
        result.data = new char[result.data_length];
        std::strcpy(result.data, error.c_str());
        return result;
    }
    
    BoolResult load_result = processor->load_raw_file(std::string(file_path));
    return bridge_internal::convert_result(load_result);
}

FFIResult raw_processor_extract_metadata(int64_t handle) {
    RawProcessor* processor = bridge_internal::get_processor_from_handle(handle);
    if (!processor) {
        FFIResult result;
        result.code = static_cast<int32_t>(ResultCode::ERROR_INVALID_PARAMETERS);
        std::string error = bridge_internal::create_error_json("Invalid processor handle");
        result.data_length = static_cast<int32_t>(error.length() + 1);
        result.data = new char[result.data_length];
        std::strcpy(result.data, error.c_str());
        return result;
    }
    
    MetadataResult metadata_result = processor->extract_metadata();
    return bridge_internal::convert_result(metadata_result);
}

FFIImageData raw_processor_generate_thumbnail(int64_t handle, uint32_t max_size) {
    RawProcessor* processor = bridge_internal::get_processor_from_handle(handle);
    if (!processor) {
        FFIImageData empty_data;
        empty_data.data = nullptr;
        empty_data.width = 0;
        empty_data.height = 0;
        empty_data.channels = 0;
        empty_data.data_length = 0;
        return empty_data;
    }
    
    ImageResult thumbnail_result = processor->generate_thumbnail(max_size);
    if (thumbnail_result.is_success()) {
        return bridge_internal::convert_image_data(thumbnail_result.data);
    } else {
        FFIImageData empty_data;
        empty_data.data = nullptr;
        empty_data.width = 0;
        empty_data.height = 0;
        empty_data.channels = 0;
        empty_data.data_length = 0;
        return empty_data;
    }
}

FFIImageData raw_processor_generate_preview(
    int64_t handle, 
    const FFIAdjustmentParams* params,
    const FFIProcessingOptions* options) {
    
    RawProcessor* processor = bridge_internal::get_processor_from_handle(handle);
    if (!processor || !params || !options) {
        FFIImageData empty_data;
        empty_data.data = nullptr;
        empty_data.width = 0;
        empty_data.height = 0;
        empty_data.channels = 0;
        empty_data.data_length = 0;
        return empty_data;
    }
    
    AdjustmentParams cpp_params = bridge_internal::convert_adjustment_params(*params);
    ProcessingOptions cpp_options = bridge_internal::convert_processing_options(*options);
    
    ImageResult preview_result = processor->generate_preview(cpp_params, cpp_options);
    if (preview_result.is_success()) {
        return bridge_internal::convert_image_data(preview_result.data);
    } else {
        FFIImageData empty_data;
        empty_data.data = nullptr;
        empty_data.width = 0;
        empty_data.height = 0;
        empty_data.channels = 0;
        empty_data.data_length = 0;
        return empty_data;
    }
}

FFIImageData raw_processor_process_full_image(
    int64_t handle,
    const FFIAdjustmentParams* params,
    const FFIProcessingOptions* options) {
    
    RawProcessor* processor = bridge_internal::get_processor_from_handle(handle);
    if (!processor || !params || !options) {
        FFIImageData empty_data;
        empty_data.data = nullptr;
        empty_data.width = 0;
        empty_data.height = 0;
        empty_data.channels = 0;
        empty_data.data_length = 0;
        return empty_data;
    }
    
    AdjustmentParams cpp_params = bridge_internal::convert_adjustment_params(*params);
    ProcessingOptions cpp_options = bridge_internal::convert_processing_options(*options);
    
    ImageResult full_result = processor->process_full_image(cpp_params, cpp_options);
    if (full_result.is_success()) {
        return bridge_internal::convert_image_data(full_result.data);
    } else {
        FFIImageData empty_data;
        empty_data.data = nullptr;
        empty_data.width = 0;
        empty_data.height = 0;
        empty_data.channels = 0;
        empty_data.data_length = 0;
        return empty_data;
    }
}

FFIResult raw_processor_save_image(
    int64_t handle,
    const FFIImageData* image_data,
    const char* output_path,
    const char* format,
    uint32_t quality) {
    
    RawProcessor* processor = bridge_internal::get_processor_from_handle(handle);
    if (!processor || !image_data || !output_path || !format) {
        FFIResult result;
        result.code = static_cast<int32_t>(ResultCode::ERROR_INVALID_PARAMETERS);
        std::string error = bridge_internal::create_error_json("Invalid parameters");
        result.data_length = static_cast<int32_t>(error.length() + 1);
        result.data = new char[result.data_length];
        std::strcpy(result.data, error.c_str());
        return result;
    }
    
    ImageData cpp_image_data = bridge_internal::convert_from_ffi_image_data(*image_data);
    BoolResult save_result = processor->save_image(
        cpp_image_data,
        std::string(output_path),
        std::string(format),
        quality
    );
    
    return bridge_internal::convert_result(save_result);
}

FFIResult raw_processor_get_current_file_path(int64_t handle) {
    RawProcessor* processor = bridge_internal::get_processor_from_handle(handle);
    if (!processor) {
        FFIResult result;
        result.code = static_cast<int32_t>(ResultCode::ERROR_INVALID_PARAMETERS);
        std::string error = bridge_internal::create_error_json("Invalid processor handle");
        result.data_length = static_cast<int32_t>(error.length() + 1);
        result.data = new char[result.data_length];
        std::strcpy(result.data, error.c_str());
        return result;
    }
    
    std::string file_path = processor->get_current_file_path();
    StringResult string_result(ResultCode::SUCCESS, file_path);
    return bridge_internal::convert_result(string_result);
}

bool raw_processor_is_loaded(int64_t handle) {
    RawProcessor* processor = bridge_internal::get_processor_from_handle(handle);
    return processor ? processor->is_loaded() : false;
}

void raw_processor_clear(int64_t handle) {
    RawProcessor* processor = bridge_internal::get_processor_from_handle(handle);
    if (processor) {
        processor->clear();
    }
}

void ffi_free_result(FFIResult* result) {
    if (result && result->data) {
        delete[] result->data;
        result->data = nullptr;
        result->data_length = 0;
    }
}

void ffi_free_image_data(FFIImageData* image_data) {
    if (image_data && image_data->data) {
        delete[] image_data->data;
        image_data->data = nullptr;
        image_data->width = 0;
        image_data->height = 0;
        image_data->channels = 0;
        image_data->data_length = 0;
    }
}

FFIResult raw_processor_initialize() {
    LOG_INFO(TAG, "Initializing RAW processor library");
    
    FFIResult result;
    result.code = static_cast<int32_t>(ResultCode::SUCCESS);
    std::string success_msg = bridge_internal::create_json_string("status", "initialized");
    result.data_length = static_cast<int32_t>(success_msg.length() + 1);
    result.data = new char[result.data_length];
    std::strcpy(result.data, success_msg.c_str());
    
    return result;
}

void raw_processor_finalize() {
    LOG_INFO(TAG, "Finalizing RAW processor library");
    
    std::lock_guard<std::mutex> lock(g_processors_mutex);
    g_processors.clear();
    
    LOG_INFO(TAG, "RAW processor library finalized");
}

FFIResult raw_processor_get_version() {
    std::string version = "1.0.0";
    StringResult version_result(ResultCode::SUCCESS, version);
    return bridge_internal::convert_result(version_result);
}

FFIResult raw_processor_get_supported_formats() {
    std::string formats = "[\"CR2\",\"NEF\",\"ARW\",\"DNG\",\"RAF\",\"RW2\",\"ORF\",\"PEF\",\"SRW\",\"3FR\",\"FFF\",\"IIQ\",\"MOS\",\"CRW\",\"ERF\",\"MEF\",\"MRW\",\"X3F\"]";
    StringResult formats_result(ResultCode::SUCCESS, formats);
    return bridge_internal::convert_result(formats_result);
}

} // extern "C"

} // namespace raw_editor