# Deterministic Linux contributor image. Version pins are mirrored in environment/toolchain.env.
# Docker requires a valid pre-FROM default; docker/build.* verifies and passes
# the same value from environment/toolchain.env.
ARG JDK_DOCKER_IMAGE=eclipse-temurin:17.0.20_8-jdk-jammy
FROM ${JDK_DOCKER_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG GODOT_RELEASE_TAG
ARG GODOT_BUILD
ARG GODOT_TEMPLATES_VERSION
ARG GODOT_LINUX_ARCHIVE
ARG GODOT_TEMPLATES_ARCHIVE
ARG ANDROID_COMMAND_LINE_TOOLS
ARG ANDROID_COMMAND_LINE_TOOLS_LINUX_URL
ARG ANDROID_COMMAND_LINE_TOOLS_LINUX_SHA1
ARG ANDROID_PLATFORM
ARG ANDROID_BUILD_TOOLS
ARG ANDROID_NDK
ARG ANDROID_CMAKE

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git unzip \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/android-sdk/cmdline-tools /tmp/cletris-downloads \
    && curl --fail --location --retry 3 "$ANDROID_COMMAND_LINE_TOOLS_LINUX_URL" -o /tmp/cletris-downloads/cmdline-tools.zip \
    && echo "$ANDROID_COMMAND_LINE_TOOLS_LINUX_SHA1  /tmp/cletris-downloads/cmdline-tools.zip" | sha1sum -c - \
    && unzip -q /tmp/cletris-downloads/cmdline-tools.zip -d /opt/android-sdk/cmdline-tools \
    && mv /opt/android-sdk/cmdline-tools/cmdline-tools /opt/android-sdk/cmdline-tools/latest

ENV ANDROID_SDK_ROOT=/opt/android-sdk \
    CLETRIS_ANDROID_SDK_ROOT=/opt/android-sdk \
    CLETRIS_JAVA_HOME=/opt/java/openjdk \
    CLETRIS_TOOLCHAIN_CACHE=/opt/cletris-cache \
    PATH=/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/opt/java/openjdk/bin:${PATH}

RUN yes | sdkmanager --sdk_root="$ANDROID_SDK_ROOT" --licenses >/dev/null \
    && sdkmanager --sdk_root="$ANDROID_SDK_ROOT" \
        "platform-tools" \
        "platforms;$ANDROID_PLATFORM" \
        "build-tools;$ANDROID_BUILD_TOOLS" \
        "ndk;$ANDROID_NDK" \
        "cmake;$ANDROID_CMAKE" \
    && test "$(sdkmanager --version)" = "$ANDROID_COMMAND_LINE_TOOLS"

RUN curl --fail --location --retry 3 \
        "https://github.com/godotengine/godot/releases/download/$GODOT_RELEASE_TAG/$GODOT_LINUX_ARCHIVE" \
        -o /tmp/cletris-downloads/godot.zip \
    && unzip -q /tmp/cletris-downloads/godot.zip -d /opt/godot \
    && mv /opt/godot/Godot_v4.6-stable_linux.x86_64 /opt/godot/godot \
    && chmod +x /opt/godot/godot \
    && test "$(/opt/godot/godot --version)" = "$GODOT_BUILD" \
    && mkdir -p "/opt/cletris-cache/godot-data/godot/export_templates/$GODOT_TEMPLATES_VERSION" \
    && curl --fail --location --retry 3 \
        "https://github.com/godotengine/godot/releases/download/$GODOT_RELEASE_TAG/$GODOT_TEMPLATES_ARCHIVE" \
        -o /tmp/cletris-downloads/templates.tpz \
    && mkdir -p /tmp/cletris-downloads/templates \
    && unzip -q /tmp/cletris-downloads/templates.tpz -d /tmp/cletris-downloads/templates \
    && cp -a /tmp/cletris-downloads/templates/templates/. "/opt/cletris-cache/godot-data/godot/export_templates/$GODOT_TEMPLATES_VERSION/" \
    && rm -rf /tmp/cletris-downloads

ENV CLETRIS_GODOT_BIN=/opt/godot/godot
WORKDIR /workspace
CMD ["bash"]
