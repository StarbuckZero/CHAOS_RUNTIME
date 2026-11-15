# CHAOS Runtime

## Linux build

Requires Haxe, Neko, a C++ compiler, Make, and the OpenFL, Lime, hxcpp, and
Actuate Haxelib packages. The Linux build was verified with Haxe 4.3.7,
OpenFL 9.5.2, Lime 8.3.2, hxcpp 4.3.2, and Actuate 1.9.0.

Register your CHAOS Framework and Engine checkouts with Haxelib first:

```sh
haxelib dev chaos-framework /path/to/CHAOS_FRAMEWORK
haxelib dev chaos-engine /path/to/CHAOS_ENGINE
```

Engine's `com/chaos/engine/event` directory must be lowercase on Linux.
From this repository, build and run the desktop application:

```sh
haxelib run lime build linux -64
./Export/linux/bin/CHAOSRUNTIME
```

The included `project.json` is an empty starter project. Replace it with your
project and rebuild to copy it beside the executable. The `Assets` directory
is optional. Running the application requires a graphical session.

The HTML5 build remains available with `haxelib run lime build html5`.

## Linux C++ shared library

Run `bash Native/build-linux.sh` to build `libchaos_runtime.so` and collect its
generated C++/hxcpp headers. See
[Native/README.md](Native/README.md) for ownership, initialization, shutdown,
rendering, and compiler requirements. The unpacked SDK files are generated under
`Export/linux-library/sdk/`. Download packaging is handled by the publishing server.

## macOS builds (unverified)

With Xcode and macOS Haxe/Neko installed, build the application with
`haxelib run lime build mac -arm64` (Apple Silicon) or
`haxelib run lime build mac -64` (Intel). Build the C++ `.dylib` SDK with
`bash Native/build-macos.sh arm64` or `bash Native/build-macos.sh x86_64`.
The workspace's `build-macos.sh` builds and collects both as unpacked files.
See [Native/MACOS.md](Native/MACOS.md) for setup and architecture requirements.
These targets have not been built or run on a Mac.
