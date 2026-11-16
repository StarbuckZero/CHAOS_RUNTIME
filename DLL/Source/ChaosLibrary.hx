import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;

@:keep
@:cppFileCode('
#include <atomic>
#include <string>
#include <exception>
#include <ChaosLibrary.h>

static std::atomic<bool> chaos_started(false);
static thread_local std::string chaos_error;

extern "C" EXPORT_EXTRA const char* chaos_last_error() {
    return chaos_error.c_str();
}

extern "C" EXPORT_EXTRA int chaos_run(const char* package_directory) {
    chaos_error.clear();
    if (!package_directory || !*package_directory) {
        chaos_error = "An absolute package directory is required.";
        return 1;
    }
    if (chaos_started.exchange(true)) {
        chaos_error = "CHAOS supports one run per host process. Keep the library loaded until process exit.";
        return 1;
    }
    HX_TOP_OF_STACK
    int result = 1;
    try {
        hx::Boot();
        __boot_all();
        ::ChaosLibrary_obj::run(::String(package_directory));
        result = 0;
    } catch (Dynamic error) {
        chaos_error = error == null() ? "Unknown CHAOS error" : error->toString().__CStr();
    } catch (const std::exception& error) {
        chaos_error = error.what();
    } catch (...) {
        chaos_error = "Unknown native CHAOS error";
    }
    hx::SetTopOfStack((int*)0, true);
    return result;
}
')
class ChaosLibrary {
    public static function run(directory:String):Void {
        if (!Path.isAbsolute(directory) || !FileSystem.exists(directory) || !FileSystem.isDirectory(directory))
            throw "Package directory must be an existing absolute directory.";
        var previous = Sys.getCwd();
        try {
            Sys.setCwd(directory);
            // Fail before creating a window if the exported project is missing or invalid.
            haxe.Json.parse(File.getContent("project.json"));
            ApplicationMain.create(null);
        } catch (error:Dynamic) {
            Sys.setCwd(previous);
            throw error;
        }
        Sys.setCwd(previous);
    }
}
