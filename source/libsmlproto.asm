include 'libsmlproto.inc'

section '.text' executable

        ; Set internal bit flag, which change default (4 byte pattern) 
        ; behavior to 8 byte pattern behavior. This isn't recommended,
        ; as it is just a waste of extra space on language files
        ; (4 bytes extra per string). But it allows one to use extended
        ; emojis as the pattern (like country flags, or skin/gender altered
        ; emojis). They have 8 byte in length. Despite the advise, 
        ; performance will be the same regardless of any setting.
        ; 
        ; Parameter:
        ; dil = TRUE: enable 8 byte pattern;
        ;       FALSE: enable 4 byte pattern (default behavior)
        ;       Any other value lead to bit not being changed,
        ;       and function return 0.
        ;       
        ; Return: al = 1: change success; 0: no change
        ; 
        ; Note: this function does not lock, and it must be called 
        ; before SMLP_InitLanguage().
        SMLP_SetExtendedMode:
                        endbr64
                        cmp         dil, 1
                        ja          .no_change
                        test        dil, dil
                        js          .no_change
                        
                        mov         cl, [function_lock]
                        shl         dil, 7
                        and         cl, 01111111b
                        or          cl, dil
                        mov         [function_lock], cl
                        
                        mov         al, 1
                        ret
                        
            .no_change: mov         al, 0
                        ret
                        
                        
        ; Converts escape sequences within a given string to its corresponding byte values.
        ; This function came straight from my 'xecho' application, so it works exactly
        ; like that command. Here, it allows strings to have escape sequences, if needed.
        ; It also means that it needs a good optimization pass, because, there, it is just
        ; a proof of concept, written in a very 32-bit compatible way.
        ; 
        ; Parameters:
        ; rdi = destination buffer
        ; rsi = source string
        ; 
        ; Return: eax = number of escape sequences processed, or -1 if error
        ; 
        ; NOTE.1: This function must only be used after successfull language
        ; initialization by SMLP_InitLanguage()! It will always fail otherwise.
        ; 
        ; NOTE.2: Because escape sequences never expand to larger than escaped string,
        ; and also because this function is a read-modify-write sequence function, 
        ; source and destination can be the same buffer. It will never overrun.
        ; 
        SMLP_ParseEscapedString:
                        endbr64   ; rdi = destination buffer; rsi = source string
                        push        rbx
                        
                        test        [function_lock], FLAG_INIT_LOCK
                        jz          .enderr
                        
                        lea         rbx, [escapetable-20h]
                        mov         [escape_count], 0
                        
            .nextchar:  lodsb
                        test        al, al
                        jz          .endsuccess
                        cmp         al, '\'
                        je          .escape
                        stosb
                        jmp         .nextchar
                        
           .endsuccess: pop         rbx
                        stosb
                        mov         eax, [escape_count]
                        ret
                        
            .enderr:    mov         eax, -1
                        pop         rbx
                        ret
                        
            .escape:    lodsb
                        test        al, al
                        js          .ignoreescape
                        cmp         al, 20h
                        jb          .ignoreescape
                        inc         [escape_count]
                        xlatb
                        test        al, -1
                        jns         .store
                        cmp         al, 254
                        je          .octal
                        cmp         al, 253
                        je          .hex
                        cmp         al, 252
                        je          .utf16
                        cmp         al, 251
                        je          .utf32
                        
         .ignoreescape: mov         ax, [rsi-2]
                        dec         [escape_count]
                        stosw
                        jmp         .nextchar
                        
            .store:     stosb
                        jmp         .nextchar
                        
            .octal:     mov         eax, [rsi-1]
                        mov         ch, 1     ; Invalid octal flag before process
                        cmp         al, '0'
                        jb          .endoctal
                        cmp         al, '7'
                        ja          .endoctal
                        xor         ecx, ecx  ; Valid octal + cl = number of octal chars
                        sub         al, '0'
                        movzx       edx, al
                        inc         cl
                        shr         eax, 8
                        cmp         al, '0'
                        jb          .endoctal
                        cmp         al, '7'
                        ja          .endoctal
                        sub         al, '0'
                        shl         edx, 3
                        inc         cl
                        or          dl, al
                        shr         eax, 8
                        cmp         al, '0'
                        jb          .endoctal
                        cmp         al, '7'
                        ja          .endoctal
                        sub         al, '0'
                        shl         edx, 3
                        or          dl, al
                        inc         cl
                        
            .endoctal:  test        ch, ch
                        jnz         .ignoreescape
                        lea         rsi, [rsi+rcx-1]
                        mov         al, dl
                        stosb
                        jmp         .nextchar
                        
            .hex:       mov         dx, [rsi] ; supporting 2 char hex \xNN
                        mov         ch, 1     ; Set invalid flag before process
                        cmp         dx, '00'
                        jb          .endhex
                        cmp         dx, 'ff'
                        ja          .endhex
                        sub         dx, '00'
                        cmp         dl, 9
                        jbe         @f
                        sub         dl, 7
                        cmp         dl, 0Fh
                        jbe         @f
                        sub         dl, 20h
                        cmp         dl, 0Fh
                        ja          .endhex
                        cmp         dl, 0Ah
                        jb          .endhex
                        
                @@      cmp         dh, 9
                        jbe         @f
                        sub         dh, 7
                        cmp         dh, 0Fh
                        jbe         @f
                        
                        sub         dh, 20h
                        cmp         dh, 0Fh
                        ja          .endhex
                        cmp         dh, 0Ah
                        jb          .endhex
                        
                @@      xor         ch, ch    ; Valid hex escape
                        
            .endhex:    test        ch, ch
                        jnz         .ignoreescape
                        shl         dl, 4
                        or          dl, dh
                        mov         al, dl
                        stosb
                        add         rsi, 2
                        jmp         .nextchar
                        
            .utf16:     mov         edx, [rsi]
                        mov         ch, 1     ; set invalid
                        cmp         edx, '0000'
                        jb          .endu16
                        cmp         edx, 'ffff'
                        ja          .endu16
                        sub         edx, '0000'
                        mov         cl, 4
                        
                @@@     cmp         dl, 9
                        jbe         @f3
                        sub         dl, 7
                        cmp         dl, 0Ah
                        jb          .endu16
                        
                @@      cmp         dl, 0Fh
                        jbe         @f2
                        sub         dl, 20h
                        cmp         dl, 0Ah
                        jb          .endu16
                        
                @@      cmp         dl, 0Fh
                        ja          .endu16
                        test        dl, dl
                        js          .endu16
                        
                @@      ror         edx, 8
                        dec         cl
                        jnz         @@b
                        
                        bswap       edx
                        shl         dh, 4
                        or          dl, dh
                        ror         edx, 16
                        shl         dh, 4
                        or          dl, dh
                        ror         edx, 16
                        mov         eax, edx
                        ror         eax, 8
                        movzx       edx, dl
                        or          dh, ah
                        xor         ch, ch
                        call        .utf8enc
                        jc          .ignoreescape
                        
            .endu16:    test        ch, ch
                        jnz         .ignoreescape
                        
                        stosd
                        movzx       ecx, cl
                        sub         rcx, 4
                        add         rdi, rcx
                        add         rsi, 4
                        jmp         .nextchar
                        
            .utf32:     mov         edx, [rsi]
                        mov         eax, [rsi+4]
                        mov         ch, 1
                        
                        cmp         edx, '0000'
                        jb          .endu32
                        cmp         eax, '0000'
                        jb          .endu32
                        cmp         edx, 'ffff'
                        ja          .endu32
                        cmp         eax, 'ffff'
                        ja          .endu32
                        
                        bswap       eax
                        bswap       edx
                        sub         eax, '0000'
                        sub         edx, '0000'
                        mov         cl, 4
                        
                @@@     cmp         al, 9
                        jbe         @f3
                        sub         al, 7
                        cmp         al, 0Ah
                        jb          .endu32
                        
                @@      cmp         al, 0Fh
                        jbe         @f2
                        sub         al, 20h
                        cmp         al, 0Ah
                        jb          .endu32
                        
                @@      cmp         al, 0Fh
                        ja          .endu32
                        test        al, al
                        js          .endu32
                        
                @@      ror         eax, 8
                        cmp         dl, 9
                        jbe         @f3
                        sub         dl, 7
                        cmp         dl, 0Ah
                        jb          .endu32
                        
                @@      cmp         dl, 0Fh
                        jbe         @f2
                        sub         dl, 20h
                        cmp         dl, 0Ah
                        jb          .endu32
                        
                @@      cmp         dl, 0Fh
                        ja          .endu32
                        test        dl, dl
                        js          .endu32
                        
                @@      ror         edx, 8
                        dec         cl
                        jnz         @@b
                        push        rcx
                        push        rbx
                        shl         ah, 4
                        shl         dh, 4
                        or          al, ah
                        or          dl, dh
                        xor         ah, ah
                        xor         dh, dh
                        ror         eax, 16
                        ror         edx, 16
                        shl         ah, 4
                        shl         dh, 4
                        or          ah, al
                        or          dh, dl
                        xor         al, al
                        xor         dl, dl
                        mov         ebx, eax
                        mov         ecx, edx
                        ror         eax, 16
                        ror         edx, 16
                        or          ax, bx
                        or          dx, cx
                        movzx       eax, ax
                        shl         edx, 16
                        or          edx, eax
                        pop         rbx
                        pop         rcx
                        call        .utf8enc
                        jc          .endu32
                        xor         ch, ch
                        
            .endu32:    test        ch, ch
                        jnz         .ignoreescape
                        stosd
                        movzx       ecx, cl
                        sub         rcx, 4
                        add         rdi, rcx
                        add         rsi, 8
                        jmp         .nextchar
                        
            .utf8enc:   cmp         edx, 7Fh
                        ja          @f
                        mov         cl, 1          ; encoding length
                        mov         eax, edx       ; eax = UTF-8 bytes
                        clc
                        ret
                @@      cmp         edx, 7FFh
                        ja          @f
                        mov         cl, 2
                        mov         eax, 00000C080h
                        shl         dh, 2
                        or          ah, dh
                        mov         dh, dl
                        and         dx, 0C03Fh
                        shr         dh, 6
                        or          ax, dx
                        xchg        ah, al
                        clc
                        ret
                        
                @@      cmp         edx, 0FFFFh
                        ja          @f
                        mov         cl, 3
                        mov         eax, 00E08080h
                        push        rdx
                        and         dx, 0F3Fh
                        shl         dh, 2
                        or          ax, dx
                        pop         rdx
                        shr         dl, 6
                        shr         dh, 4
                        or          ah, dl
                        xor         dl, dl
                        shl         edx, 8
                        or          eax, edx
                        rol         eax, 8
                        bswap       eax
                        clc
                        ret
                        
                @@      cmp         edx, 10FFFFh   ; maximum UTF-32 code point
                        ja          .utf8err
                        mov         cl, 4
                        mov         eax, 0F0808080h
                        push        rdx       ; process xyz
                        and         dx, 0F3Fh
                        shl         dh, 2
                        or          ax, dx
                        mov         edx, [rsp]
                        shr         dl, 6
                        or          ah, dl
                        pop         rdx
                        shr         edx, 12   ; discard xyz, process uvw
                        push        rdx
                        and         dx, 013Fh
                        shl         dh, 2
                        ror         eax, 16
                        or          ax, dx
                        pop         rdx
                        shr         dl, 6
                        or          ah, dl
                        rol         eax, 16
                        bswap       eax
                        clc
                        ret
                        
            .utf8err:   stc
                        ret


        ; Loads and parses the strings using current locale in
        ; default mode. To use extended mode, call the above function
        ; before this.
        ;
        ; Parameters:
        ; 
        ; rdi = path to language files, NULL means current directory
        ; rsi = file prefix, NULL means no prefix
        ; rdx = file suffix, NULL means no suffix. This is usually 
        ;     the extension '.xxx', but it can be anything.
        ; rcx = file size limit: if NULL, file size limit is disabled
        ; 
        ; Resulting searched file name and path will be:
        ;   [path]/[prefix][language name][suffix]
        ;   
        ; Example:
        ;  rdi => "language"
        ;  rsi => "lang_"
        ;  rdx => ".lng"
        ;  ecx => any
        ;  Current language: pt_BR
        ; Search for: 'language/lang_pt_BR.lng'
        ; 
        ; If language file wasn't found, then the fallback will be:
        ;   'language/lang_C.lng'
        ; 
        ; In this case, the function will succeed, and rdx will contain
        ;    the fallback language name definition.
        ;    
        ; If the fallback language file wasn't found, after all, it will fail
        ; 
        ; Return: rax = pointer to array of indexed string pointers
        ;             = NULL if error
        ;         rdx = current selected language locale name
        SMLP_InitLanguage:
                        endbr64
                        push        rbp
                        mov         rbp, rsp
                        sub         rsp, 24
                        
                        push        rbx
                        push        r12
                        push        r13
                        push        r14
                        push        r15
                        
                        ; Lock this procedure to run once
                        test        [function_lock], 1
                        jnz         .err
                        
                        ; Save parameters at non-volatile registers
                        mov         r12, rdi            ; path
                        mov         r13, rsi            ; prefix
                        mov         r14, rdx            ; suffix
                        mov         [file_sz_max], rcx  ; size limit
                        
                        ; Gather LANG environment variable
                        ; which will be part of searched 
                        ; language definition filename
                        lea         rdi, [langenv]
                        call        plt.getenv
                        test        rax, rax
                        jz          .err
                        
                        ; Parse string to remove any
                        ; '.XXX' off string and store it
                        ; locally
                        lea         rdi, [locale]
                        mov         rsi, rax
                        mov         ecx, MAX_LOCALE_LEN
                @@      lodsb
                        test        al, al
                        jz          @f
                        cmp         al, '.'
                        je          @f2
                        stosb
                        dec         ecx     ; error if locale > MAX LEN
                        jz         .err
                        jmp         @b
                @@      stosb
                        jmp         @f2
                @@      xor         al, al
                        stosb
                        
                        ; Start parsing path
                @@      lea         r15, [locale]   ; save ro return later
                        mov         r10d, MAX_PATH  ; Total path counter
                        lea         rdi, [path]
            .path:      test        r12, r12
                        jz          .prefix
                        mov         ecx, MAX_PATH
                        mov         rsi, r12
                @@      lodsb
                        test        al, al
                        jz          @f
                        stosb
                        dec         ecx
                        jz          .err
                        dec         r10d
                        jz          .err
                        jmp         @b
                @@      mov         [rdi], al
                        cmp         [rdi-1], byte '/'
                        je          @f
                        mov         [rdi], word '/'
                        inc         rdi
                @@      
                        ; Start parsing and appending
                        ; prefix at the end of the path
            .prefix:    test        r13, r13
                        jz          .locale
                        mov         ecx, MAX_PREFIX
                        mov         rsi, r13
                @@      lodsb
                        test        al, al
                        jz          @f
                        stosb
                        dec         ecx
                        jz          .err
                        dec         r10d
                        jz          .err
                        jmp         @b
                @@      
                        ; Parse extracted locale name
            .locale:    lea         rsi, [locale]
                        mov         rbx, rdi    ; save to be used in fallback routine
                @@      lodsb
                        test        al, al
                        jz          @f
                        stosb
                        dec         r10d
                        jz          .err
                        jmp         @b
                @@      
            
            .suffix:    test        r14, r14
                        jz          @@f
                        mov         ecx, MAX_SUFFIX
                        mov         rsi, r14
                @@      lodsb
                        test        al, al
                        jz          @f
                        stosb
                        dec         ecx
                        jz          .err
                        dec         r10d
                        jz          .err
                        jmp         @b
                @@
                @@@     stosb
                
                        ; Try get file size information, to know
                        ; how much memory to allocate for the file
            .file_info: lea         rdi, [path]
                        lea         rsi, [fileprops]
                        call        plt.stat
                        test        eax, eax
                        jz          @@f
                        test        [function_lock], FLAG_EXTEND_PATTERN
                        
                        ; In case file doesn't exist, prepare fallback
                        ; filename and path begining at locale ptr
                        ; previously saved in rbx
            .fallback:  lea         rsi, [fallback_locale]
                        mov         rdi, rbx
                        movsw
                        test        r14, r14
                        jz          @f3
                        dec         rdi
                        mov         rsi, r14
                @@      lodsb
                        test        al, al
                        jz          @f
                        stosb
                        jmp         @b
                @@      stosb
                @@      lea         r15, [fallback_locale]  ; replace
                        
                        ; Try load information from fallback file
           .file2_info: lea         rdi, [path]
                        lea         rsi, [fileprops]
                        call        plt.stat
                        test        eax, eax
                        js          .err
                        
                        ; Check size limit if limit is specified
                        ; (non-NULL 4th parameter)
                @@@     mov         r12, [fileprops.size]
                        test        [file_sz_max], -1
                        jz          @f
                        cmp         r12, [file_sz_max]
                        ja          .err
                        
                @@      test        [function_lock], FLAG_EXTEND_PATTERN
                        mov         r11, MIN_FILE_SIZE
                        mov         r10, MIN_FILE_SIZE_EXT
                        cmovnz      r11, r10
                        cmp         r12, r11
                        jb          .err
                        
                        ; Allocate buffer for file contents
                @@      lea         rdi, [r12+4]    ; add 4 extra bytes to buffer
                        call        plt.malloc
                        test        rax, rax
                        jz          .err
                        mov         [p_file], rax
                        mov         [rax+r12], word 0FF00h  ; Append at end of buffer
                        
                        ; Allocate buffer for array of string pointers
                        lea         rdi, [r12*2+8]
                        shr         rdi, 3      ; number of elements {[(file * 2) + 8] / 8}
                        mov         esi, 8      ; size of element (qword)
                        call        plt.calloc  ; This size will be shrinked later
                        test        rax, rax
                        jz          .err
                        mov         [p_array], rax
                        
                        ; Open language file to read its contents
                        ; into *p_file buffer
                        lea         rdi, [path]
                        xor         esi, esi    ; O_RDONLY (read-only mode)
                        call        plt.open
                        test        eax, eax
                        js          .err
                        mov         [n_file], eax
                        
                        ; Read language file into allocated buffer
                        mov         rsi, [p_file]
                        mov         rdx, r12
                        mov         r14, r12    ; Save file size at r14
                        mov         edi, eax
                @@      call        plt.read
                        test        rax, rax
                        js          .err
                        sub         r12, rax
                        jz          @f
                        mov         rsi, [p_file]
                        lea         rsi, [rsi+rax]
                        mov         rdx, r12
                        mov         edi, [n_file]
                        jmp         @b
                        
                        ; Close file after its contents were read
                @@      mov         edi, [n_file]
                        call        plt.close
                        mov         [n_file], -1
                        
                        ; Start indexing strings, and pseudo counting them
                        mov         rsi, [p_file]
                        mov         rdx, [p_array]
                        xor         r10d, r10d
                        xor         ecx, ecx
                        
                        ; Check 4-byte/8-byte mode bit
                        test        [function_lock], FLAG_EXTEND_PATTERN
                        jnz         .mode8
                        
            .mode4:     lodsd                       ; Gather pattern (first 4 bytes)
                        mov         [rdx+rcx], rsi  ; Save first string pointer
                        mov         [rsi-4], r10d   ; replace pattern with NULL
                        sub         r14, 3
                        add         rcx, 8
                        lea         rdi, [rsi+3]
                @@      dec         r14
                        jz          @@f
                        lea         rdi, [rdi-3]    ;
                        scasd                       ; Search next pattern
                        jne         @b
                        mov         [rdx+rcx], rdi  ; Next string
                        add         rcx, 8
                        mov         [rdi-4], r10d
                        sub         r14, 3
                        jle         @@f
                        add         rdi, 3
                        jmp         @b
                        
            .mode8:     lodsq                       ; Same as mode4, but 8 byte
                        mov         [rdx+rcx], rsi
                        mov         [rsi-8], r10
                        sub         r14, 7
                        add         rcx, 8
                        lea         rdi, [rsi+7]
                @@      dec         r14
                        jz          @@f
                        lea         rdi, [rdi-7]
                        scasq
                        jne         @b
                        mov         [rdx+rcx], rdi
                        add         rcx, 8
                        mov         [rdi-8], r10
                        sub         r14, 7
                        jle         @@f
                        add         rdi, 7
                        jmp         @b
                        
                        ; Store parameters
                @@@     mov         [rdx+rcx], r10      ; Append null pointer at
                        shr         rcx, 3              ; the end of array
                        mov         [str_count], ecx    ; Number of entries
                        
                        ; Frees extra allocated space
                        ; for array, leaving only enough
                        ; for pointers + null pointer
                        mov         rdi, [p_array]
                        lea         esi, [ecx+1]
                        mov         edx, 8
                        call        plt.reallocarray
                        test        rax, rax
                        jz          .err
                        mov         [p_array], rax
                        mov         rdx, r15    ; return(2) selected locale
                        
                        mov         [function_lock], FLAG_INIT_LOCK
                        
            .end:       pop         r15
                        pop         r14
                        pop         r13
                        pop         r12
                        pop         rbx
                        leave
                        ret
                        
            .err:       test        [n_file], -1
                        js          @f
                        mov         edi, [n_file]
                        call        plt.close
                        
                @@      test        [p_array], -1
                        jz          @f
                        mov         rdi, [p_array]
                        call        plt.free
                        
                @@      test        [p_file], -1
                        jz          @f
                        mov         rdi, [p_file]
                        call        plt.free
                        
                @@      xor         eax, eax
                        jmp         .end
                        

        ; For the one who doesn't want to parse the returned array
        ; himself, there is this convenience function:
        ; 
        ; Parameter:
        ; edi = string index (beginning at index 0)
        ; 
        ; Return:  rax = pointer to string, or NULL if error
        ; 
        SMLP_GetIndexedString:
                        endbr64
                        test        [function_lock], 1
                        jz          .err
                        
                        cmp         edi, [str_count]
                        jae         .err
                        
                        mov         r8, [p_array]
                        mov         rax, [r8+rdi*8]
                        ret
                        
            .err:       xor         rax, rax
                        ret
                        
                        
        ; Another convenience function. But this one adds performance,
        ; because the library itself has already done counting
        ; strings.
        ; Parameters: none
        ; 
        ; Return:   rax = number of strings, or -1 if error
        ; 
        SMLP_GetStringCount:
                        endbr64
                        test        [function_lock], 1
                        jz          .err
                        
                        mov         eax, [str_count]
                        ret
                        
            .err:       mov         eax, -1
                        ret
                        
                        
        ; This function deallocates everything. It should be called
        ; on program exit, or when program no longer needs any data
        ; or memory used by this library.
        ; Parameter:
        ;  dil (boolean) : prepare for reload:
        ;    TRUE -> language will be reinitialized soon (unlock re-init);
        ;    FALSE -> program will terminate, just do a simple cleanup.
        ;
        ; Return: al = 1 success; al = 0 only it if called more than once.
        ;   Nothing is done on subsequent calls to this function.
        SMLP_Cleanup:   endbr64
                        push        rbx
                        mov         bl, dil
                        
                        test        [function_lock], 2
                        jnz         .err
                        test        [function_lock], 1
                        jz          .err
                        
                        test        [p_array], -1
                        jz          @f
                        mov         rdi, [p_array]
                        call        plt.free
                        
                @@      test        [p_file], -1
                        jz          @f
                        mov         rdi, [p_file]
                        call        plt.free
                        
                @@      test        bl, bl
                        jz          @f
                        xor         [function_lock], FLAG_BOTH_LOCK     ; also frees Init lock
                        jmp         .end
                @@      or          [function_lock], FLAG_CLEANUP_LOCK  ; lock this function
                        
            .end:       pop         rbx
                        mov         al, 1
                        ret
                        
            .err:       pop         rbx
                        xor         al, al
                        ret

