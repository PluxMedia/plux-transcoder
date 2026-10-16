#!/usr/bin/env bash
# =============================================================================
# Plux Transcoder - Environment & Generic Build Configuration
# Baseado nas melhores práticas do FFmpeg Compilation Guide (Ubuntu/Debian)
# =============================================================================

# Determina o diretório raiz do projeto Plux Transcoder de forma relativa
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PLUX_ROOT="${SCRIPT_DIR}"

# Diretórios genéricos isolados (não deixam caminhos de CI ou usuário no executável)
export PLUX_DEPS="${PLUX_ROOT}/deps"
export PLUX_BUILD="${PLUX_ROOT}/build"
export PLUX_DIST="${PLUX_ROOT}/dist"
export PLUX_PATCHES="${PLUX_ROOT}/patches"

# Criação das pastas de ambiente
mkdir -p "${PLUX_BUILD}/include"
mkdir -p "${PLUX_BUILD}/lib"
mkdir -p "${PLUX_BUILD}/lib/pkgconfig"
mkdir -p "${PLUX_BUILD}/bin"
mkdir -p "${PLUX_DIST}/bin"
mkdir -p "${PLUX_PATCHES}"

# Variáveis padrão de compilador e pkg-config
export PATH="${PLUX_BUILD}/bin:${PLUX_DIST}/bin:${PATH}"
export PKG_CONFIG_PATH="${PLUX_BUILD}/lib/pkgconfig:${PLUX_BUILD}/lib64/pkgconfig:${PLUX_BUILD}/share/pkgconfig:${PKG_CONFIG_PATH}"
export CFLAGS="-I${PLUX_BUILD}/include -O3"
export CXXFLAGS="-I${PLUX_BUILD}/include -O3"
export LDFLAGS="-L${PLUX_BUILD}/lib -L${PLUX_BUILD}/lib64"

if [ -n "${MSYSTEM_PREFIX:-}" ] && [ -d "${MSYSTEM_PREFIX}/bin" ]; then
    export PATH="${MSYSTEM_PREFIX}/bin:${PATH}"
fi

if [[ "${MSYSTEM:-}" == *CLANG* ]]; then
    export CC="clang"
    export CXX="clang++"
    export AR="llvm-ar"
    export NM="llvm-nm"
    export RANLIB="llvm-ranlib"
    export STRIP="llvm-strip"
fi

if [[ "$(uname -s)" == "Darwin"* ]]; then
    if command -v brew &>/dev/null; then
        BREW_PREFIX="$(brew --prefix)"
        export ACLOCAL_PATH="${BREW_PREFIX}/share/aclocal:${ACLOCAL_PATH:-}"
        export PATH="${BREW_PREFIX}/bin:${PATH}"
    fi
fi

# Informações de Identidade do Plux Transcoder
export PLUX_NAME="Plux Transcoder"
export PLUX_VERSION="1.0.0-plux"
export PLUX_IDENT="PluxMedia Project (VVC + Dolby Vision + xHE-AAC)"

echo -e "\033[1;32m[PLUX ENV]\033[0m Ambiente configurado com sucesso!"
echo -e "  -> Raiz:     ${PLUX_ROOT}"
echo -e "  -> Build:    ${PLUX_BUILD}"
echo -e "  -> Saída:    ${PLUX_DIST}"
echo -e "  -> PkgConfig: ${PKG_CONFIG_PATH}"
