/* 
 * SMLP - Simple Multilingual Protocol Library
 * 100% assembly made for x86-64 System V ABI.
 * 
 * C-Interface Header
 * Contributed by: Google Gemini & Jesse-6
 */

#ifndef SMLP_PROTO_H
#define SMLP_PROTO_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <sys/types.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @struct SMLPResult
 * @brief Captures the dual-register return (RAX and RDX) as per System V ABI.
 * 
 * Under System V ABI, a 16-byte struct is returned via RAX (lower 8 bytes) 
 * and RDX (upper 8 bytes). This ensures C compatibility with the assembly 
 * implementation without data loss.
 */
typedef struct {
    char **str_map;    /* Mapped to RAX: Pointer to the string map array */
    char *sel_locale;  /* Mapped to RDX: Pointer to the validated/selected locale */
} SMLPResult;

/**
 * Enables or disables extended pattern mode.
 * @param enable Boolean flag to toggle the mode.
 * @return Returns the status of the operation.
 */
extern bool SMLP_SetExtendedMode(bool enable);

/**
 * Parses escaped character sequences in a string.
 * @param dest Destination buffer.
 * @param src Source string with escape sequences.
 * @return Number of characters processed.
 */
extern unsigned int SMLP_ParseEscapedString(char* dest, const char* src);

/**
 * Initializes the language mapping from files.
 * @param path Directory path for language files.
 * @param prefix Filename prefix (e.g., "lang_").
 * @param suffix Filename suffix (e.g., ".smlp").
 * @param sz_filelimit Maximum file size allowed for security.
 * @return An SMLPResult struct containing the string array (RAX) and the selected locale (RDX).
 */
extern SMLPResult SMLP_InitLanguage(const char* path,
                                    const char* prefix,
                                    const char* suffix,
                                    ssize_t sz_filelimit);

/**
 * Returns the total count of strings currently mapped in memory.
 */
extern unsigned int SMLP_GetStringCount(void);

/**
 * Retrieves a pointer to a specific string by its index.
 * @param str_n The index of the string.
 * @return Pointer to the string or NULL if out of bounds.
 */
extern char* SMLP_GetIndexedString(int str_n);

/**
 * Cleans up allocated resources.
 * @param will_reload Set to true if a subsequent re-initialization is planned.
 * @return Success status of the cleanup.
 */
extern bool SMLP_Cleanup(bool will_reload);

#ifdef __cplusplus
}
#endif

#endif /* SMLP_PROTO_H */
