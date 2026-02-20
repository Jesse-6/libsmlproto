To proper compile the C example, an aditional step might be needed:

As super user, create a default link for the library:

------------------------------------------------
 $ cd /lib/
 $ sudo ln -s libsmlproto.so.0 libsmlproto.so
 
------------------------------------------------

This will create a link libsmlproto.so that resolves to the original libsmlproto.so.0 file.

And then, you will be able to compile the c-example.c using:

-------------------------------------------------
 > gcc -O3 c-example.c -o c-example -lsmlproto
-------------------------------------------------
