# C++ shared library

Build from the Runtime repository with the Haxe toolchain active:

```sh
bash Native/build-linux.sh
```

This uses Haxe/hxcpp's [`dll_link` and `dll_export` targets](https://haxe.org/manual/target-cpp-defines.html). The SDK contains
`libchaos_runtime.so`, `lime.ndll`, generated public C++ headers, matching
hxcpp headers. All output is under `Export/linux-library/`.
No Git push is part of the build.

For macOS `.dylib` builds, use `bash Native/build-macos.sh` and follow
[MACOS.md](MACOS.md). macOS compilation and execution remain unverified.

## Compile a C++ host

From the extracted SDK directory:

```sh
g++ -std=c++11 -m64 -Iinclude -Ihxcpp -include include/HxcppConfig.h \
    host.cpp -L. -lchaos_runtime -Wl,-rpath,'$ORIGIN' -o host
```

Replace `host.cpp` with your application's source file.

## Lifecycle and ownership

1. On the host's main UI thread, establish `HX_TOP_OF_STACK` in a scope lasting
   for the entire Haxe session. Call the exported `hxRunLibrary()` once and
   check its returned error string (`nullptr` means success). This initializes
   Haxe without opening a CHAOS window or starting an event loop.
2. The host creates and owns an OpenFL application, window, stage, and display
   container. Call `ChaosLibrary_obj::attach(parent, projectJSON)` with a parent
   already on that stage. CHAOS preserves the host's window size/fullscreen state
   and working directory. Asset paths are relative to the host working directory.
3. The host drives OpenFL's frame/input events and rendering. The returned
   `CoreEngine` is an OpenFL display object. It can be rendered into a host-owned
   `BitmapData` for display in another GUI toolkit. Native Qt/GTK window-handle
   adoption and toolkit-specific input forwarding are not provided by hxcpp.
4. Call `ChaosLibrary_obj::shutdown()` before destroying the parent/stage.
   Shutdown removes CHAOS listeners and detaches its root; it is idempotent.
   The host retains ownership of its application, window, and bitmap surfaces.
   Haxe objects use garbage collection: do not `delete` the returned pointer.

Only one CHAOS instance is supported at a time because the engine uses shared
global state. Keep calls on the main UI thread. Retain long-lived Haxe objects
in GC-visible Haxe fields or registered GC roots, rather than only C++ heap
storage. Haxe exceptions cross the generated C++ interface as `Dynamic`;
catch them at the host boundary. Initialization errors are borrowed strings;
copy them if retained. Project command errors also use the engine's parser-failure
events. Shutdown does not tear down hxcpp itself: keep the shared library loaded
until process exit. A host using its own event loop must also service Haxe timers.

## Binary compatibility

This is the standard hxcpp C++ ABI, requiring the supplied generated headers and
`HxcppConfig.h`. It is not a compiler-independent C ABI. Build all Haxe/OpenFL
code for one host into this runtime; do not load another independent hxcpp runtime
and exchange its Haxe objects with this one.

The Linux x86_64 build uses Haxe 4.3.7, hxcpp 4.3.2 (API 430), OpenFL 9.5.2,
Lime 8.3.2, and GCC 13 on Linux Mint 22.3/glibc 2.39. Use a compatible GNU C++
toolchain and matching settings. Rebuild on an older Linux baseline when needed.
Allocate Haxe objects through exported generated constructors/factories.
Inline hxcpp allocator helpers such as `hx::Anon_obj::Create()`
reference private GC symbols and cannot be linked directly into the C++ host.
Ship `lime.ndll` beside `libchaos_runtime.so` and make `libchaos_runtime.so`
available to the dynamic loader (the example uses an executable-relative rpath).
The shared library itself also uses an origin-relative rpath to find Lime.
System graphics/audio libraries and drivers are required for desktop rendering.
Linux SDK output is platform-specific. The macOS script creates a separate dylib
SDK; Windows requires a separate DLL/import-library build and validation.
