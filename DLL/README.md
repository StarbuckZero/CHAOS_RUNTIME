# CHAOS C++ runtime library

This library runs an exported CHAOS project in its own OpenFL window inside your
C++ process. It does not embed into an existing host window or expose Haxe classes.
Windows uses an x64 DLL and import library; Linux uses an x64 `.so`.

## Build

Use the same Haxe, hxcpp, OpenFL, Lime, Actuate, and desktop C++ toolchain as the
native runtime. From this directory run `node build.mjs windows` on Windows or
`node build.mjs linux` on Linux. Output follows `Export/<platform>/bin/` and includes
the library, Lime dependency, public header, import library (Windows), and example.
The version is inherited from `../project.xml`; builds do not change it.

The build macro suppresses OpenFL's automatic application startup and process exit.
`chaos_run` initializes Haxe and starts OpenFL explicitly. The shared engine retains
the package directory selected by the host instead of using the host EXE directory.

## Use a published project

Extract the complete IDE DLL export, including `project.json`, the editable layout,
theme, and `assets/`. Keep the library's filename unchanged: the Windows import
library records `CHAOSRUNTIME.dll`. Supply the absolute UTF-8 export directory to
`chaos_run`. No Firebase connection is required to load the extracted project assets.

From a Visual Studio x64 Native Tools prompt in the extracted export directory:

```bat
cl /EHsc /I include examples\main.cpp CHAOSRUNTIME.lib /Fe:chaos-example.exe
chaos-example.exe "D:\absolute\path\to\export"
```

On Linux, using a matching x64 toolchain and system dependencies for Lime/OpenFL:

```sh
g++ -I include examples/main.cpp -L. -lCHAOSRUNTIME -Wl,-rpath,'$ORIGIN' -o chaos-example
./chaos-example /absolute/path/to/export
```

Place the DLL and `lime.ndll` beside the host executable on Windows. On Linux keep
the shared library on the loader path and `lime.ndll` in the package directory.
The C ABI avoids exposing C++ standard library types across compiler boundaries;
host and library must still match OS and architecture. The Windows build uses MSVC
and the same runtime dependencies as the native CHAOS build.

## Lifetime and errors

- Call `chaos_run` once per process, on the main thread, outside `DllMain`. It owns
  initialization, its window, event loop, and shutdown when the window closes.
- It blocks until the window closes and returns control without exiting the host.
  Return code 0 means success; 1 means an error. On failure, copy the UTF-8 text
  returned by `chaos_last_error()` on the same thread. Do not free that pointer.
- Keep the library loaded until process exit; repeat initialization and unloading
  hxcpp/OpenFL inside a live process are not supported.
- Working directory changes to the export directory during the call and is restored
  on return, including errors. Coordinate other host threads that use relative paths.
- The host owns its input string; the library does not retain it after the call.
  Close the CHAOS window to stop the runtime. This API does not provide host-driven
  rendering, live command submission, or cross-thread UI control.

## Firebase delivery

Upload unpacked builds under `runtime/dll/<windows|linux>/x64/<version>/` using
Studio's `scripts/runtime-storage.mjs` with platform `dll-windows` or `dll-linux`.
In the IDE Publish dialog choose DLL, then the platform and runtime build. Every
project asset, including sprite source images, is included in DLL exports.
