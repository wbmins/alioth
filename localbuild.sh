#!/usr/bin/env bash
set -euo pipefail

export https_proxy="http://127.0.0.1:7890"
# 桌面环境: plasma-mobile/sxmo/cosmic
UI="${1:-plasma-mobile}"
HOME_DIR="$HOME"
REPO_URL="https://github.com/wbmins/alioth.git"
WORKSPACE="$HOME_DIR/alioth"
PMBOOTSTRAP_DIR="$HOME_DIR/pmbootstrap"
CONFIG_DIR="$HOME_DIR/.config"
PMOS_DIR="$HOME_DIR/.local/var/pmbootstrap"

check_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "ERROR: '$1' is not installed."
        echo
        echo "Please install git parallel zip first."
        exit 1
    fi
}
# 1. 检查依赖
check_dependencies() {
    check_cmd git
    check_cmd parallel
}
# 2. 获取/更新源码仓库
sync_repository() {
    if [ ! -d "$WORKSPACE/.git" ]; then
        echo "Cloning repository..."
        git clone --recurse-submodules "$REPO_URL" "$WORKSPACE"
    else
        echo "Updating repository..."
        cd "$WORKSPACE"
        git fetch --all
        git pull
        git submodule sync --recursive
        git submodule update --init --recursive
    fi
    cd "$WORKSPACE"
}
# 3. 安装并配置 pmbootstrap
setup_pmbootstrap() {
    if [ ! -d "$PMBOOTSTRAP_DIR" ]; then
        git clone https://gitlab.postmarketos.org/postmarketOS/pmbootstrap.git "$PMBOOTSTRAP_DIR"
    fi
    cd "$PMBOOTSTRAP_DIR"
    git fetch
    git checkout 3.9.0
    chmod +x pmbootstrap.py
    sudo ln -sf "$PMBOOTSTRAP_DIR/pmbootstrap.py" /usr/local/bin/pmbootstrap
    echo "pmbootstrap version:"
    pmbootstrap --version
}
# 4. 配置 pmbootstrap（复制配置文件、设置 UI、准备 pmaports 等）
configure_pmbootstrap() {
    mkdir -p "$CONFIG_DIR"
    cp "$WORKSPACE/pmbootstrap_v3.cfg" "$CONFIG_DIR/pmbootstrap_v3.cfg"
    sed -i "s/^ui = .*/ui = ${UI}/" "$CONFIG_DIR/pmbootstrap_v3.cfg"
    echo "Current UI: $UI"
    #如果选择了 cosmic 桌面，强制将音频后端改为 pipewire 以避免冲突
    if [ "${UI}" = "cosmic" ]; then
        sed -i "s/postmarketos-base-ui-audio-backend = pulseaudio/postmarketos-base-ui-audio-backend = pipewire/g" ~/.config/pmbootstrap_v3.cfg
    fi
    mkdir -p "$PMOS_DIR/cache_git"
    if [ ! -d "$PMOS_DIR/cache_git/pmaports" ]; then
        git clone https://gitlab.postmarketos.org/postmarketOS/pmaports.git \
            "$PMOS_DIR/cache_git/pmaports"
    fi
    echo "8" > "$PMOS_DIR/version"
    echo "Copy device package..."
    cp -rf "$WORKSPACE/pmaports-alioth/device-xiaomi-alioth" \
        "$PMOS_DIR/cache_git/pmaports/device/testing/"
    echo "Copy firmware package..."
    cp -rf "$WORKSPACE/pmaports-alioth/firmware-xiaomi-alioth" \
        "$PMOS_DIR/cache_git/pmaports/device/testing/"
    echo "Copy kernel package..."
    cp -rf "$WORKSPACE/pmaports-alioth/linux-postmarketos-qcom-sm8250-alioth" \
        "$PMOS_DIR/cache_git/pmaports/device/testing/"
}
# 5. 构建 APK（firmware、kernel、device）
build_apks() {
    echo "==> Check and Build firmware"
    parallel --line-buffer --halt now,done=1 ::: \
        "pmbootstrap checksum firmware-xiaomi-alioth" \
        "pmbootstrap log"
    parallel --line-buffer --halt now,done=1 ::: \
        "pmbootstrap build firmware-xiaomi-alioth" \
        "pmbootstrap log"
    echo "==> Check and Build kernel"
    parallel --line-buffer --halt now,done=1 ::: \
        "pmbootstrap checksum linux-postmarketos-qcom-sm8250-alioth" \
        "pmbootstrap log"
    parallel --line-buffer --halt now,done=1 ::: \
        "pmbootstrap build linux-postmarketos-qcom-sm8250-alioth" \
        "pmbootstrap log"
    echo "==> Check and Build device"
    parallel --line-buffer --halt now,done=1 ::: \
        "pmbootstrap checksum device-xiaomi-alioth" \
        "pmbootstrap log"
    parallel --line-buffer --halt now,done=1 ::: \
        "pmbootstrap build device-xiaomi-alioth" \
        "pmbootstrap log"
}
# 6. 复制生成的 APK 到工作区
copy_apks() {
    mkdir -p "$WORKSPACE/edge/aarch64"

    cp -af \
        "$PMOS_DIR/packages/edge/aarch64/"{APKINDEX.tar.gz,device-xiaomi-alioth-*.apk,firmware-xiaomi-alioth-*.apk,linux-postmarketos-qcom-sm8250-alioth-*.apk} \
        "$WORKSPACE/edge/aarch64/"

    echo "APK copied to:"
    echo "$WORKSPACE/edge/aarch64"
}
# 7. 构建最终镜像
build_image() {
    echo "==> Build image"
    parallel --line-buffer --halt now,done=1 ::: \
        "pmbootstrap install --password mins" \
        "pmbootstrap log"

    echo
    echo "Generated images:"
    sudo mv ~/.local/var/pmbootstrap/chroot_rootfs_xiaomi-alioth/boot/boot.img ~/
    sudo mv ~/.local/var/pmbootstrap/chroot_native/home/pmos/rootfs/xiaomi-alioth.img ~/
}

main() {
    check_dependencies
    sync_repository
    setup_pmbootstrap
    configure_pmbootstrap
    build_apks
    # copy_apks
    # build_image

    echo
    echo "Build finished."
}

# 执行主函数
main