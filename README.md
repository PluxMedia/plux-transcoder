# Plux Transcoder (FFmpeg Next-Gen Edition)

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE.md)
[![FFmpeg](https://img.shields.io/badge/FFmpeg-7.x%20Master-orange.svg)](https://ffmpeg.org)
[![VVC / H.266](https://img.shields.io/badge/VVC%20%2F%20H.266-Fraunhofer%20HHI-success.svg)](https://github.com/fraunhoferhhi/vvenc)
[![Dolby Vision](https://img.shields.io/badge/Dolby%20Vision-Profiles%205%20%2F%207%20%2F%208-red.svg)](https://github.com/jellyfin/jellyfin-ffmpeg)
[![Audio](https://img.shields.io/badge/Audio-xHE--AAC%20%2F%20AC--4-blueviolet.svg)](https://github.com/mstorsjo/fdk-aac)

**Plux Transcoder** is a modern, high-performance multimedia transcoding engine built on the bleeding-edge upstream **FFmpeg** tree. It enhances standard FFmpeg capabilities with out-of-the-box support for next-generation broadcast, streaming, and cinema formats—specifically **H.266 / VVC**, complete **Dolby Vision (Profiles 5, 7, and 8)** processing, **xHE-AAC**, and **Dolby AC-4**.

---

## Key Capabilities & Enhancements

### 1. H.266 / VVC (Versatile Video Coding)
- **Native & Accelerated Decoding**: Integrated support for the official Fraunhofer HHI `vvdec` library alongside upstream FFmpeg native VVC decoders.
- **Production Encoding**: Built with Fraunhofer HHI `libvvenc` integration, enabling high-efficiency H.266 encoding with SIMD optimization (AVX2, ARM NEON).
- **Workflow Synergy**: Incorporates encoding presets and packaging methodologies established by the [VVCEasy](https://github.com/MartinEesmaa/VVCEasy) project.

### 2. Full-Spectrum Dolby Vision Pipeline
- **Profile 5 (ICtCp) Tone Mapping**: Solves color distortion and the infamous "purple/green tint" issue when playing or transcoding Dolby Vision Profile 5 streams to SDR/HDR10 display targets.
- **Dynamic Metadata & RPU Preservation**: Retains Dolby Vision Reference Processing Unit (RPU) side-data during stream muxing, HLS segmenting, and hardware transcoding (inspired by the [Jellyfin-FFmpeg](https://github.com/jellyfin/jellyfin-ffmpeg) patchset).
- **Format Flexibility**: Comprehensive support across single-layer and dual-layer profiles (Profile 5, Profile 7 FEL/MEL, and Profile 8).

### 3. Advanced Next-Gen Audio
- **xHE-AAC (Extended HE-AAC / MPEG-D USAC)**: Reference audio fidelity at ultra-low bitrates via Fraunhofer IIS `fdk-aac`.
- **Dolby AC-4 Audio**: Integrated decoding support for next-generation ATSC 3.0 broadcast and streaming audio streams.
- **Spatial & Cinema Audio**: Enhanced DTS:X stream detection within DTS-HD media.

### 4. High-Performance AV1, Subtitles & Streaming
- **VideoLAN `dav1d`**: Blazing fast AV1 decoding optimized for multi-core CPUs and ARM64 platforms.
- **Rich Typography & Subtitle Engines**: Native integration of `libass`, `freetype2`, `fribidi`, and `harfbuzz` for pixel-perfect complex script and bidirectional subtitle rendering.
- **Enhanced Image & Streaming Ecosystem**: Full support for WebP (`libwebp`), direct hardware frame allocation via Linux DRM (`libdrm`), XML DASH manifest parsing (`libxml2`), and precision scaling via `libzimg`.

---

## Architecture & Portability

Plux Transcoder is architected to compile cleanly without hardcoded host environments or runtime dependency leakage:
- **Static Linking**: Designed to generate self-contained, standalone binaries with zero runtime `.so`/`.dll` dependencies.
- **Cross-Platform Readiness**: Fully portable across **Linux (x86_64, aarch64/ARM64)**, **macOS (Apple Silicon & Intel)**, and **Windows**.
- **No CI Clutter**: Clean build configurations with standardized paths and no residual build-server artifacts in version banners.

---

## Repository Structure

```text
custom-transcoder/
├── ffmpeg/               # Upstream FFmpeg source tree
├── deps/                 # Modular upstream dependencies
│   ├── vvdec/ & vvenc/   # Fraunhofer HHI H.266/VVC libraries
│   ├── fdk-aac/          # Fraunhofer IIS AAC & xHE-AAC
│   ├── dav1d/            # VideoLAN AV1 decoder
│   ├── dovi_tool/        # libdovi C-API for Dolby Vision RPU metadata
│   └── jellyfin-ffmpeg/  # Reference patchset for color filters & tonemapping
├── patches/              # Curated, isolated feature patches
├── build/                # Local build prefix ($BUILD/include, $BUILD/lib)
├── dist/                 # Final artifact output directory ($DIST/bin)
├── setup_plux_env.sh     # Clean environment configuration script
└── fetch_dependencies.sh # Modular dependency fetcher
```

---

## Build Prerequisites

Following the official Ubuntu/Debian FFmpeg compilation standard, ensure the following core tools are present:

```bash
sudo apt-get update && sudo apt-get install -y \
  autoconf automake build-essential cmake git \
  libtool pkg-config texinfo yasm nasm ninja-build meson
```

### Initializing the Environment

Before building, source the environment script to ensure standardized paths and compiler flags:

```bash
source ./setup_plux_env.sh
```

---

## Acknowledgments & Credits

Plux Transcoder is made possible by the incredible work of the global open-source multimedia community:

- **[FFmpeg Project](https://ffmpeg.org)**: The foundational multimedia framework and codec engine.
- **[Jellyfin Project](https://github.com/jellyfin/jellyfin-ffmpeg)**: Groundbreaking work on Dolby Vision tonemapping, ICtCp color conversion filters, and open-source streaming enhancements.
- **[VVCEasy (Martin Eesmaa)](https://github.com/MartinEesmaa/VVCEasy)**: Comprehensive research, automation, and tooling for accessible VVC/H.266 encoding and playback.
- **[Fraunhofer HHI](https://github.com/fraunhoferhhi)**: Authors of the official VVenC encoder and VVdeC decoder.
- **[Fraunhofer IIS](https://www.iis.fraunhofer.de/) & [Martin Storsjö](https://github.com/mstorsjo/fdk-aac)**: High-quality FDK AAC and xHE-AAC audio codec implementations.
- **[VideoLAN (dav1d)](https://code.videolan.org/videolan/dav1d)**: State-of-the-art AV1 decoding performance.
- **[quietvoid (dovi_tool / libdovi)](https://github.com/quietvoid/dovi_tool)**: Open-source Dolby Vision RPU parsing and generation tools.

---

## License

Plux Transcoder integrates components under **GPL v3** and **LGPL v2.1+**. Redistribution must comply with the licensing terms of FFmpeg and the enabled external modules. See the [LICENSE](LICENSE.md) file for comprehensive details.
