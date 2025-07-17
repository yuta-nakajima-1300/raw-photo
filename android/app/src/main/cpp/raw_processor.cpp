#include "raw_processor.h"
#include <android/log.h>
#include <algorithm>
#include <cmath>
#include <fstream>

namespace raw_editor {

static const char* TAG = "RawProcessor";

RawProcessor::RawProcessor() 
    : libraw_(std::make_unique<LibRaw>()), 
      is_loaded_(false), 
      cache_valid_(false) {
    
    // LibRawの初期設定
    libraw_->imgdata.params.use_camera_wb = 1;
    libraw_->imgdata.params.use_auto_wb = 0;
    libraw_->imgdata.params.output_color = 1; // sRGB
    libraw_->imgdata.params.gamma_16bit = 1;
    libraw_->imgdata.params.no_auto_bright = 1;
    libraw_->imgdata.params.bright = 1.0;
    libraw_->imgdata.params.output_bps = 16;
    
    LOG_INFO(TAG, "RawProcessor initialized");
}

RawProcessor::~RawProcessor() {
    clear();
    LOG_INFO(TAG, "RawProcessor destroyed");
}

BoolResult RawProcessor::load_raw_file(const std::string& file_path) {
    LOG_INFO(TAG, ("Loading RAW file: " + file_path).c_str());
    
    // 既存のファイルをクリア
    clear();
    
    // ファイル存在確認
    std::ifstream file(file_path);
    if (!file.good()) {
        std::string error = "File not found: " + file_path;
        LOG_ERROR(TAG, error.c_str());
        return BoolResult(ResultCode::ERROR_FILE_NOT_FOUND, error);
    }
    
    // LibRawでファイルを開く
    int ret = libraw_->open_file(file_path.c_str());
    if (ret != LIBRAW_SUCCESS) {
        std::string error = "Failed to open RAW file: " + get_libraw_error_message(ret);
        LOG_ERROR(TAG, error.c_str());
        return BoolResult(ResultCode::ERROR_LIBRAW_ERROR, error);
    }
    
    // ファイル情報を読み込み
    ret = libraw_->unpack();
    if (ret != LIBRAW_SUCCESS) {
        std::string error = "Failed to unpack RAW file: " + get_libraw_error_message(ret);
        LOG_ERROR(TAG, error.c_str());
        libraw_->recycle();
        return BoolResult(ResultCode::ERROR_LIBRAW_ERROR, error);
    }
    
    current_file_path_ = file_path;
    is_loaded_ = true;
    invalidate_cache();
    
    LOG_INFO(TAG, "RAW file loaded successfully");
    return BoolResult(ResultCode::SUCCESS, true);
}

MetadataResult RawProcessor::extract_metadata() const {
    if (!is_loaded_) {
        return MetadataResult(ResultCode::ERROR_INVALID_PARAMETERS, "No RAW file loaded");
    }
    
    RawMetadata metadata;
    
    // カメラ情報
    if (libraw_->imgdata.idata.make[0]) {
        metadata.camera_make = std::string(libraw_->imgdata.idata.make);
    }
    if (libraw_->imgdata.idata.model[0]) {
        metadata.camera_model = std::string(libraw_->imgdata.idata.model);
    }
    
    // レンズ情報
    if (libraw_->imgdata.lens.Lens[0]) {
        metadata.lens_model = std::string(libraw_->imgdata.lens.Lens);
    }
    
    // 撮影情報
    metadata.iso = static_cast<u32>(libraw_->imgdata.other.iso_speed);
    metadata.aperture = libraw_->imgdata.other.aperture;
    metadata.focal_length = libraw_->imgdata.other.focal_len;
    metadata.flash_used = libraw_->imgdata.color.flash_used != 0;
    metadata.orientation = libraw_->imgdata.sizes.flip;
    
    // シャッタースピード
    if (libraw_->imgdata.other.shutter > 0) {
        if (libraw_->imgdata.other.shutter >= 1.0) {
            metadata.shutter_speed = std::to_string(static_cast<int>(libraw_->imgdata.other.shutter)) + "s";
        } else {
            metadata.shutter_speed = "1/" + std::to_string(static_cast<int>(1.0 / libraw_->imgdata.other.shutter));
        }
    }
    
    // 画像サイズ
    metadata.image_width = libraw_->imgdata.sizes.width;
    metadata.image_height = libraw_->imgdata.sizes.height;
    
    // ホワイトバランス
    metadata.color_temperature = libraw_->imgdata.color.WB_Coeffs[0] > 0 ? 
        6500.0f / libraw_->imgdata.color.WB_Coeffs[0] * libraw_->imgdata.color.WB_Coeffs[2] : 0.0f;
    
    // 色空間
    metadata.color_space = "sRGB"; // デフォルト
    
    LOG_INFO(TAG, "Metadata extracted successfully");
    return MetadataResult(ResultCode::SUCCESS, metadata);
}

ImageResult RawProcessor::generate_thumbnail(u32 max_size) const {
    if (!is_loaded_) {
        return ImageResult(ResultCode::ERROR_INVALID_PARAMETERS, "No RAW file loaded");
    }
    
    LOG_INFO(TAG, ("Generating thumbnail with max size: " + std::to_string(max_size)).c_str());
    
    // LibRawから埋め込みサムネイルを取得
    int ret = libraw_->unpack_thumb();
    if (ret == LIBRAW_SUCCESS && libraw_->imgdata.thumbnail.thumb) {
        // 埋め込みサムネイルが利用可能
        cv::Mat thumb_mat;
        
        if (libraw_->imgdata.thumbnail.tformat == LIBRAW_THUMBNAIL_JPEG) {
            // JPEG サムネイル
            std::vector<u8> jpeg_data(
                libraw_->imgdata.thumbnail.thumb,
                libraw_->imgdata.thumbnail.thumb + libraw_->imgdata.thumbnail.tlength
            );
            thumb_mat = cv::imdecode(jpeg_data, cv::IMREAD_COLOR);
        } else {
            // RAW サムネイル（PPM形式など）
            cv::Mat raw_thumb(
                libraw_->imgdata.thumbnail.theight,
                libraw_->imgdata.thumbnail.twidth,
                CV_8UC3,
                libraw_->imgdata.thumbnail.thumb
            );
            thumb_mat = raw_thumb.clone();
        }
        
        if (!thumb_mat.empty()) {
            // サイズ調整
            cv::Mat resized = resize_if_needed(thumb_mat, max_size, max_size);
            cv::cvtColor(resized, resized, cv::COLOR_BGR2RGB);
            
            ImageData result = mat_to_image_data(resized);
            LOG_INFO(TAG, "Thumbnail generated from embedded thumbnail");
            return ImageResult(ResultCode::SUCCESS, result);
        }
    }
    
    // 埋め込みサムネイルが利用できない場合、RAWから生成
    ProcessingOptions options(true);
    options.output_width = max_size;
    options.output_height = max_size;
    
    cv::Mat image = process_with_libraw(options);
    if (image.empty()) {
        return ImageResult(ResultCode::ERROR_PROCESSING_FAILED, "Failed to process RAW for thumbnail");
    }
    
    cv::Mat resized = resize_if_needed(image, max_size, max_size);
    cv::cvtColor(resized, resized, cv::COLOR_BGR2RGB);
    
    ImageData result = mat_to_image_data(resized);
    LOG_INFO(TAG, "Thumbnail generated from RAW processing");
    return ImageResult(ResultCode::SUCCESS, result);
}

ImageResult RawProcessor::generate_preview(
    const AdjustmentParams& params,
    const ProcessingOptions& options) {
    
    if (!is_loaded_) {
        return ImageResult(ResultCode::ERROR_INVALID_PARAMETERS, "No RAW file loaded");
    }
    
    LOG_INFO(TAG, "Generating preview with adjustments");
    
    // キャッシュされた画像を使用するか確認
    cv::Mat base_image;
    if (cache_valid_ && !cached_image_.empty()) {
        base_image = cached_image_.clone();
    } else {
        base_image = process_with_libraw(options);
        if (base_image.empty()) {
            return ImageResult(ResultCode::ERROR_PROCESSING_FAILED, "Failed to process RAW");
        }
        
        // キャッシュを更新
        cached_image_ = base_image.clone();
        cache_valid_ = true;
    }
    
    // 調整を段階的に適用
    cv::Mat result = base_image.clone();
    
    try {
        // 1. ホワイトバランス調整
        result = apply_white_balance(result, params);
        
        // 2. 基本調整（露出、コントラストなど）
        result = apply_basic_adjustments(result, params);
        
        // 3. HSL調整
        result = apply_hsl_adjustments(result, params);
        
        // 4. トーンカーブ
        result = apply_tone_curve(result, params);
        
        // 5. ディテール調整
        result = apply_detail_adjustments(result, params);
        
        // 6. レンズ補正
        result = apply_lens_corrections(result, params);
        
        // 7. 変形（回転・クロップ）
        result = apply_transform(result, params);
        
        // 色空間をRGBに変換
        cv::cvtColor(result, result, cv::COLOR_BGR2RGB);
        
        ImageData image_data = mat_to_image_data(result);
        LOG_INFO(TAG, "Preview generated successfully");
        return ImageResult(ResultCode::SUCCESS, image_data);
        
    } catch (const cv::Exception& e) {
        std::string error = "OpenCV error during processing: " + std::string(e.what());
        LOG_ERROR(TAG, error.c_str());
        return ImageResult(ResultCode::ERROR_OPENCV_ERROR, error);
    } catch (const std::exception& e) {
        std::string error = "Error during processing: " + std::string(e.what());
        LOG_ERROR(TAG, error.c_str());
        return ImageResult(ResultCode::ERROR_PROCESSING_FAILED, error);
    }
}

ImageResult RawProcessor::process_full_image(
    const AdjustmentParams& params,
    const ProcessingOptions& options) {
    
    if (!is_loaded_) {
        return ImageResult(ResultCode::ERROR_INVALID_PARAMETERS, "No RAW file loaded");
    }
    
    LOG_INFO(TAG, "Processing full resolution image");
    
    // フル解像度で処理
    ProcessingOptions full_options = options;
    full_options.preview_mode = false;
    
    cv::Mat base_image = process_with_libraw(full_options);
    if (base_image.empty()) {
        return ImageResult(ResultCode::ERROR_PROCESSING_FAILED, "Failed to process RAW at full resolution");
    }
    
    // プレビューと同じ調整パイプラインを適用
    cv::Mat result = base_image.clone();
    
    try {
        result = apply_white_balance(result, params);
        result = apply_basic_adjustments(result, params);
        result = apply_hsl_adjustments(result, params);
        result = apply_tone_curve(result, params);
        result = apply_detail_adjustments(result, params);
        result = apply_lens_corrections(result, params);
        result = apply_transform(result, params);
        
        // 出力サイズの調整
        if (full_options.output_width > 0 && full_options.output_height > 0) {
            result = resize_if_needed(result, full_options.output_width, full_options.output_height);
        }
        
        cv::cvtColor(result, result, cv::COLOR_BGR2RGB);
        
        ImageData image_data = mat_to_image_data(result);
        LOG_INFO(TAG, "Full resolution image processed successfully");
        return ImageResult(ResultCode::SUCCESS, image_data);
        
    } catch (const cv::Exception& e) {
        std::string error = "OpenCV error during full processing: " + std::string(e.what());
        LOG_ERROR(TAG, error.c_str());
        return ImageResult(ResultCode::ERROR_OPENCV_ERROR, error);
    } catch (const std::exception& e) {
        std::string error = "Error during full processing: " + std::string(e.what());
        LOG_ERROR(TAG, error.c_str());
        return ImageResult(ResultCode::ERROR_PROCESSING_FAILED, error);
    }
}

BoolResult RawProcessor::save_image(
    const ImageData& image_data,
    const std::string& output_path,
    const std::string& format,
    u32 quality) const {
    
    if (!image_data.is_valid()) {
        return BoolResult(ResultCode::ERROR_INVALID_PARAMETERS, "Invalid image data");
    }
    
    LOG_INFO(TAG, ("Saving image to: " + output_path).c_str());
    
    try {
        // ImageDataをOpenCV Matに変換
        cv::Mat image(
            image_data.height, 
            image_data.width, 
            image_data.channels == 3 ? CV_8UC3 : CV_8UC1,
            const_cast<byte*>(image_data.data.data())
        );
        
        // RGB→BGRに変換（OpenCVはBGR）
        if (image_data.channels == 3) {
            cv::cvtColor(image, image, cv::COLOR_RGB2BGR);
        }
        
        // フォーマット別のエンコードパラメータ
        std::vector<int> encode_params;
        
        if (format == "JPEG" || format == "JPG") {
            encode_params.push_back(cv::IMWRITE_JPEG_QUALITY);
            encode_params.push_back(static_cast<int>(quality));
        } else if (format == "PNG") {
            encode_params.push_back(cv::IMWRITE_PNG_COMPRESSION);
            encode_params.push_back(9); // 最大圧縮
        } else if (format == "TIFF") {
            encode_params.push_back(cv::IMWRITE_TIFF_COMPRESSION);
            encode_params.push_back(1); // LZW圧縮
        }
        
        // 画像を保存
        bool success = cv::imwrite(output_path, image, encode_params);
        if (!success) {
            std::string error = "Failed to save image: " + output_path;
            LOG_ERROR(TAG, error.c_str());
            return BoolResult(ResultCode::ERROR_PROCESSING_FAILED, error);
        }
        
        LOG_INFO(TAG, "Image saved successfully");
        return BoolResult(ResultCode::SUCCESS, true);
        
    } catch (const cv::Exception& e) {
        std::string error = "OpenCV error during save: " + std::string(e.what());
        LOG_ERROR(TAG, error.c_str());
        return BoolResult(ResultCode::ERROR_OPENCV_ERROR, error);
    } catch (const std::exception& e) {
        std::string error = "Error during save: " + std::string(e.what());
        LOG_ERROR(TAG, error.c_str());
        return BoolResult(ResultCode::ERROR_PROCESSING_FAILED, error);
    }
}

std::string RawProcessor::get_current_file_path() const {
    return current_file_path_;
}

bool RawProcessor::is_loaded() const {
    return is_loaded_;
}

void RawProcessor::clear() {
    if (libraw_ && is_loaded_) {
        libraw_->recycle();
    }
    current_file_path_.clear();
    is_loaded_ = false;
    invalidate_cache();
    
    LOG_INFO(TAG, "RawProcessor cleared");
}

// プライベートメソッドの実装は続く...
// [次のメッセージで継続]

} // namespace raw_editor