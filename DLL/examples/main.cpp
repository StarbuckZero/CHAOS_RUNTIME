#include "chaos_runtime.h"
#include <cstdio>

int main(int argc, char** argv) {
    if (argc != 2) {
        std::fprintf(stderr, "Usage: chaos-example <absolute-export-directory>\n");
        return 2;
    }
    const int result = chaos_run(argv[1]);
    if (result) std::fprintf(stderr, "%s\n", chaos_last_error());
    std::puts("CHAOS returned control to the C++ host.");
    return result;
}
