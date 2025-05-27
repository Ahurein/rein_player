There are two build options: the regular one and the accelerated one using a prebuilt image with all dependencies and regular one. To use the accelerated option, you must first build the Docker image and push it to the image registry at ghcr.io. This can be wrapped in a separate repository with GitHub Actions added.

* docker build -t ghcr.io/Ahurein/flutter-gtk-mpv:latest .
* docker push ghcr.io/Ahurein/flutter-gtk-mpv:latest

Content of Dockerfile
```
# 3.32.0 or latest
FROM ghcr.io/cirruslabs/flutter:latest

RUN apt-get update && \
    apt-get install -y \
        clang \
        ninja-build \
        cmake  \
        libgtk-3-dev \
        libmpv-dev \
        mpv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN wget -O appimagetool https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage && \
    chmod +x appimagetool && \
    mv appimagetool /usr/local/bin/appimagetool

WORKDIR /app

RUN flutter doctor
```