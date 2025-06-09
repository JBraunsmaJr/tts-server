# Dockerfile for Piper TTS Server (Final, Self-Contained Method)

# Use the latest stable Node.js base image (Debian 12 "Bookworm")
FROM node:20-slim AS builder

# Set ARGs for versions to make them easy to update
ARG PIPER_VERSION=2023.11.14-2
ARG PIPER_VOICE=en_GB-northern_english_male-medium
ARG PIPER_VOICE_2=en_US-norman-medium

# --- Stage 1: Compile espeak-ng into a self-contained local directory ---
WORKDIR /app

# Install the build tools
RUN apt-get update && apt-get install -y \
    git \
    autoconf \
    automake \
    libtool \
    pkg-config \
    g++ \
    make \
    libsonic-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Clone and compile espeak-ng, installing to a local prefix inside /app
RUN git clone https://github.com/espeak-ng/espeak-ng.git && \
    cd espeak-ng && \
    ./autogen.sh && \
    # --- FIX: Install to a completely local, self-contained directory ---
    ./configure --prefix=/app/espeak-install && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm -rf espeak-ng

# --- Stage 2: Download Piper and Models ---
# Install wget for downloading
RUN apt-get update && apt-get install -y wget && apt-get clean

# Download Piper
RUN wget "https://github.com/rhasspy/piper/releases/download/${PIPER_VERSION}/piper_linux_x86_64.tar.gz" -O piper.tar.gz && \
    tar -zxvf piper.tar.gz && \
    # Just move the contents of the piper dir, not to a system path
    mv piper piper-bin && \
    rm -f piper.tar.gz

# Download the voice models
RUN mkdir -p /app/models
RUN wget "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/northern_english_male/medium/${PIPER_VOICE}.onnx" -O "/app/models/${PIPER_VOICE}.onnx" && \
    wget "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/northern_english_male/medium/${PIPER_VOICE}.onnx.json" -O "/app/models/${PIPER_VOICE}.onnx.json"

RUN wget "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/norman/medium/${PIPER_VOICE_2}.onnx" -O "/app/models/${PIPER_VOICE_2}.onnx" && \
    wget "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/norman/medium/${PIPER_VOICE_2}.onnx.json" -O "/app/models/${PIPER_VOICE_2}.onnx.json"


# --- Stage 3: Build Node.js application ---
COPY package*.json ./
RUN npm install
COPY . .
RUN npx tsc


# --- Final Production Stage ---
FROM node:20-slim

WORKDIR /app

# --- FIX: Set Environment Variables to point to our self-contained libraries and data ---
ENV LD_LIBRARY_PATH=/app/piper-bin:/app/espeak-install/lib:$LD_LIBRARY_PATH
ENV ESPEAK_DATA_PATH=/app/espeak-install/share/espeak-ng-data

# Copy all our application artifacts from the builder stage
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/models ./models
COPY --from=builder /app/espeak-install ./espeak-install
COPY --from=builder /app/piper-bin ./piper-bin

# Make the piper binary executable
RUN chmod +x /app/piper-bin/piper

RUN mkdir -p /app/output
EXPOSE 3000

# Update the TypeScript code to use the local piper path
# We'll do this on the fly here to avoid another file change for you
RUN sed -i "s|'/usr/local/bin/piper'|'/app/piper-bin/piper'|g" /app/dist/piper.js

CMD ["node", "dist/server.js"]