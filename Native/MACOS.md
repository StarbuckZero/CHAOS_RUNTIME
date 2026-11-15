# macOS contributor builds

These build scripts have not been compiled or run on a Mac. Only shell syntax
and the non-macOS platform guards have been checked on Linux.

## Prerequisites

Install Xcode, open it to finish installing its components, and select its
developer tools. Lime's [macOS setup guide](https://lime.openfl.org/docs/advanced-setup/macos/)
requires Xcode and a Mac for native builds. Install a macOS-compatible Haxe and
Neko toolchain using the [Haxe downloads](https://haxe.org/download/) or your
package manager. The existing Linux build uses Haxe 4.3.7 and Neko 2.4.1.

Do not run the workspace's `setup.sh` or source `env.sh` on a Mac: those configure
Linux binaries. The macOS scripts use `haxe`, `haxelib`, and `neko` already on PATH.

Install and select the matching Haxelib dependencies:

```sh
haxelib install openfl 9.5.2
haxelib install lime 8.3.2
haxelib install hxcpp 4.3.2
haxelib install actuate 1.9.0
haxelib set openfl 9.5.2
haxelib set lime 8.3.2
haxelib set hxcpp 4.3.2
haxelib set actuate 1.9.0
haxelib dev chaos-framework /absolute/path/to/CHAOS_FRAMEWORK
haxelib dev chaos-engine /absolute/path/to/CHAOS_ENGINE
```

Use the matching Engine source checkout with the macOS bundle resource-path fix.
On a case-sensitive filesystem its `com/chaos/engine/event` directory must be
lowercase, matching the Haxe package. Lime must provide a `MacArm64/lime.ndll`
or `Mac64/lime.ndll` matching the architecture; the SDK script checks this before
compiling. If the selected Lime installation lacks that binary, build Lime for
that architecture first using its upstream instructions.

## Build

From the workspace root:

```sh
./build-macos.sh             # current Mac architecture
./build-macos.sh arm64       # Apple Silicon
./build-macos.sh x86_64      # Intel
```

Outputs are unpacked directories:

- `dist/macos/<architecture>/CHAOSRUNTIME.app`
- `dist/macos-library/<architecture>/libchaos_runtime.dylib`, `lime.ndll`,
  matching C++/hxcpp headers, documentation, and licenses.

To build only the SDK from the Runtime repository, run
`bash Native/build-macos.sh arm64` or `bash Native/build-macos.sh x86_64`.
Its output is `Export/macos-library/<architecture>/sdk/`.
To build only the application there, use `haxelib run lime build mac -arm64`
or `haxelib run lime build mac -64`.

The application keeps project JSON and assets in its bundle's
`Contents/Resources/`. Replace the starter `project.json` in the source checkout
before rebuilding. To launch the application after building:

```sh
open dist/macos/arm64/CHAOSRUNTIME.app
```

Each invocation produces one architecture. Cross-architecture builds require
compatible toolchains and dependencies; no universal binary is assembled.
`MACOSX_DEPLOYMENT_TARGET` defaults to `11.0` and may be overridden in the
environment. Bundled dependencies may require a newer deployment baseline.

## C++ hosts and distribution

The lifecycle in `README.md` also applies to macOS. From the SDK directory,
compile your own host with the same architecture and bundled headers:

```sh
clang++ -std=c++11 -arch arm64 -Iinclude -Ihxcpp -include include/HxcppConfig.h \
  host.cpp -L. -lchaos_runtime -Wl,-rpath,@executable_path -o host
DYLD_LIBRARY_PATH="$PWD${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" ./host
```

Use `-arch x86_64` for Intel. The dylib's install name is
`@rpath/libchaos_runtime.dylib`; keep `lime.ndll` beside it and configure the host's
loader path. Run UI operations on the main thread. The SDK uses the matching
hxcpp C++ ABI, not a compiler-independent C interface.

The SDK dylib is ad hoc signed after setting its install name. Production signing
and notarization require the distributor's own Apple configuration and are not
performed by these scripts. No test files or archives are created. The publishing
server handles download packaging.

Optional Firebase uploads use the same argument order as the Linux script:

```sh
./build-macos.sh arm64 gs://YOUR_BUCKET/native-folder gs://YOUR_BUCKET/library-folder
```

Install Google Cloud CLI and authenticate first. The destinations receive the
unpacked application bundle and SDK files recursively.
