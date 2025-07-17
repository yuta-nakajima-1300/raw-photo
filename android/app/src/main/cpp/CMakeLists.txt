# CMakeLists.txt for RAW Photo Editor Native Module

cmake_minimum_required(VERSION 3.18.1)

project(raw_photo_editor_native)

# C++17を使用
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# デバッグフラグ
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -DDEBUG")

# ソースファイル定義
set(SOURCES
    raw_processor.cpp
    image_processor.cpp
    metadata_extractor.cpp
    native_bridge.cpp
)

# ヘッダーファイル定義
set(HEADERS
    raw_processor.h
    image_processor.h
    metadata_extractor.h
    native_bridge.h
    common_types.h
)

# ライブラリディレクトリ
set(LIB_DIR ${CMAKE_SOURCE_DIR}/../../../../../../libs)

# LibRaw
find_library(LIBRAW_LIB
    NAMES libraw
    PATHS ${LIB_DIR}/libraw
    PATH_SUFFIXES lib
    NO_DEFAULT_PATH
)

# OpenCV
set(OpenCV_DIR ${LIB_DIR}/opencv/sdk/native/jni)
find_package(OpenCV REQUIRED)

# インクルードディレクトリ
include_directories(
    ${LIB_DIR}/libraw/include
    ${OpenCV_INCLUDE_DIRS}
    ${CMAKE_SOURCE_DIR}
)

# 共有ライブラリ作成
add_library(raw_photo_editor_native SHARED ${SOURCES})

# リンクライブラリ
target_link_libraries(raw_photo_editor_native
    ${LIBRAW_LIB}
    ${OpenCV_LIBS}
    log
    android
    jnigraphics
)

# コンパイラフラグ
target_compile_options(raw_photo_editor_native PRIVATE
    -Wall
    -Wextra
    -O3
    -ffast-math
    -DANDROID
    -D__ANDROID_API__=21
)

# プリプロセッサ定義
target_compile_definitions(raw_photo_editor_native PRIVATE
    LIBRAW_NODLL
    USE_JPEG
    USE_ZLIB
)

# デバッグシンボル保持
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_compile_options(raw_photo_editor_native PRIVATE -g)
endif()

# 最適化フラグ
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_compile_options(raw_photo_editor_native PRIVATE
        -flto
        -fomit-frame-pointer
        -ffunction-sections
        -fdata-sections
    )
    target_link_options(raw_photo_editor_native PRIVATE
        -Wl,--gc-sections
        -Wl,--strip-all
    )
endif()