#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
if [[ ${1:-} == --help ]]; then
    echo "Usage: $0 [arm64|x86_64]"
    echo 'Builds unpacked libchaos_runtime.dylib, Lime, and matching C++ headers. Requires macOS and Xcode.'
    exit 0
fi
[[ $# -le 1 ]] || { echo 'Expected at most one architecture.' >&2; exit 1; }
[[ $(uname -s) == Darwin ]] || { echo 'This build requires macOS.' >&2; exit 1; }
architecture=${1:-$(uname -m)}
case $architecture in
    arm64) architecture_define=HXCPP_ARM64; lime_platform=MacArm64 ;;
    x86_64) architecture_define=HXCPP_M64; lime_platform=Mac64 ;;
    *) echo 'Supported architectures: arm64, x86_64.' >&2; exit 1 ;;
esac
for tool in haxe haxelib neko xcrun ditto codesign; do
    command -v "$tool" >/dev/null || { echo "Missing tool: $tool. See Native/MACOS.md." >&2; exit 1; }
done
xcrun --find clang++ >/dev/null
export MACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET:-11.0}
hxcpp_dir=$(haxelib path hxcpp | sed -n '/^\//{p;q;}')
lime_dir=$(haxelib path lime | sed -n '/^\//{p;q;}')
lime_dir=$(dirname -- "${lime_dir%/}")
lime_binary="$lime_dir/ndll/$lime_platform/lime.ndll"
[[ -f $lime_binary ]] || { echo "Missing $lime_binary; install/rebuild Lime for $architecture." >&2; exit 1; }
xcrun lipo -verify_arch "$architecture" "$lime_binary"
output="Export/macos-library/$architecture"
haxe Native/library-macos.hxml -D "$architecture_define" -cpp "$output/obj"
mv export_classes.info "$output/"
sdk="$output/sdk"
rm -rf -- "$sdk"
mkdir -p "$sdk/include" "$sdk/hxcpp" "$sdk/licenses"
cp "$output/obj/ChaosLibrary.dylib" "$sdk/libchaos_runtime.dylib"
xcrun lipo -verify_arch "$architecture" "$sdk/libchaos_runtime.dylib"
xcrun install_name_tool -id '@rpath/libchaos_runtime.dylib' "$sdk/libchaos_runtime.dylib"
codesign --force --sign - "$sdk/libchaos_runtime.dylib"
ditto "$output/obj/include" "$sdk/include"
cp "$output/obj/HxcppConfig.h" "$sdk/include/"
ditto "$hxcpp_dir/include" "$sdk/hxcpp"
cp "$lime_binary" "$sdk/"
cp Native/README.md Native/MACOS.md "$sdk/"
for library in hxcpp lime openfl actuate chaos-engine chaos-framework; do
    library_dir=$(haxelib path "$library" | sed -n '/^\//{p;q;}')
    library_dir=${library_dir%/}
    [[ $library_dir != */src ]] || library_dir=$(dirname -- "$library_dir")
    for license in "$library_dir"/LICENSE*; do
        [[ ! -f $license ]] || cp "$license" "$sdk/licenses/$library-$(basename -- "$license")"
    done
done
echo "Built shared-library files: $PWD/$sdk"
