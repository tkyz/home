# syntax = docker/dockerfile:1.0-experimental

ARG DOCKER_BUILDING
ARG DOCKER_TAG

#----------------------------------------------------------------
FROM php:fpm-alpine

# 内部完結

EXPOSE 9000

# 外部参照

RUN \
  apk update && \
  apk upgrade && \
  apk add --no-cache \
    libjpeg-turbo \
    libpng \
    freetype \
    oniguruma \
    ffmpeg \
    zip && \
  apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
    imagemagick && \
  apk add --no-cache --virtual .build-deps \
    libjpeg-turbo-dev \
    libpng-dev \
    freetype-dev \
    oniguruma-dev && \
  docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg && \
  docker-php-ext-install \
    mbstring \
    exif \
    gd && \
  apk del --purge .build-deps && \
  true
