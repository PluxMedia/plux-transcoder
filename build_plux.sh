#!/usr/bin/env bash
# =============================================================================
# Plux Transcoder (PluxMedia) - Automated Multi-Platform Build Pipeline
# Compatible with Linux (x86_64, arm64), macOS (Intel, Apple Silicon), and Windows (MSYS2)
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/setup_plux_env.sh"

NPROC=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
OS_TYPE="$(uname -s)"
echo -e "\033[1;34m[PLUX BUILD]\033[0m Iniciando pipeline em ${OS_TYPE} (${NPROC} núcleos)..."

CMAKE_GEN=""
if command -v ninja &>/dev/null; then
    CMAKE_GEN="-G Ninja"
fi

# 1. Dependências
"${SCRIPT_DIR}/fetch_dependencies.sh" all

# 2. Compilar fdk-aac (xHE-AAC / USAC)
if [ ! -f "${PLUX_BUILD}/lib/libfdk-aac.a" ]; then
    echo -e "\033[1;34m[PLUX BUILD]\033[0m Compilando fdk-aac (xHE-AAC)..."
    cd "${PLUX_DEPS}/fdk-aac"
    autoreconf -fiv
    ./configure --prefix="${PLUX_BUILD}" --disable-shared --enable-static
    make -j"${NPROC}" && make install
fi

# 3. Compilar dav1d (AV1)
if [ ! -f "${PLUX_BUILD}/lib/libdav1d.a" ]; then
    echo -e "\033[1;34m[PLUX BUILD]\033[0m Compilando dav1d (AV1)..."
    cd "${PLUX_DEPS}/dav1d"
    meson setup build -Denable_tools=false -Denable_tests=false --default-library=static --prefix "${PLUX_BUILD}" --libdir="${PLUX_BUILD}/lib"
    ninja -C build && ninja -C build install
fi

