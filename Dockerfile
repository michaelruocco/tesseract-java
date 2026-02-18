# ---------- Shared Base Image ----------
ARG BASE_IMAGE=eclipse-temurin:25-jre-jammy

# Stage 1: Builder (Compiles Leptonica + Tesseract)
FROM ${BASE_IMAGE} AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    automake \
    autoconf \
    libtool \
    pkg-config \
    git \
    wget \
    ca-certificates \
    libpng-dev \
    libjpeg-dev \
    libtiff-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

ARG LEPTONICA_VERSION=1.86.0
RUN wget https://github.com/DanBloomberg/leptonica/releases/download/${LEPTONICA_VERSION}/leptonica-${LEPTONICA_VERSION}.tar.gz \
    && tar xzf leptonica-${LEPTONICA_VERSION}.tar.gz \
    && cd leptonica-${LEPTONICA_VERSION} \
    && ./configure \
    && make -j$(nproc) \
    && make install

ARG TESSERACT_VERSION=5.5.1
RUN wget https://github.com/tesseract-ocr/tesseract/archive/refs/tags/${TESSERACT_VERSION}.tar.gz -O tesseract-${TESSERACT_VERSION}.tar.gz \
    && tar xzf tesseract-${TESSERACT_VERSION}.tar.gz \
    && cd tesseract-${TESSERACT_VERSION} \
    && ./autogen.sh \
    && ./configure \
    && make -j$(nproc) \
    && make install

# Stage 2: Base Runtime Layer (Shared by runtime + ci)
FROM ${BASE_IMAGE} AS base-runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    libpng16-16 \
    libjpeg-turbo8 \
    libtiff5 \
    zlib1g \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/bin/tesseract /usr/local/bin/
COPY --from=builder /usr/local/lib/ /usr/local/lib/
COPY --from=builder /usr/local/share/ /usr/local/share/
COPY tessdata/eng.traineddata /usr/local/share/tessdata/

ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
ENV TESSDATA_PREFIX=/usr/local/share/tessdata

# Stage 3: Minimal Runtime Image
FROM base-runtime AS runtime

WORKDIR /app

# Stage 4: CI Image (Runtime + Tooling)
FROM base-runtime AS ci

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    unzip \
    zip \
    bash \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
