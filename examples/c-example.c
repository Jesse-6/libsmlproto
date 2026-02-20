#include <stdio.h>
#include "../C/smlproto.h"

int main() {
    printf("--- SMLP Library Integration Example ---\n\n");

    /* 
     * Calling the Assembly function.
     * C will expect the pointers in RAX and RDX because of the SMLPResult struct.
     */
    SMLPResult result = SMLP_InitLanguage("./lang/C example", "c_", ".smlp", 8192);

    /* Check if the map (RAX) was successfully created */
    if (result.str_map == NULL) {
        fprintf(stderr, "Error: Failed to initialize language map.\n");
        return 1;
    }

    /* Accessing the RDX value (Selected Locale) */
    printf("Selected Locale: %s\n", result.sel_locale ? result.sel_locale : "None");

    /* Using other library functions */
    unsigned int count = SMLP_GetStringCount();
    printf("Total strings loaded: %u\n", count);

    if (count > 0) {
        printf("First string content: %s\n", SMLP_GetIndexedString(0));
    }

    /* Cleanup */
    if (SMLP_Cleanup(false)) {
        printf("\nResources cleaned up successfully.\n");
    }

    return 0;
}