# 4. Compilar vvenc (H.266/VVC Encoder)
if [ ! -f "${PLUX_BUILD}/lib/libvvenc.a" ]; then
    echo -e "\033[1;34m[PLUX BUILD]\033[0m Compilando vvenc (H.266/VVC Encoder)..."
    cd "${PLUX_DEPS}/vvenc"
    cmake -B build -S . \
      ${CMAKE_GEN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="${PLUX_BUILD}" \
      -DCMAKE_INSTALL_LIBDIR="${PLUX_BUILD}/lib" \
      -DBUILD_SHARED_LIBS=OFF \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      -DVVENC_ENABLE_LINK_TIME_OPT=OFF
    cmake --build build -j"${NPROC}" && cmake --install build
fi

# 5. Compilar vvdec (H.266/VVC Decoder)
if [ ! -f "${PLUX_BUILD}/lib/libvvdec.a" ]; then
    echo -e "\033[1;34m[PLUX BUILD]\033[0m Compilando vvdec (H.266/VVC Decoder)..."
    cd "${PLUX_DEPS}/vvdec"
    cmake -B build -S . \
      ${CMAKE_GEN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="${PLUX_BUILD}" \
      -DCMAKE_INSTALL_LIBDIR="${PLUX_BUILD}/lib" \
      -DBUILD_SHARED_LIBS=OFF \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      -DVVDEC_ENABLE_LINK_TIME_OPT=OFF
    cmake --build build -j"${NPROC}" && cmake --install build
fi

# 6. Compilar x264 (H.264 estático)
if [ ! -f "${PLUX_BUILD}/lib/libx264.a" ]; then
    echo -e "\033[1;34m[PLUX BUILD]\033[0m Compilando x264 (H.264 estático)..."
    cd "${PLUX_DEPS}/x264"
    ./configure --prefix="${PLUX_BUILD}" --libdir="${PLUX_BUILD}/lib" --enable-static --disable-shared --disable-cli --enable-pic
    make -j"${NPROC}" && make install
fi

# 7. Compilar x265 (HEVC/H.265 estático)
if [ ! -f "${PLUX_BUILD}/lib/libx265.a" ] || [ ! -f "${PLUX_BUILD}/lib/pkgconfig/x265.pc" ]; then
    echo -e "\033[1;34m[PLUX BUILD]\033[0m Compilando x265 (HEVC estático)..."
    cd "${PLUX_DEPS}/x265"
    git tag -f 3.5 2>/dev/null || true
    if [ -f "source/CMakeLists.txt" ]; then
        sed -i.bak 's/cmake_policy(SET CMP0025 OLD)/# cmake_policy(SET CMP0025 OLD)/g' source/CMakeLists.txt 2>/dev/null || true
        sed -i.bak 's/cmake_policy(SET CMP0054 OLD)/# cmake_policy(SET CMP0054 OLD)/g' source/CMakeLists.txt 2>/dev/null || true
        sed -i.bak 's/cmake_minimum_required (VERSION 2.8.8)/cmake_minimum_required (VERSION 3.10)/g' source/CMakeLists.txt 2>/dev/null || true
        sed -i.bak 's/set(ARM_ALIASES armv6l armv7l aarch64)/set(ARM_ALIASES armv6l armv7l aarch64 arm64)/g' source/CMakeLists.txt 2>/dev/null || true
        rm -f source/CMakeLists.txt.bak
    fi
    X265_EXTRA_CMAKE=""
    # No macOS (AppleClang) e no Windows ARM64 (COFF), os arquivos de assembly do x265 quebram no linker por usarem diretivas exclusivas de Linux ELF (.hidden, %function).
    # Desativar assembly (-DENABLE_ASSEMBLY=OFF) nessas plataformas resolve 100% dos erros de link.
    if [[ "${OS_TYPE}" == "Darwin"* ]] || [[ "${MSYSTEM:-}" == *ARM* ]] || [[ "${MSYSTEM_CARCH:-}" == "aarch64" ]]; then
        X265_EXTRA_CMAKE="-DENABLE_ASSEMBLY=OFF"
    fi
    cmake -B build -S source \
      ${CMAKE_GEN} \
      -DCMAKE_BUILD_TYPE=Release \
      ${X265_EXTRA_CMAKE} \
      -DCMAKE_INSTALL_PREFIX="${PLUX_BUILD}" \
      -DCMAKE_INSTALL_LIBDIR="${PLUX_BUILD}/lib" \
      -DBUILD_SHARED_LIBS=OFF \
      -DENABLE_SHARED=OFF \
      -DENABLE_CLI=OFF \
      -DENABLE_PIC=ON
    cmake --build build -j"${NPROC}" && cmake --install build

    mkdir -p "${PLUX_BUILD}/lib/pkgconfig"
    if [ -f "${PLUX_BUILD}/lib64/libx265.a" ] && [ ! -f "${PLUX_BUILD}/lib/libx265.a" ]; then
        cp -f "${PLUX_BUILD}/lib64/libx265.a" "${PLUX_BUILD}/lib/libx265.a"
    fi
    if [ -f "${PLUX_BUILD}/lib64/pkgconfig/x265.pc" ] && [ ! -f "${PLUX_BUILD}/lib/pkgconfig/x265.pc" ]; then
        cp -f "${PLUX_BUILD}/lib64/pkgconfig/x265.pc" "${PLUX_BUILD}/lib/pkgconfig/x265.pc"
    fi
    if [ -f "build/x265.pc" ] && [ ! -f "${PLUX_BUILD}/lib/pkgconfig/x265.pc" ]; then
        cp -f "build/x265.pc" "${PLUX_BUILD}/lib/pkgconfig/x265.pc"
    fi
    if [ ! -f "${PLUX_BUILD}/lib/pkgconfig/x265.pc" ]; then
        cat << 'EOF' > "${PLUX_BUILD}/lib/pkgconfig/x265.pc"
prefix=${PLUX_BUILD}
exec_prefix=${prefix}
libdir=${prefix}/lib
includedir=${prefix}/include

Name: x265
Description: H.265/HEVC video encoder
Version: 3.5
Libs: -L${libdir} -lx265
Libs.private: -lstdc++ -lm -ldl -lrt -lpthread
Cflags: -I${includedir}
EOF
        sed -i "s|\${PLUX_BUILD}|${PLUX_BUILD}|g" "${PLUX_BUILD}/lib/pkgconfig/x265.pc"
    fi
fi

# 8. Detectar bibliotecas do sistema e configurar flags
EXTRA_LIBS="-lpthread -lm"
EXTRA_CONFIG_FLAGS=""

case "${OS_TYPE}" in
    Linux*)
        EXTRA_LIBS="${EXTRA_LIBS} -ldl"
        ;;
    Darwin*)
        EXTRA_CONFIG_FLAGS="${EXTRA_CONFIG_FLAGS} --enable-videotoolbox"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        ;;
