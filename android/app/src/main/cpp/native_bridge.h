#ifndef NATIVE_BRIDGE_H
#define NATIVE_BRIDGE_H

#include <jni.h>
#include <string>
#include <memory>
#include "raw_processor.h"

namespace raw_editor {

/**
 * Flutter FFI用のC APIブリッジ
 * RawProcessorクラスをC関数として公開し、Dartから呼び出し可能にする
 */

// FFI用の結果構造体
struct FFIResult {
    int32_t code;           // ResultCode
    char* data;             // JSON形式のデータまたはエラーメッセージ
    int32_t data_length;    // データの長さ
};

// FFI用の画像データ構造体
struct FFIImageData {
    uint8_t* data;
    uint32_t width;
    uint32_t height;
    uint32_t channels;
    uint32_t data_length;
};

// FFI用の調整パラメータ構造体（Dartと同期）
struct FFIAdjustmentParams {
    // 基本調整
    float exposure;
    float highlights;
    float shadows;
    float whites;
    float blacks;
    float contrast;
    float brightness;
    float clarity;
    float vibrance;
    float saturation;
    
    // 色温度・色調
    float temperature;
    float tint;
    
    // HSL調整
    float hue_red;
    float hue_orange;
    float hue_yellow;
    float hue_green;
    float hue_aqua;
    float hue_blue;
    float hue_purple;
    float hue_magenta;
    
    float saturation_red;
    float saturation_orange;
    float saturation_yellow;
    float saturation_green;
    float saturation_aqua;
    float saturation_blue;
    float saturation_purple;
    float saturation_magenta;
    
    float luminance_red;
    float luminance_orange;
    float luminance_yellow;
    float luminance_green;
    float luminance_aqua;
    float luminance_blue;
    float luminance_purple;
    float luminance_magenta;
    
    // トーンカーブ
    float curve_highlights;
    float curve_lights;
    float curve_darks;
    float curve_shadows;
    
    // ディテール
    float sharpening;
    float noise_reduction;
    float color_noise_reduction;
    
    // レンズ補正
    float lens_distortion;
    float chromatic_aberration;
    float vignetting;
    
    // 変形
    float rotation;
    float crop_left;
    float crop_top;
    float crop_right;
    float crop_bottom;
};

// FFI用の処理オプション
struct FFIProcessingOptions {
    uint32_t output_width;
    uint32_t output_height;
    uint32_t quality;
    bool preview_mode;
    bool use_gpu;
    uint32_t thread_count;
};

extern "C" {

/**
 * RawProcessorインスタンスを作成
 * @return プロセッサーハンドル（ポインタ）
 */
int64_t raw_processor_create();

/**
 * RawProcessorインスタンスを削除
 * @param handle プロセッサーハンドル
 */
void raw_processor_destroy(int64_t handle);

/**
 * RAWファイルを読み込み
 * @param handle プロセッサーハンドル
 * @param file_path ファイルパス
 * @return 読み込み結果
 */
FFIResult raw_processor_load_file(int64_t handle, const char* file_path);

/**
 * メタデータを抽出
 * @param handle プロセッサーハンドル
 * @return メタデータ（JSON形式）
 */
FFIResult raw_processor_extract_metadata(int64_t handle);

/**
 * サムネイル画像を生成
 * @param handle プロセッサーハンドル
 * @param max_size 最大サイズ
 * @return 画像データ
 */
FFIImageData raw_processor_generate_thumbnail(int64_t handle, uint32_t max_size);

/**
 * プレビュー画像を生成
 * @param handle プロセッサーハンドル
 * @param params 調整パラメータ
 * @param options 処理オプション
 * @return 画像データ
 */
FFIImageData raw_processor_generate_preview(
    int64_t handle, 
    const FFIAdjustmentParams* params,
    const FFIProcessingOptions* options
);

/**
 * フル解像度画像を処理
 * @param handle プロセッサーハンドル
 * @param params 調整パラメータ
 * @param options 処理オプション
 * @return 画像データ
 */
FFIImageData raw_processor_process_full_image(
    int64_t handle,
    const FFIAdjustmentParams* params,
    const FFIProcessingOptions* options
);

/**
 * 画像をファイルに保存
 * @param handle プロセッサーハンドル
 * @param image_data 画像データ
 * @param output_path 出力パス
 * @param format フォーマット
 * @param quality 品質
 * @return 保存結果
 */
FFIResult raw_processor_save_image(
    int64_t handle,
    const FFIImageData* image_data,
    const char* output_path,
    const char* format,
    uint32_t quality
);

/**
 * 現在のファイルパスを取得
 * @param handle プロセッサーハンドル
 * @return ファイルパス
 */
FFIResult raw_processor_get_current_file_path(int64_t handle);

/**
 * 読み込み状態をチェック
 * @param handle プロセッサーハンドル
 * @return 読み込み済みならtrue
 */
bool raw_processor_is_loaded(int64_t handle);

/**
 * プロセッサーをクリア
 * @param handle プロセッサーハンドル
 */
void raw_processor_clear(int64_t handle);

/**
 * FFI結果のメモリを解放
 * @param result FFI結果
 */
void ffi_free_result(FFIResult* result);

/**
 * FFI画像データのメモリを解放
 * @param image_data FFI画像データ
 */
void ffi_free_image_data(FFIImageData* image_data);

/**
 * ライブラリ初期化
 * @return 初期化結果
 */
FFIResult raw_processor_initialize();

/**
 * ライブラリ終了処理
 */
void raw_processor_finalize();

/**
 * バージョン情報を取得
 * @return バージョン文字列
 */
FFIResult raw_processor_get_version();

/**
 * サポートされているフォーマット一覧を取得
 * @return フォーマット一覧（JSON配列）
 */
FFIResult raw_processor_get_supported_formats();

} // extern "C"

// 内部ヘルパー関数
namespace bridge_internal {

/**
 * C++のResultをFFIResultに変換
 */
template<typename T>
FFIResult convert_result(const ProcessingResult<T>& result);

/**
 * C++のImageDataをFFIImageDataに変換
 */
FFIImageData convert_image_data(const ImageData& image_data);

/**
 * FFIAdjustmentParamsをC++のAdjustmentParamsに変換
 */
AdjustmentParams convert_adjustment_params(const FFIAdjustmentParams& ffi_params);

/**
 * FFIProcessingOptionsをC++のProcessingOptionsに変換
 */
ProcessingOptions convert_processing_options(const FFIProcessingOptions& ffi_options);

/**
 * FFIImageDataをC++のImageDataに変換
 */
ImageData convert_from_ffi_image_data(const FFIImageData& ffi_data);

/**
 * ハンドルからRawProcessorポインタを取得
 */
RawProcessor* get_processor_from_handle(int64_t handle);

/**
 * JSON文字列を作成
 */
std::string create_json_string(const std::string& key, const std::string& value);

/**
 * エラーメッセージをJSON形式で作成
 */
std::string create_error_json(const std::string& message);

} // namespace bridge_internal

} // namespace raw_editor

#endif // NATIVE_BRIDGE_H