format ELF64 executable 3

include 'fastcall_v1.inc'
include 'stdmacros.inc'
include 'stdio.inc'

library 'libsmlproto.so.0'
ext proto SMLP_Cleanup, byte            ; returns byte size
ext proto SMLP_GetIndexedString, dword  ; returns qword size
ext proto SMLP_GetStringCount, none     ; returns dword size
ext proto SMLP_InitLanguage, qword, qword, qword, qword ; returns qword size
ext proto SMLP_SetExtendedMode, byte    ; return byte size

define STR_HELLO_WORLD      0
define STR_SUCCESS_MESSAGE  1
define STR_FAREWELL_MESSAGE 2
define STR_STRING_COUNT     3
define STR_LF               4


_code       ua_locale:          db 'uk_UA'
            Start entry:        endbr64

                                ; For the purpose of demonstration, I made ucranian 
                                ; language to be extended mode (in which the pattern
                                ; is the ucranian flag emoji, 8 bytes in length):
                                getenv("LANG");
                                mov         rdi, rax
                                lea         rsi, [ua_locale]
                                mov         ecx, 5
                                repe        cmpsb
                                jne         @f
                                SMLP_SetExtendedMode(TRUE);
                                test        al, al
                                jz          .err
                                
                                ; Initialize language, by loading its file (if exists),
                                ; or the default "C" as a fallback.
                                ; If neither can be found, the function returns 0.
                        @@      SMLP_InitLanguage("lang", NULL, ".txt", NULL);
                                test        rax, rax
                                jz          .err
                                mov         rbx, rax    ; save array pointer
                                
                                ; If SMLP_InitLanguage() succeds, rdx contains a
                                ; pointer to selected locale for translations:
                                fprintf(**stdout, <27,"[1;32mLOCALE = %s", \
                                    27,"[0m",10,10,0>, rdx);
                                
                                ; Get a pointer for the given index (if it exists
                                ; within current language file):
                                SMLP_GetIndexedString(STR_HELLO_WORLD);
                                test        rax, rax
                                jz          .err2
                                fputs(rax, **stdout);
                                
                                ; Next indexed string:
                                SMLP_GetIndexedString(STR_SUCCESS_MESSAGE);
                                test        rax, rax
                                jz          .err2
                                fputs(rax, **stdout);
                                
                                ; You can also parse manually the array of pointers
                                ; returned by SMLP_InitLanguage() function yourself.
                                ; The end of the array contains a NULL pointer.
                                mov         r15, -1
                                test        [rbx+(STR_FAREWELL_MESSAGE*8)], r15
                                jz          .err2
                                fputs([rbx+(STR_FAREWELL_MESSAGE*8)], **stdout);
                                
                                ; There is also SMLP_GetStringCount() function, 
                                ; which returns the number of indexed strings
                                ; on the array. Despite being a convenience
                                ; function, it is a performance function, 
                                ; because library has already counted the
                                ; strings, so you don't need to recurse counting
                                ; them again.
                                test        [rbx+(STR_STRING_COUNT*8)], r15
                                jz          .end
                                SMLP_GetStringCount();
                                fprintf(**stdout, [rbx+STR_STRING_COUNT*8], eax);
                                
                                ; File can also contains null strings or 
                                ; 1 byte strings; they're
                                ; indexed normally:
                                test        [rbx+STR_LF*8], r15
                                jz          .end
                                fputs([rbx+STR_LF*8], **stdout);
                                
                                ; To free allocated resources used to load 
                                ; language definitions, call this function to
                                ; release them.
                                SMLP_Cleanup(FALSE);
                                
                .end:           exit(0);
                                
                .err:           exit(1);
                
                .err2:          SMLP_Cleanup(FALSE);
                                exit(2);
                                
                
                                

