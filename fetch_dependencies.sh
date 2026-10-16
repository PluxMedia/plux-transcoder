#!/usr/bin/env bash
# =============================================================================
# Script modular para baixar as dependências do nosso Transcoder Customizado
# Suporta: H.266/VVC (vvdec/vvenc), Dolby Vision (libdovi), xHE-AAC e AV1 (dav1d)
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPS_DIR="${SCRIPT_DIR}/deps"

mkdir -p "${DEPS_DIR}"

log() {
    echo -e "\033[1;34m[DEPENDENCIAS]\033[0m $1"
}

success() {
    echo -e "\033[1;32m[SUCESSO]\033[0m $1"
}

# 1. H.266 / VVC (Decodificador e Codificador oficial Fraunhofer HHI)
fetch_vvc() {
    log "Baixando dependências para H.266/VVC..."
    
    # Decodificador VVC
    if [ ! -d "${DEPS_DIR}/vvdec" ]; then
        log "Clonando VVdeC (Decodificador H.266 rápido)..."
        git clone --depth 1 https://github.com/fraunhoferhhi/vvdec.git "${DEPS_DIR}/vvdec"
    else
        log "VVdeC já baixado em ${DEPS_DIR}/vvdec."
    fi

    # Codificador VVC
    if [ ! -d "${DEPS_DIR}/vvenc" ]; then
        log "Clonando VVenC (Codificador H.266)..."
        git clone --depth 1 https://github.com/fraunhoferhhi/vvenc.git "${DEPS_DIR}/vvenc"
    else
        log "VVenC já baixado em ${DEPS_DIR}/vvenc."
    fi
    success "Módulos H.266/VVC prontos!"
}

# 2. Dolby Vision (libdovi - parser e injeção de RPU frame a frame)
fetch_dovi() {
    log "Baixando dependência para Dolby Vision (libdovi / dovi_tool)..."
    if [ ! -d "${DEPS_DIR}/dovi_tool" ]; then
        log "Clonando dovi_tool (libdovi C-API)..."
        git clone --depth 1 https://github.com/quietvoid/dovi_tool.git "${DEPS_DIR}/dovi_tool"
    else
        log "dovi_tool já baixado em ${DEPS_DIR}/dovi_tool."
    fi
    success "Módulo Dolby Vision pronto!"
}

# 3. xHE-AAC / Fraunhofer FDK AAC
fetch_aac() {
    log "Baixando Fraunhofer FDK AAC (suporte a áudio avançado e xHE-AAC)..."
    if [ ! -d "${DEPS_DIR}/fdk-aac" ]; then
        log "Clonando fdk-aac..."
        git clone --depth 1 https://github.com/mstorsjo/fdk-aac.git "${DEPS_DIR}/fdk-aac"
    else
        log "fdk-aac já baixado em ${DEPS_DIR}/fdk-aac."
    fi
    success "Módulo de Áudio AAC pronto!"
}

# 4. AV1 (Decodificador dav1d - referência em alta velocidade)
fetch_av1() {
    log "Baixando decodificador AV1 (dav1d da VideoLAN)..."
    if [ ! -d "${DEPS_DIR}/dav1d" ]; then
        log "Clonando dav1d..."
        git clone --depth 1 https://code.videolan.org/videolan/dav1d.git "${DEPS_DIR}/dav1d"
    else
        log "dav1d já baixado em ${DEPS_DIR}/dav1d."
    fi
    success "Módulo AV1 pronto!"
}

# 5. x264 (Codificador H.264 Estático)
fetch_x264() {
    log "Baixando x264 (H.264 estático)..."
    if [ ! -d "${DEPS_DIR}/x264" ]; then
        log "Clonando x264..."
        git clone --depth 1 https://code.videolan.org/videolan/x264.git "${DEPS_DIR}/x264"
    else
        log "x264 já baixado em ${DEPS_DIR}/x264."
    fi
    success "Módulo x264 pronto!"
}

# 6. x265 (Codificador HEVC/H.265 Estático)
fetch_x265() {
    log "Baixando x265 (HEVC estático)..."
    if [ ! -d "${DEPS_DIR}/x265" ]; then
        log "Clonando x265..."
        git clone --depth 1 https://github.com/videolan/x265.git "${DEPS_DIR}/x265" || git clone --depth 1 https://bitbucket.org/multicoreware/x265_git.git "${DEPS_DIR}/x265"
    else
        log "x265 já baixado em ${DEPS_DIR}/x265."
    fi
    git -C "${DEPS_DIR}/x265" tag -f 3.5 2>/dev/null || true
    success "Módulo x265 pronto!"
}

# 7. Patches e referências do Jellyfin-FFmpeg
fetch_jellyfin() {
    log "Baixando repositório de referência do Jellyfin-FFmpeg (filtros e tone-mapping)..."
    if [ ! -d "${DEPS_DIR}/jellyfin-ffmpeg" ]; then
        log "Clonando jellyfin-ffmpeg..."
        git clone --depth 1 https://github.com/jellyfin/jellyfin-ffmpeg.git "${DEPS_DIR}/jellyfin-ffmpeg"
    else
        log "jellyfin-ffmpeg já baixado em ${DEPS_DIR}/jellyfin-ffmpeg."
    fi
    success "Referência do Jellyfin pronta!"
}

# Ajuda
show_help() {
    echo "Uso: $0 [alvo]"
    echo ""
    echo "Alvos disponíveis:"
    echo "  all       - Baixa todas as dependências extras (VVC, AAC, AV1, x264, x265)"
    echo "  vvc       - Baixa os repositórios de H.266/VVC (vvdec e vvenc)"
    echo "  dovi      - Baixa a libdovi para Dolby Vision"
    echo "  aac       - Baixa o fdk-aac para áudio avançado / xHE-AAC"
    echo "  av1       - Baixa o decodificador dav1d"
    echo "  x264      - Baixa o codificador x264"
    echo "  x265      - Baixa o codificador x265"
    echo "  jellyfin  - Baixa o repositório de referência do Jellyfin-FFmpeg"
    echo "  list      - Lista as dependências já baixadas"
    echo ""
}

TARGET="${1:-all}"

case "${TARGET}" in
    vvc)
        fetch_vvc
        ;;
    dovi)
        fetch_dovi
        ;;
    aac)
        fetch_aac
        ;;
    av1)
        fetch_av1
        ;;
    x264)
        fetch_x264
        ;;
    x265)
        fetch_x265
        ;;
    jellyfin)
        fetch_jellyfin
        ;;
    all)
        log "Iniciando download de dependências do transcoder (VVC, AAC, AV1, x264, x265)..."
        fetch_vvc
        fetch_aac
        fetch_av1
        fetch_x264
        fetch_x265
        success "Todas as dependências foram baixadas em: ${DEPS_DIR}"
        ;;
    list)
        echo "Dependências presentes em ${DEPS_DIR}:"
        ls -lh "${DEPS_DIR}" || true
        ;;
    *)
        show_help
        ;;
esac
