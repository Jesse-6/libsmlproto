# [S]imple [M]ulti [L]anguage [P]rotocol - (SMLP)
### What is this?
A simple standard, made by me, which makes easier for you - **the user** - make and edit translations used by applications to better fit your needs, and, for you - **the developer** - to easily maintain a text file with a single attribute, which makes it the language you decide to support in your multi language application.

To accomplish this, I made a very simple library - of course in **assembly** - that anyone can learn and use it quickly.

The SMLP specification is also simple, and I think 5 lines will be more than enough to explain it to you (I wrote this before writing the spec below):

 - First 4 **bytes** (yes, bytes, not chars, because in UTF-8 they can span up to 4 bytes, or even 8 bytes for some emojis using multi byte UTF-8 char) is the **pattern**, which opens up a new string every time it occurs;
 - Remaining, up to the next pattern bytes or to the end of file, is the **string** to be indexed and used by your aplication.

That's it. The whole specification is this two statements!
Sounds complicated? Well, bundled with this iron-proof library I've provided here, I've added an app called 'tester', which is kind of a Hello World program, but with multi language, by using 'libsmlproto.so.0' functions. I'm too lazy to add all languages, but you can do it and test it for yourself.

### The library 'libsmlproto.so' and its functions
There are, up to this "zeroth" version, only 6 functions that get this entire machinery to work fine enough:

```
extern bool SMLP_SetExtendedMode(bool enable);
```

```
extern unsigned int SMLP_ParseEscapedString(char* dest,
                                            char* src);
```

```
typedef struct {
  char **str_map;
  char *sel_locale;
} SMLPResult;

extern SMLPResult SMLP_InitLanguage(const char* path,
                                  const char* prefix,
                                  const char* suffix,
                                  ssize_t sz_filelimit);
```

```
extern unsigned int SMLP_GetStringCount(void);
```

```
extern char* SMLP_GetIndexedString(int str_n);
```

```
extern bool SMLP_Cleanup(bool will_reload);
```
See the included header under 'C' folder for details. Also, there is a c-example file under example folder showing how to use it with C language.

The library works by initalizing and indexing strings off a language file, which shall have its name as follows:
```
  # relative path and filename:
  [path]/[prefix][locale][suffix]
  
  # absolute path and filename:
  [/folder1/folder2]/[prefix][locale][suffix]
  
  # filename at current application directory:
  [prefix][locale][suffix]
```
\[prefix\] and \[suffix\] are optional, also \[path\] is optional, and \[locale\] will be host's current locale, or any override made to the 'LANG=' environment variable.

Example:
```
    # For a host located in Brazil:
    # Path is 'lang'
    # Prefix is 'vp_'
    # Locale is 'pt_BR (or pt_BR.UTF-8)'
    # Suffix is '.txt'
    lang/vp_pt_BR.txt # <- resulting filename
```

One important concept regarding this library is: there's only 2 possible attributes inside its source text file: it is: **pattern**, or it is **string**. Do not use newline character to "organize" or "arrange" or "align" anything. Because newline, or tab, or whatever char (any byte of any value will be considered string if it does not  match pattern) will be part of your string! If you want to align something there, make newline or tab char part of the pattern. Then, it might work whenever pattern occurs, and you can visually benefit from the chosen character attribute as well.

I think the names and parameter names are quite self explainable, but if you think you need more details, for now, I have documented every function in (assembly) detail at the source. Also the example application has a good and well commented example of production usage. I'll soon do a proper documentation off source, one day. Maybe... '-'
(Does this simple thing really need one?)

### Installation
Just copy the provided binary to your system's library path, usually `/usr/lib/`, as **super user** (sudo, or doas).
Additionally, one may need to create a symbolic link to easily use it with C language:

```
> cd /usr/lib/
> sudo ln -s libsmlproto.so.0 libsmlproto.so
```

To compile it from source, as well as the bundled example, you will need:

 - [fasm2](https://github.com/tgrysztar/fasm2 "flat assembler 2") assembler;
 - [fastcall_v1](https://github.com/Jesse-6/fastcall_v1 "C style fastcall macro toolkit - for fasm2 assember") macro kit;
  - knowledge on how to do the following:
 
 From source path:
 ```
 > fasm2 libsmlproto.asm ../libsmlproto.o
 > ld -shared -o ../libsmlproto.so.0 ../libsmlproto.o -lc --gc-sections
 ```
 Install with:
 ```
 > cd ..
 > sudo cp -av libsmlproto.so.0 /usr/lib/
 ```
 
 The example assembly applications just get summoned with:
 ```
 > fasm2 tester.asm
 > fasm2 helloworld.asm
 ```
 This already outputs the executable.
 

That's it. Go on and use it, I'm quite assured that you will like it (or even love it, and its simplified usage) too, just like I loved it after getting it alive in just 1 day, and refined within 2 days, from nothing to multi-language!
