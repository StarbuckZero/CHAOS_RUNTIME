#ifndef CHAOS_RUNTIME_H
#define CHAOS_RUNTIME_H

#if defined(_WIN32)
#define CHAOS_API __declspec(dllimport)
#else
#define CHAOS_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* Call once, on the main thread, with the absolute UTF-8 package directory.
 * Owns a CHAOS window and blocks until it closes. Returns 0 on success, 1 on error.
 * Temporarily changes process working directory; restores it before returning.
 * Keep the library loaded until process exit. Never call from DllMain.
 */
CHAOS_API int chaos_run(const char* package_directory);

/* Borrowed UTF-8 message on the calling thread, valid until its next chaos_run.
 * Copy this string if it must outlive that call. No caller-owned buffers cross the ABI.
 */
CHAOS_API const char* chaos_last_error(void);

#ifdef __cplusplus
}
#endif
#endif