esac

if [[ "${MSYSTEM:-}" == *CLANG* ]] || [[ "${CC:-}" == *clang* ]]; then
    CC_BIN="${CC:-clang}"
    CXX_LINKER="${CXX:-clang++}"
    AR_BIN="${AR:-llvm-ar}"
    NM_BIN="${NM:-llvm-nm}"
    RANLIB_BIN="${RANLIB:-llvm-ranlib}"
    STRIP_BIN="${STRIP:-llvm-strip}"
elif command -v gcc &>/dev/null; then
    CC_BIN="gcc"
    CXX_LINKER="g++"
    AR_BIN="ar"
    NM_BIN="nm"
    RANLIB_BIN="ranlib"
    STRIP_BIN="strip"
elif command -v clang &>/dev/null; then
    CC_BIN="clang"
    CXX_LINKER="clang++"
    AR_BIN="ar"
    NM_BIN="nm"
    RANLIB_BIN="ranlib"
    STRIP_BIN="strip"
else
    CC_BIN="${CC:-cc}"
    CXX_LINKER="${CXX:-c++}"
    AR_BIN="${AR:-ar}"
    NM_BIN="${NM:-nm}"
    RANLIB_BIN="${RANLIB:-ranlib}"
    STRIP_BIN="${STRIP:-strip}"
fi

echo -e "\033[1;34m[PLUX BUILD]\033[0m Compilador: ${CC_BIN} | Linker: ${CXX_LINKER} | Arquitetura: $(uname -m)"

check_enable() {
    local pkg="$1"
    local flag="$2"
    if pkg-config --exists "${pkg}" 2>/dev/null; then
        local cflags libs
        cflags=$(pkg-config --cflags "${pkg}" 2>/dev/null || echo "")
        libs=$(pkg-config --libs --static "${pkg}" 2>/dev/null || pkg-config --libs "${pkg}" 2>/dev/null || echo "")
        local test_c="${PLUX_BUILD}/plux_test_${pkg}.c"
        local test_out="${PLUX_BUILD}/plux_test_${pkg}.out"
        echo 'int main(void){return 0;}' > "${test_c}"
        if ${CC_BIN} "${test_c}" ${cflags} ${libs} -o "${test_out}" 2>/dev/null; then
            rm -f "${test_c}" "${test_out}"
            echo -e "\033[1;32m  [+] Habilitando ${flag} (${pkg} link OK)\033[0m"
            EXTRA_CONFIG_FLAGS="${EXTRA_CONFIG_FLAGS} ${flag}"
        else
            rm -f "${test_c}" "${test_out}"
            echo -e "\033[1;33m  [-] Omitindo ${flag} (${pkg} falhou no link de teste)\033[0m"
        fi
    else
        echo -e "\033[1;33m  [-] Omitindo ${flag} (${pkg} não detectado)\033[0m"
    fi
}

