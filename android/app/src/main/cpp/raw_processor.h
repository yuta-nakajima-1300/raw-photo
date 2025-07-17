#ifndef RAW_PROCESSOR_H
#define RAW_PROCESSOR_H

#include "common_types.h"
#include <libraw/libraw.h>
#include <opencv2/opencv.hpp>
#include <string>
#include <memory>

namespace raw_editor {

/**
 * RAW画像処理エンジン
 * LibRawを使用してRAW画像の読み込み・処理を行う
 */
class RawProcessor {
public:
    RawProcessor();
    ~RawProcessor();
    
    // コピー・ムーブ禁止
    RawProcessor(const RawProcessor&) = delete;
    RawProcessor& operator=(const RawProcessor&) = delete;
    RawProcessor(RawProcessor&&) = delete;
    RawProcessor& operator=(RawProcessor&&) = delete;
    
    /**
     * RAWファイルを読み込む
     * @param file_path RAWファイルのパス
     * @return 読み込み結果
     */
    BoolResult load_raw_file(const std::string& file_path);
    
    /**
     * RAWメタデータを抽出
     * @return メタデータ
     */
    MetadataResult extract_metadata() const;
    
    /**
     * サムネイル画像を生成
     * @param max_size 最大サイズ（長辺）
     * @return サムネイル画像データ
     */
    ImageResult generate_thumbnail(u32 max_size = 512) const;
    
    /**
     * プレビュー画像を生成（調整適用）
     * @param params 調整パラメータ
     * @param options 処理オプション
     * @return プレビュー画像データ
     */
    ImageResult generate_preview(
        const AdjustmentParams& params,
        const ProcessingOptions& options = ProcessingOptions(true)
    );
    
    /**
     * 最終画像を出力（フル解像度）
     * @param params 調整パラメータ
     * @param options 処理オプション
     * @return 出力画像データ
     */
    ImageResult process_full_image(
        const AdjustmentParams& params,
        const ProcessingOptions& options = ProcessingOptions()
    );
    
    /**
     * 画像をファイルに保存
     * @param image_data 画像データ
     * @param output_path 出力パス
     * @param format 出力フォーマット ("JPEG", "PNG", "TIFF")
     * @param quality JPEG品質 (1-100)
     * @return 保存結果
     */
    BoolResult save_image(
        const ImageData& image_data,
        const std::string& output_path,
        const std::string& format = "JPEG",
        u32 quality = 95
    ) const;
    
    /**
     * 現在読み込まれているRAWファイルのパスを取得
     * @return ファイルパス
     */
    std::string get_current_file_path() const;
    
    /**
     * RAWファイルが読み込み済みかチェック
     * @return 読み込み済みならtrue
     */
    bool is_loaded() const;
    
    /**
     * リソースをクリア
     */
    void clear();

private:
    std::unique_ptr<LibRaw> libraw_;
    std::string current_file_path_;
    bool is_loaded_;
    mutable cv::Mat cached_image_;
    mutable bool cache_valid_;
    
    /**
     * LibRawで画像を処理してOpenCV Mat形式に変換
     * @param options 処理オプション
     * @return OpenCV Mat
     */
    cv::Mat process_with_libraw(const ProcessingOptions& options);
    
    /**
     * 基本調整を適用
     * @param image 入力画像
     * @param params 調整パラメータ
     * @return 調整済み画像
     */
    cv::Mat apply_basic_adjustments(const cv::Mat& image, const AdjustmentParams& params) const;
    
    /**
     * 色温度・色調調整を適用
     * @param image 入力画像
     * @param params 調整パラメータ
     * @return 調整済み画像
     */
    cv::Mat apply_white_balance(const cv::Mat& image, const AdjustmentParams& params) const;
    
    /**
     * HSL調整を適用
     * @param image 入力画像
     * @param params 調整パラメータ
     * @return 調整済み画像
     */
    cv::Mat apply_hsl_adjustments(const cv::Mat& image, const AdjustmentParams& params) const;
    
    /**
     * トーンカーブを適用
     * @param image 入力画像
     * @param params 調整パラメータ
     * @return 調整済み画像
     */
    cv::Mat apply_tone_curve(const cv::Mat& image, const AdjustmentParams& params) const;
    
    /**
     * シャープニング・ノイズ除去を適用
     * @param image 入力画像
     * @param params 調整パラメータ
     * @return 調整済み画像
     */
    cv::Mat apply_detail_adjustments(const cv::Mat& image, const AdjustmentParams& params) const;
    
    /**
     * レンズ補正を適用
     * @param image 入力画像
     * @param params 調整パラメータ
     * @return 調整済み画像
     */
    cv::Mat apply_lens_corrections(const cv::Mat& image, const AdjustmentParams& params) const;
    
    /**
     * 変形（回転・クロップ）を適用
     * @param image 入力画像
     * @param params 調整パラメータ
     * @return 変形済み画像
     */
    cv::Mat apply_transform(const cv::Mat& image, const AdjustmentParams& params) const;
    
    /**
     * OpenCV MatをImageDataに変換
     * @param mat OpenCV Mat
     * @return ImageData
     */
    ImageData mat_to_image_data(const cv::Mat& mat) const;
    
    /**
     * 色温度を色調整行列に変換
     * @param temperature 色温度
     * @param tint 色調
     * @return 3x3色調整行列
     */
    cv::Mat calculate_white_balance_matrix(f32 temperature, f32 tint) const;
    
    /**
     * エラーメッセージを取得
     * @param error_code LibRawエラーコード
     * @return エラーメッセージ
     */
    std::string get_libraw_error_message(int error_code) const;
    
    /**
     * 画像サイズを制限内にリサイズ
     * @param image 入力画像
     * @param max_width 最大幅
     * @param max_height 最大高さ
     * @return リサイズ済み画像
     */
    cv::Mat resize_if_needed(const cv::Mat& image, u32 max_width, u32 max_height) const;
    
    /**
     * キャッシュを無効化
     */
    void invalidate_cache();
};

} // namespace raw_editor

#endif // RAW_PROCESSOR_H