# [S]imple [M]ulti [L]anguage [P]rotocol - (SMLP)
### What is this?
A simple standard, made by me, which makes easier for you - **the user** - make and edit translations used by applications to better fit your needs, and, for you - **the developer** - to easily maintain a text file with a single attribute, which makes it the language you decide to support in your multi language application.

To accomplish this, I made a very simple library - of course in **assembly** - that anyone can learn and use it quickly.

The SMLP specification is also simple, and I think 5 lines will be more than enough to explain it to you (I wrote this before writing the spec below):

 - First 4 bytes (yes, bytes, not chars, because in UTF-8 they can span up to 4, or even 8 bytes for some emojis) is the **pattern**, which opens up a new string every time it occurs;
 - The rest, up to the next pattern bytes or to the end of file, is the **string** to be indexed and used by your aplication.

That's it. The whole specification is this two statements!
Sounds complicated? Well, bundled with this iron-proof library I've provided here, I've added an app called 'tester', which is kind of a Hello World program, but with multi language, by using 'libsmlproto.so.0' functions. I'm too lazy to add all languages, but you can do it and test it for yourself.

### The library 'libsmlproto.so' and its functions
There are, up to this "zeroth" version, only 5 functions that get this entire machinery to work fine enough:

```
extern bool SMLP_SetExtendedMode(bool enable);
```

```
extern char[] **SMLP_InitLanguage(char* path,
                                  char* prefix,
                                  char* suffix,
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
*I hope my 'C' language statements above doesn't hurt too much your eyes, like my english already does.*
*I don't program actively in C, so I only guess how it should be written. Sorry...*

I think the names and parameter names are quite self explainable, but if you think you need more details, for now, I have documented every function in (assembly) detail at the source. Also the example application has a good and well commented example of production usage. I'll soon do a proper documentation off source, one day. Maybe... '-'
(Does this simple thing really need one?)

### Installation
Just copy the provided binary to your system's library path, usually `/usr/lib/`, as **super user** (sudo, or doas).

To compile it from source, as well as the bundled example, you will need:

 - [fasm2](https://github.com/tgrysztar/fasm2 "flat assembler 2) assembler;
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
 
 The example application just get summoned with:
 ```
 > fasm2 tester.asm ../tester
 ```
 This already outputs the executable.
 

That's it. Go on and use it, I'm quite assured that you will like it (or even love it, and its simplified usage), too, just like I loved it after getting it alive in just 1 day, and refined within 2 days, from nothing to multi-language!