echo -e "\033[1;34m[PLUX BUILD]\033[0m Checando bibliotecas multimídia adicionais..."
check_enable "libass" "--enable-libass"
check_enable "freetype2" "--enable-libfreetype"
check_enable "vorbis" "--enable-libvorbis"
check_enable "openssl" "--enable-openssl"
check_enable "libwebp" "--enable-libwebp"
check_enable "libdrm" "--enable-libdrm"
check_enable "fribidi" "--enable-libfribidi"
check_enable "harfbuzz" "--enable-libharfbuzz"
check_enable "fontconfig" "--enable-libfontconfig"
check_enable "libxml-2.0" "--enable-libxml2"
check_enable "zimg" "--enable-libzimg"

# 9. Configurar e compilar FFmpeg (Plux Transcoder)
echo -e "\033[1;34m[PLUX BUILD]\033[0m Compilando Plux Transcoder FFmpeg..."
if [ -d "${PLUX_ROOT}/ffmpeg" ] && [ "${PLUX_ROOT}/ffmpeg" != "${PWD}" ]; then
    cd "${PLUX_ROOT}/ffmpeg"
else
    cd "${PLUX_ROOT}"
fi

PKG_CONFIG_PATH="${PLUX_BUILD}/lib/pkgconfig:${PLUX_BUILD}/lib64/pkgconfig:${PLUX_BUILD}/share/pkgconfig:${PKG_CONFIG_PATH}" \
./configure \
  --prefix="${PLUX_DIST}" \
  --bindir="${PLUX_DIST}/bin" \
  --pkg-config-flags="--static" \
  --cc="${CC_BIN}" \
  --cxx="${CXX_LINKER}" \
  --ld="${CXX_LINKER}" \
  --ar="${AR_BIN}" \
  --nm="${NM_BIN}" \
  --ranlib="${RANLIB_BIN}" \
  --strip="${STRIP_BIN}" \
  --extra-cflags="-I${PLUX_BUILD}/include -O3" \
  --extra-ldflags="-L${PLUX_BUILD}/lib -L${PLUX_BUILD}/lib64" \
  --extra-libs="${EXTRA_LIBS}" \
  --extra-version="plux" \
  --enable-gpl \
  --enable-version3 \
  --enable-nonfree \
  --enable-static \
  --disable-shared \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libvvenc \
  --enable-libdav1d \
  --enable-libfdk-aac \
  --disable-ffprobe \
  --disable-ffplay \
  ${EXTRA_CONFIG_FLAGS} || {
    echo -e "\033[1;31m[ERRO] FFmpeg ./configure falhou!\033[0m"
    if [ -f ffbuild/config.log ]; then
        echo -e "\033[1;33m--- Últimas 80 linhas de ffbuild/config.log ---\033[0m"
        tail -n 80 ffbuild/config.log
    fi
    exit 1
}

make -j"${NPROC}" && make install

# 8. Criar executável oficial do Plux Transcoder
mkdir -p "${PLUX_DIST}/bin"
if [ -f "${PLUX_DIST}/bin/ffmpeg.exe" ]; then
    mv -f "${PLUX_DIST}/bin/ffmpeg.exe" "${PLUX_DIST}/bin/Plux Transcoder.exe"
    ln -sf "Plux Transcoder.exe" "${PLUX_DIST}/bin/plux-transcoder.exe" 2>/dev/null || cp -f "${PLUX_DIST}/bin/Plux Transcoder.exe" "${PLUX_DIST}/bin/plux-transcoder.exe"
else
    mv -f "${PLUX_DIST}/bin/ffmpeg" "${PLUX_DIST}/bin/Plux Transcoder"
    ln -sf "Plux Transcoder" "${PLUX_DIST}/bin/plux-transcoder"
fi
rm -f "${PLUX_DIST}/bin/ffprobe"* "${PLUX_DIST}/bin/ffplay"* 2>/dev/null || true

echo -e "\033[1;32m[SUCESSO]\033[0m Plux Transcoder gerado em: ${PLUX_DIST}/bin/Plux Transcoder"
