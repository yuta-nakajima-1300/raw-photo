// raw_processor.cpp の続き - プライベートメソッドの実装

#include "raw_processor.h"
#include <android/log.h>

namespace raw_editor {

cv::Mat RawProcessor::process_with_libraw(const ProcessingOptions& options) {
    LOG_INFO(TAG, "Processing with LibRaw");
    
    // LibRawでRAW現像処理
    int ret = libraw_->dcraw_process();
    if (ret != LIBRAW_SUCCESS) {
        LOG_ERROR(TAG, ("LibRaw dcraw_process failed: " + get_libraw_error_message(ret)).c_str());
        return cv::Mat();
    }
    
    // 処理済み画像を取得
    libraw_processed_image_t* processed = libraw_->dcraw_make_mem_image(&ret);
    if (ret != LIBRAW_SUCCESS || !processed) {
        LOG_ERROR(TAG, ("LibRaw dcraw_make_mem_image failed: " + get_libraw_error_message(ret)).c_str());
        return cv::Mat();
    }
    
    // OpenCV Matに変換
    cv::Mat result;
    
    if (processed->type == LIBRAW_IMAGE_BITMAP) {
        if (processed->colors == 3) {
            // RGB 画像
            cv::Mat rgb_image(processed->height, processed->width, CV_8UC3, processed->data);
            result = rgb_image.clone();
        } else if (processed->colors == 1) {
            // グレースケール画像
            cv::Mat gray_image(processed->height, processed->width, CV_8UC1, processed->data);
            result = gray_image.clone();
        }
    }
    
    // メモリを解放
    LibRaw::dcraw_clear_mem(processed);
    
    if (result.empty()) {
        LOG_ERROR(TAG, "Failed to convert LibRaw image to OpenCV Mat");
        return cv::Mat();
    }
    
    // プレビューモードの場合はリサイズ
    if (options.preview_mode && (options.output_width > 0 || options.output_height > 0)) {
        result = resize_if_needed(result, options.output_width, options.output_height);
    }
    
    LOG_INFO(TAG, "LibRaw processing completed successfully");
    return result;
}

cv::Mat RawProcessor::apply_basic_adjustments(const cv::Mat& image, const AdjustmentParams& params) const {
    if (image.empty()) return image;
    
    cv::Mat result = image.clone();
    result.convertTo(result, CV_32F, 1.0/255.0); // 0-1範囲に正規化
    
    // 露出調整
    if (params.exposure != 0.0f) {
        f32 exposure_factor = std::pow(2.0f, params.exposure);
        result *= exposure_factor;
    }
    
    // ハイライト・シャドウ調整
    if (params.highlights != 0.0f || params.shadows != 0.0f) {
        cv::Mat luminance;
        cv::cvtColor(result, luminance, cv::COLOR_BGR2GRAY);
        
        // ハイライトマスク（明るい部分）
        cv::Mat highlight_mask;
        cv::threshold(luminance, highlight_mask, 0.7f, 1.0f, cv::THRESH_BINARY);
        cv::GaussianBlur(highlight_mask, highlight_mask, cv::Size(21, 21), 0);
        
        // シャドウマスク（暗い部分）
        cv::Mat shadow_mask;
        cv::threshold(luminance, shadow_mask, 0.3f, 1.0f, cv::THRESH_BINARY_INV);
        cv::GaussianBlur(shadow_mask, shadow_mask, cv::Size(21, 21), 0);
        
        // ハイライト調整適用
        if (params.highlights != 0.0f) {
            f32 highlight_factor = 1.0f + params.highlights / 100.0f;
            std::vector<cv::Mat> channels;
            cv::split(result, channels);
            
            for (auto& channel : channels) {
                cv::Mat adjusted = channel * highlight_factor;
                channel = channel.mul(1.0f - highlight_mask) + adjusted.mul(highlight_mask);
            }
            
            cv::merge(channels, result);
        }
        
        // シャドウ調整適用
        if (params.shadows != 0.0f) {
            f32 shadow_factor = 1.0f + params.shadows / 100.0f;
            std::vector<cv::Mat> channels;
            cv::split(result, channels);
            
            for (auto& channel : channels) {
                cv::Mat adjusted = channel * shadow_factor;
                channel = channel.mul(1.0f - shadow_mask) + adjusted.mul(shadow_mask);
            }
            
            cv::merge(channels, result);
        }
    }
    
    // ホワイト・ブラック調整
    if (params.whites != 0.0f) {
        f32 white_factor = 1.0f + params.whites / 100.0f;
        cv::Mat white_mask = result > 0.8f;
        result = result.mul(1.0f - white_mask) + (result * white_factor).mul(white_mask);
    }
    
    if (params.blacks != 0.0f) {
        f32 black_factor = 1.0f + params.blacks / 100.0f;
        cv::Mat black_mask = result < 0.2f;
        result = result.mul(1.0f - black_mask) + (result * black_factor).mul(black_mask);
    }
    
    // コントラスト調整
    if (params.contrast != 0.0f) {
        f32 contrast_factor = 1.0f + params.contrast / 100.0f;
        result = (result - 0.5f) * contrast_factor + 0.5f;
    }
    
    // 明度調整
    if (params.brightness != 0.0f) {
        f32 brightness_offset = params.brightness / 100.0f;
        result += brightness_offset;
    }
    
    // 彩度・自然な彩度調整
    if (params.saturation != 0.0f || params.vibrance != 0.0f) {
        cv::Mat hsv;
        cv::cvtColor(result, hsv, cv::COLOR_BGR2HSV);
        
        std::vector<cv::Mat> hsv_channels;
        cv::split(hsv, hsv_channels);
        
        if (params.saturation != 0.0f) {
            f32 sat_factor = 1.0f + params.saturation / 100.0f;
            hsv_channels[1] *= sat_factor;
        }
        
        if (params.vibrance != 0.0f) {
            // Vibrance（低彩度部分の彩度を選択的に向上）
            cv::Mat saturation_mask = hsv_channels[1] < 0.5f;
            f32 vibrance_factor = 1.0f + params.vibrance / 100.0f;
            cv::Mat adjusted = hsv_channels[1] * vibrance_factor;
            hsv_channels[1] = hsv_channels[1].mul(1.0f - saturation_mask) + 
                             adjusted.mul(saturation_mask);
        }
        
        cv::merge(hsv_channels, hsv);
        cv::cvtColor(hsv, result, cv::COLOR_HSV2BGR);
    }
    
    // クラリティ（ローカルコントラスト）
    if (params.clarity != 0.0f) {
        cv::Mat blurred;
        cv::GaussianBlur(result, blurred, cv::Size(0, 0), 10.0);
        cv::Mat unsharp_mask = result - blurred;
        f32 clarity_factor = params.clarity / 100.0f;
        result += unsharp_mask * clarity_factor;
    }
    
    // 値を0-1範囲にクランプ
    cv::threshold(result, result, 0.0, 0.0, cv::THRESH_TOZERO);
    cv::threshold(result, result, 1.0, 1.0, cv::THRESH_TRUNC);
    
    // 8ビットに戻す
    result.convertTo(result, CV_8U, 255.0);
    
    return result;
}

cv::Mat RawProcessor::apply_white_balance(const cv::Mat& image, const AdjustmentParams& params) const {
    if (image.empty() || (params.temperature == 0.0f && params.tint == 0.0f)) {
        return image;
    }
    
    cv::Mat result = image.clone();
    result.convertTo(result, CV_32F, 1.0/255.0);
    
    // 色温度調整行列を計算
    cv::Mat wb_matrix = calculate_white_balance_matrix(params.temperature, params.tint);
    
    // チャンネル分離
    std::vector<cv::Mat> channels;
    cv::split(result, channels);
    
    if (channels.size() >= 3) {
        // RGB各チャンネルに調整を適用
        cv::Mat adjusted_r = channels[2] * wb_matrix.at<f32>(0, 0); // R
        cv::Mat adjusted_g = channels[1] * wb_matrix.at<f32>(1, 1); // G
        cv::Mat adjusted_b = channels[0] * wb_matrix.at<f32>(2, 2); // B
        
        channels[0] = adjusted_b;
        channels[1] = adjusted_g;
        channels[2] = adjusted_r;
        
        cv::merge(channels, result);
    }
    
    // 値を0-1範囲にクランプ
    cv::threshold(result, result, 0.0, 0.0, cv::THRESH_TOZERO);
    cv::threshold(result, result, 1.0, 1.0, cv::THRESH_TRUNC);
    
    // 8ビットに戻す
    result.convertTo(result, CV_8U, 255.0);
    
    return result;
}

cv::Mat RawProcessor::apply_hsl_adjustments(const cv::Mat& image, const AdjustmentParams& params) const {
    if (image.empty()) return image;
    
    // HSL調整が不要かチェック
    bool has_hsl_adjustments = 
        params.hue_red != 0.0f || params.hue_orange != 0.0f || params.hue_yellow != 0.0f ||
        params.hue_green != 0.0f || params.hue_aqua != 0.0f || params.hue_blue != 0.0f ||
        params.hue_purple != 0.0f || params.hue_magenta != 0.0f ||
        params.saturation_red != 0.0f || params.saturation_orange != 0.0f ||
        params.saturation_yellow != 0.0f || params.saturation_green != 0.0f ||
        params.saturation_aqua != 0.0f || params.saturation_blue != 0.0f ||
        params.saturation_purple != 0.0f || params.saturation_magenta != 0.0f ||
        params.luminance_red != 0.0f || params.luminance_orange != 0.0f ||
        params.luminance_yellow != 0.0f || params.luminance_green != 0.0f ||
        params.luminance_aqua != 0.0f || params.luminance_blue != 0.0f ||
        params.luminance_purple != 0.0f || params.luminance_magenta != 0.0f;
    
    if (!has_hsl_adjustments) {
        return image;
    }
    
    cv::Mat result = image.clone();
    result.convertTo(result, CV_32F, 1.0/255.0);
    
    // HSV色空間に変換
    cv::Mat hsv;
    cv::cvtColor(result, hsv, cv::COLOR_BGR2HSV);
    
    std::vector<cv::Mat> hsv_channels;
    cv::split(hsv, hsv_channels);
    
    cv::Mat hue = hsv_channels[0];
    cv::Mat saturation = hsv_channels[1];
    cv::Mat value = hsv_channels[2];
    
    // 色相範囲の定義（0-360度をOpenCVの0-180に変換）
    struct ColorRange {
        f32 min_hue, max_hue;
        f32 hue_adj, sat_adj, lum_adj;
    };
    
    std::vector<ColorRange> color_ranges = {
        {0, 15, params.hue_red, params.saturation_red, params.luminance_red},          // 赤
        {15, 45, params.hue_orange, params.saturation_orange, params.luminance_orange}, // オレンジ
        {45, 75, params.hue_yellow, params.saturation_yellow, params.luminance_yellow}, // 黄
        {75, 105, params.hue_green, params.saturation_green, params.luminance_green},   // 緑
        {105, 135, params.hue_aqua, params.saturation_aqua, params.luminance_aqua},     // シアン
        {135, 165, params.hue_blue, params.saturation_blue, params.luminance_blue},     // 青
        {165, 195, params.hue_purple, params.saturation_purple, params.luminance_purple}, // 紫
        {195, 225, params.hue_magenta, params.saturation_magenta, params.luminance_magenta}, // マゼンタ
        {345, 360, params.hue_red, params.saturation_red, params.luminance_red},        // 赤（wraparound）
    };
    
    for (const auto& range : color_ranges) {
        if (range.hue_adj == 0.0f && range.sat_adj == 0.0f && range.lum_adj == 0.0f) {
            continue;
        }
        
        // 色相マスクを作成
        cv::Mat mask;
        if (range.max_hue > 180) {
            // 色相が180度を超える場合（赤の wraparound）
            cv::Mat mask1, mask2;
            cv::inRange(hue, cv::Scalar(range.min_hue / 2), cv::Scalar(180), mask1);
            cv::inRange(hue, cv::Scalar(0), cv::Scalar((range.max_hue - 360) / 2), mask2);
            mask = mask1 | mask2;
        } else {
            cv::inRange(hue, cv::Scalar(range.min_hue / 2), cv::Scalar(range.max_hue / 2), mask);
        }
        
        mask.convertTo(mask, CV_32F, 1.0/255.0);
        
        // フェザリング（ソフトな境界）
        cv::GaussianBlur(mask, mask, cv::Size(5, 5), 2.0);
        
        // 色相調整
        if (range.hue_adj != 0.0f) {
            cv::Mat adjusted_hue = hue + range.hue_adj / 2.0f; // OpenCVは0-180なので半分
            hue = hue.mul(1.0f - mask) + adjusted_hue.mul(mask);
        }
        
        // 彩度調整
        if (range.sat_adj != 0.0f) {
            f32 sat_factor = 1.0f + range.sat_adj / 100.0f;
            cv::Mat adjusted_sat = saturation * sat_factor;
            saturation = saturation.mul(1.0f - mask) + adjusted_sat.mul(mask);
        }
        
        // 明度調整
        if (range.lum_adj != 0.0f) {
            f32 lum_factor = 1.0f + range.lum_adj / 100.0f;
            cv::Mat adjusted_val = value * lum_factor;
            value = value.mul(1.0f - mask) + adjusted_val.mul(mask);
        }
    }
    
    // 値を正規化
    cv::normalize(hue, hue, 0, 180, cv::NORM_MINMAX);
    cv::threshold(saturation, saturation, 0.0, 0.0, cv::THRESH_TOZERO);
    cv::threshold(saturation, saturation, 1.0, 1.0, cv::THRESH_TRUNC);
    cv::threshold(value, value, 0.0, 0.0, cv::THRESH_TOZERO);
    cv::threshold(value, value, 1.0, 1.0, cv::THRESH_TRUNC);
    
    // チャンネルをマージしてBGRに戻す
    hsv_channels[0] = hue;
    hsv_channels[1] = saturation;
    hsv_channels[2] = value;
    
    cv::merge(hsv_channels, hsv);
    cv::cvtColor(hsv, result, cv::COLOR_HSV2BGR);
    
    // 8ビットに戻す
    result.convertTo(result, CV_8U, 255.0);
    
    return result;
}

cv::Mat RawProcessor::apply_tone_curve(const cv::Mat& image, const AdjustmentParams& params) const {
    if (image.empty()) return image;
    
    bool has_curve_adjustments = 
        params.curve_highlights != 0.0f || params.curve_lights != 0.0f ||
        params.curve_darks != 0.0f || params.curve_shadows != 0.0f;
    
    if (!has_curve_adjustments) {
        return image;
    }
    
    cv::Mat result = image.clone();
    
    // トーンカーブLUTを作成
    std::vector<uchar> lut(256);
    
    for (int i = 0; i < 256; ++i) {
        f32 input = i / 255.0f;
        f32 output = input;
        
        // 4点補間でトーンカーブを適用
        if (input < 0.25f) {
            // シャドウ
            f32 t = input / 0.25f;
            f32 shadow_adjust = params.curve_shadows / 100.0f;
            output = input + shadow_adjust * t * (1.0f - t);
        } else if (input < 0.5f) {
            // ダーク
            f32 t = (input - 0.25f) / 0.25f;
            f32 dark_adjust = params.curve_darks / 100.0f;
            output = input + dark_adjust * t * (1.0f - t);
        } else if (input < 0.75f) {
            // ライト
            f32 t = (input - 0.5f) / 0.25f;
            f32 light_adjust = params.curve_lights / 100.0f;
            output = input + light_adjust * t * (1.0f - t);
        } else {
            // ハイライト
            f32 t = (input - 0.75f) / 0.25f;
            f32 highlight_adjust = params.curve_highlights / 100.0f;
            output = input + highlight_adjust * t * (1.0f - t);
        }
        
        // 0-1範囲にクランプ
        output = std::max(0.0f, std::min(1.0f, output));
        lut[i] = static_cast<uchar>(output * 255.0f);
    }
    
    // LUTを適用
    cv::LUT(result, lut, result);
    
    return result;
}

cv::Mat RawProcessor::apply_detail_adjustments(const cv::Mat& image, const AdjustmentParams& params) const {
    if (image.empty()) return image;
    
    cv::Mat result = image.clone();
    
    // シャープニング
    if (params.sharpening != 0.0f) {
        cv::Mat blurred;
        cv::GaussianBlur(result, blurred, cv::Size(0, 0), 1.0);
        cv::Mat sharpened = result + (result - blurred) * (params.sharpening / 100.0f);
        result = sharpened;
    }
    
    // ノイズ除去
    if (params.noise_reduction != 0.0f) {
        f32 h = params.noise_reduction * 0.3f; // 強度調整
        cv::fastNlMeansDenoisingColored(result, result, h, h, 7, 21);
    }
    
    // カラーノイズ除去
    if (params.color_noise_reduction != 0.0f) {
        cv::Mat lab;
        cv::cvtColor(result, lab, cv::COLOR_BGR2Lab);
        
        std::vector<cv::Mat> lab_channels;
        cv::split(lab, lab_channels);
        
        // a,bチャンネル（色情報）にのみノイズ除去を適用
        f32 h_color = params.color_noise_reduction * 0.2f;
        cv::fastNlMeansDenoising(lab_channels[1], lab_channels[1], h_color, 7, 21);
        cv::fastNlMeansDenoising(lab_channels[2], lab_channels[2], h_color, 7, 21);
        
        cv::merge(lab_channels, lab);
        cv::cvtColor(lab, result, cv::COLOR_Lab2BGR);
    }
    
    return result;
}

cv::Mat RawProcessor::apply_lens_corrections(const cv::Mat& image, const AdjustmentParams& params) const {
    if (image.empty()) return image;
    
    cv::Mat result = image.clone();
    
    // ビネット補正
    if (params.vignetting != 0.0f) {
        cv::Point2f center(image.cols / 2.0f, image.rows / 2.0f);
        f32 max_dist = std::sqrt(center.x * center.x + center.y * center.y);
        
        cv::Mat vignette_mask = cv::Mat::zeros(image.size(), CV_32F);
        
        for (int y = 0; y < image.rows; ++y) {
            for (int x = 0; x < image.cols; ++x) {
                f32 dist = std::sqrt((x - center.x) * (x - center.x) + (y - center.y) * (y - center.y));
                f32 normalized_dist = dist / max_dist;
                
                f32 vignette_factor = 1.0f + params.vignetting / 100.0f * (1.0f - normalized_dist);
                vignette_mask.at<f32>(y, x) = vignette_factor;
            }
        }
        
        result.convertTo(result, CV_32F);
        std::vector<cv::Mat> channels;
        cv::split(result, channels);
        
        for (auto& channel : channels) {
            channel = channel.mul(vignette_mask);
        }
        
        cv::merge(channels, result);
        result.convertTo(result, CV_8U);
    }
    
    // レンズ歪み補正（簡易版）
    if (params.lens_distortion != 0.0f) {
        cv::Mat camera_matrix = cv::Mat::eye(3, 3, CV_64F);
        camera_matrix.at<double>(0, 0) = image.cols;
        camera_matrix.at<double>(1, 1) = image.rows;
        camera_matrix.at<double>(0, 2) = image.cols / 2.0;
        camera_matrix.at<double>(1, 2) = image.rows / 2.0;
        
        cv::Mat dist_coeffs = cv::Mat::zeros(4, 1, CV_64F);
        dist_coeffs.at<double>(0, 0) = params.lens_distortion / 1000.0; // 樽型/糸巻き型歪み
        
        cv::undistort(result, result, camera_matrix, dist_coeffs);
    }
    
    return result;
}

cv::Mat RawProcessor::apply_transform(const cv::Mat& image, const AdjustmentParams& params) const {
    if (image.empty()) return image;
    
    cv::Mat result = image.clone();
    
    // 回転
    if (params.rotation != 0.0f) {
        cv::Point2f center(image.cols / 2.0f, image.rows / 2.0f);
        cv::Mat rotation_matrix = cv::getRotationMatrix2D(center, params.rotation, 1.0);
        cv::warpAffine(result, result, rotation_matrix, image.size());
    }
    
    // クロップ
    if (params.crop_left != 0.0f || params.crop_top != 0.0f || 
        params.crop_right != 1.0f || params.crop_bottom != 1.0f) {
        
        int x = static_cast<int>(params.crop_left * image.cols);
        int y = static_cast<int>(params.crop_top * image.rows);
        int width = static_cast<int>((params.crop_right - params.crop_left) * image.cols);
        int height = static_cast<int>((params.crop_bottom - params.crop_top) * image.rows);
        
        // 境界チェック
        x = std::max(0, std::min(x, image.cols - 1));
        y = std::max(0, std::min(y, image.rows - 1));
        width = std::max(1, std::min(width, image.cols - x));
        height = std::max(1, std::min(height, image.rows - y));
        
        cv::Rect crop_rect(x, y, width, height);
        result = result(crop_rect).clone();
    }
    
    return result;
}

ImageData RawProcessor::mat_to_image_data(const cv::Mat& mat) const {
    if (mat.empty()) {
        return ImageData();
    }
    
    ImageData image_data(mat.cols, mat.rows, mat.channels(), 8);
    
    // データをコピー
    if (mat.isContinuous()) {
        std::memcpy(image_data.data.data(), mat.data, mat.total() * mat.elemSize());
    } else {
        // 行ごとにコピー
        for (int y = 0; y < mat.rows; ++y) {
            const uchar* src_row = mat.ptr<uchar>(y);
            uchar* dst_row = image_data.data.data() + y * mat.cols * mat.channels();
            std::memcpy(dst_row, src_row, mat.cols * mat.channels());
        }
    }
    
    return image_data;
}

cv::Mat RawProcessor::calculate_white_balance_matrix(f32 temperature, f32 tint) const {
    // 色温度を RGB 係数に変換（簡易版）
    f32 temp_factor = temperature / 1000.0f; // Kelvin -> 調整係数
    f32 tint_factor = tint / 100.0f;
    
    // 基準値（昼光色: ~5500K）からの調整
    f32 r_factor = 1.0f;
    f32 g_factor = 1.0f;
    f32 b_factor = 1.0f;
    
    if (temp_factor > 0) {
        // 暖色（低色温度）寄り
        r_factor = 1.0f + temp_factor * 0.3f;
        b_factor = 1.0f - temp_factor * 0.2f;
    } else {
        // 寒色（高色温度）寄り
        r_factor = 1.0f + temp_factor * 0.2f;
        b_factor = 1.0f - temp_factor * 0.3f;
    }
    
    // 色調調整
    if (tint_factor > 0) {
        // マゼンタ寄り
        r_factor += tint_factor * 0.1f;
        b_factor += tint_factor * 0.1f;
        g_factor -= tint_factor * 0.05f;
    } else {
        // グリーン寄り
        g_factor -= tint_factor * 0.1f;
    }
    
    // 調整行列を作成
    cv::Mat wb_matrix = cv::Mat::eye(3, 3, CV_32F);
    wb_matrix.at<f32>(0, 0) = b_factor; // B
    wb_matrix.at<f32>(1, 1) = g_factor; // G
    wb_matrix.at<f32>(2, 2) = r_factor; // R
    
    return wb_matrix;
}

std::string RawProcessor::get_libraw_error_message(int error_code) const {
    switch (error_code) {
        case LIBRAW_SUCCESS: return "Success";
        case LIBRAW_UNSPECIFIED_ERROR: return "Unspecified error";
        case LIBRAW_FILE_UNSUPPORTED: return "Unsupported file format";
        case LIBRAW_REQUEST_FOR_NONEXISTENT_IMAGE: return "Request for nonexistent image";
        case LIBRAW_OUT_OF_ORDER_CALL: return "Out of order call";
        case LIBRAW_NO_THUMBNAIL: return "No thumbnail found";
        case LIBRAW_UNSUPPORTED_THUMBNAIL: return "Unsupported thumbnail format";
        case LIBRAW_CANCELLED_BY_CALLBACK: return "Cancelled by callback";
        case LIBRAW_BAD_CROP: return "Bad crop";
        case LIBRAW_TOO_BIG: return "Image too big";
        case LIBRAW_MEMPOOL_OVERFLOW: return "Memory pool overflow";
        default: return "Unknown error (" + std::to_string(error_code) + ")";
    }
}

cv::Mat RawProcessor::resize_if_needed(const cv::Mat& image, u32 max_width, u32 max_height) const {
    if (image.empty() || (max_width == 0 && max_height == 0)) {
        return image;
    }
    
    f32 scale_x = max_width > 0 ? static_cast<f32>(max_width) / image.cols : 1.0f;
    f32 scale_y = max_height > 0 ? static_cast<f32>(max_height) / image.rows : 1.0f;
    f32 scale = std::min(scale_x, scale_y);
    
    if (scale >= 1.0f) {
        return image; // リサイズ不要
    }
    
    cv::Mat resized;
    cv::resize(image, resized, cv::Size(0, 0), scale, scale, cv::INTER_AREA);
    return resized;
}

void RawProcessor::invalidate_cache() {
    cached_image_.release();
    cache_valid_ = false;
}

} // namespace raw_editor