format ELF64

include 'stdmacros.inc'

define O_RDONLY             0o      ; Read only mode for open();

define MAX_PATH             4096

define MAX_PREFIX           2048
define MAX_SUFFIX           2048
define MAX_FILENAME_LEN     3072
define MAX_LOCALE_LEN       16      ; More than enough space, I guess
define MIN_FILE_SIZE        5
define MIN_FILE_SIZE_EXT    9

define FLAG_INIT_LOCK       00000001b
define FLAG_CLEANUP_LOCK    00000010b
define FLAG_BOTH_LOCK       00000011b

define FLAG_EXTEND_PATTERN  10000000b   ; Change mode to operate on 8 byte pattern

struct STAT
    .dev        dq ?
    .ino        dq ?
    .nlink      dq ?
    .mode       dd ?
    .uid        dd ?
    .gid        dd ?
                dd ?
    .rdev       dq ?
    .size       dq ?
    .blksize    dq ?
    .blocks     dq ?
    .atim       TIMESPEC
    .mtim       TIMESPEC
    .ctim       TIMESPEC
                rq 3
end struct

struct TIMESPEC
    .sec        dq ?
    .nsec       dq ?
end struct

public SMLP_SetExtendedMode
public SMLP_InitLanguage
public SMLP_GetIndexedString
public SMLP_GetStringCount
public SMLP_Cleanup

extrn calloc
extrn close
extrn getenv
extrn free
extrn malloc
extrn open
extrn read
extrn reallocarray
extrn stat


section '.bss' writeable

        file_sz_max     dq ?            ; file size limit (4th parameter);
        path            rb MAX_PATH     ; This is actually C MAX_PATH size.
        fileprops       STAT
        str_count       dd ?
        locale          rb MAX_LOCALE_LEN   ; parsed locale
        
section '.data' writeable

        p_array         dq 0
        p_file          dq 0
        n_file          dd -1
        function_lock   db 2        ; Start with SMLP_Cleanup locked
        
section '.rdata'
        
        langenv         db 'LANG', 0
        fallback_locale dw 'C'

