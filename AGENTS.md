# CHAOS Runtime

## Project

- This is the Haxe/OpenFL runtime. `Source/Main.hx` initializes the engine and its plugins; `project.xml` defines the application and build dependencies.
- Shared engine and UI sources live in `../_FRAMEWORK/CHAOS_ENGINE` and `../_FRAMEWORK/CHAOS_UI_HX`. Check applicable instructions there before editing those sources.
- Supported desktop platforms are Windows and Linux. Preserve HTML5 support alongside native targets.
- Keep changes focused and reuse existing runtime and framework code.

## Build targets

Maintain these delivery targets when implementing runtime changes:

- **HTML5:** build with `haxelib run lime build html5` from this repository root. Verify browser startup and affected behavior when relevant.
- **Native binary:** build with `haxelib run lime build windows` on Windows or `haxelib run lime build linux` on Linux. Verify startup and affected behavior on the corresponding platform. Linux validation may need to run on the separate Linux PC; report it as unverified when unavailable.
- **C++ developer library:** support a Windows DLL and the corresponding Linux `.so` shared library when library delivery is requested. Include public headers, a Windows import library where required, runtime dependencies, and a minimal C++ consumer example. Define initialization, shutdown, ownership, and error handling at the public API boundary. Keep compiler and ABI compatibility requirements documented.

The root `project.xml` configures application builds. The `DLL/` project inherits it and adds a C ABI for C++ hosts. Build with `node DLL/build.mjs windows` on Windows or `node DLL/build.mjs linux` on Linux; output is under `DLL/Export/<platform>/bin/`. Keep all assets in published packages and preserve the library filename because Windows import libraries depend on it. Verify library changes by building and running a C++ consumer using `DLL/examples/main.cpp`; check host continuation, working-directory restoration, and errors. The DLL runs once per process, owns its own window, and must not exit the host process.

Use the existing Haxe, Lime/OpenFL, and native toolchains. Build outputs belong under `Export/`; do not hand-edit generated files. Run checks appropriate to the change and report which targets were actually verified. Documentation-only changes do not require builds.

## Version policy

**Only update version numbers when the user explicitly asks.** This includes the application version in `project.xml`, package or release metadata, and version constants in source. Do not automatically bump versions for fixes, features, builds, DLL support, or documentation changes. When a version update is requested, change only the relevant version fields consistently.
