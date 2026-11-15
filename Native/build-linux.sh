#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$(readlink -f -- "$0")")/.."
[[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] || {
    echo 'This build requires Linux x86_64.' >&2; exit 1;
}
haxe Native/library-linux.hxml
mv export_classes.info Export/linux-library/
hxcpp_dir=$(haxelib path hxcpp | sed -n '/^\//{p;q;}')
lime_dir=$(haxelib path lime | sed -n '/^\//{p;q;}')
# Haxelib's Lime classpath points to src, whereas hxcpp points to its root.
lime_dir=$(dirname -- "${lime_dir%/}")
sdk=Export/linux-library/sdk
rm -rf -- "$sdk"
mkdir -p "$sdk/include" "$sdk/hxcpp" "$sdk/licenses"
cp Export/linux-library/obj/ChaosLibrary.dso "$sdk/libchaos_runtime.so"
cp -R Export/linux-library/obj/include/. "$sdk/include/"
cp Export/linux-library/obj/HxcppConfig.h "$sdk/include/"
cp -R "$hxcpp_dir/include/." "$sdk/hxcpp/"
cp "$lime_dir/ndll/Linux64/lime.ndll" "$sdk/"
cp Native/README.md "$sdk/"
for library in hxcpp lime openfl actuate chaos-engine chaos-framework; do
    library_dir=$(haxelib path "$library" | sed -n '/^\//{p;q;}')
    library_dir=${library_dir%/}
    [[ $library_dir != */src ]] || library_dir=$(dirname -- "$library_dir")
    for license in "$library_dir"/LICENSE*; do
        [[ ! -f $license ]] || cp "$license" "$sdk/licenses/$library-$(basename -- "$license")"
    done
done
echo "Built shared-library files: $PWD/$sdk"
