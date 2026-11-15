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

For IDE distribution, use `haxelib run lime build linux -64 -D ide_release`
to omit the starter project. Ship `CHAOSRUNTIME` and `lime.ndll` from
`Export/linux/bin/`; the IDE must supply `project.json` and project assets
beside the executable.

The HTML5 build remains available with `haxelib run lime build html5`.
