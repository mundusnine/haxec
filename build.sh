#!/bin/bash
# As of know the compilation works but the ocaml runtime fails because emscripten only compiles to wasm32 and the runtime needs 64 bit pointers
includes="-I$HOME/haxec/ocaml/otherlibs -I$HOME/haxec/ocaml/runtime -I$HOME/haxec/pcre -I$HOME/haxe/libs/objsize -I. -I$HOME/haxec/sha"

linkPaths="-L$HOME/haxec/pcre/.libs/libpcre.so -L$HOME/haxec/ocaml/runtime/libcamlrun.a -L$HOME/haxec/ocaml/otherlibs/unix/libunix.so -L$HOME/haxec/ocaml/otherlibs/systhreads/libthreads.so -L$HOME/haxec/sha/libsha1.so -L. -L--no-check-features"

afiles=''
path="$HOME/haxe/libs"
ofiles="$HOME/haxec/sha/sha1c.c $path/extc/process_stubs.c $path/pcre/pcre_stubs.c $path/extc/extc_stubs.c $path/objsize/c_objsize.c"

cargs='-lcamlrun_shared -lm -ldl -lthreads -lpthread -lunix -lpcre -lcamstr -lsha1'

outMain='   

int main (int argc, char ** argv)
{   
    printf("hello world !\n");
    caml_startup(argv) ;
    return 0 ;
}'
mainIncludes="#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>\n#include <emscripten.h>"
source ../emsdk/emsdk_env.sh

cd $HOME/haxec/ocaml #Ocaml 32 bit
./configure --build=i686-pc-linux-gnu
 make clean
 make world.opt


emconfigure ./configure
cd runtime
emmake make clean
cd ..
make runtime


#Build external stubs libs
cd $HOME/haxec/pcre
emconfigure ./configure
emmake make clean
emmake make

cd $HOME/haxec/sha
emcc -I. -I../ocaml/runtime -I$HOME/.opam/default/lib/ocaml sha1_stubs.c -o libsha1.so

#Build internal stubs libs
cd $HOME/haxec/ocaml/otherlibs/unix
emcc -O0 -I../../runtime -I. *.c -o libunix.so

cd $HOME/haxec/ocaml/otherlibs/systhreads
emcc -I../../runtime -I. st_stubs.c -o libthreads.so

cd $HOME/haxec/ocaml/otherlibs/str
emcc -I../../runtime  strstubs.c -o libcamstr.a

cur=$HOME/haxe
cd $HOME/haxe

rm -f haxe.html
rm -f haxe.js
rm -f haxe.wasm
rm -f haxe.worker.js
rm -f main_haxe.c

sed -i -e 's/HAXE_OUTPUT=haxe/HAXE_OUTPUT=haxe.bc.c/g' ./Makefile
sed -i -e 's/haxe.exe/haxe.bc.c/g' ./Makefile

make haxe

sed -i "1i$mainIncludes" ./haxe.bc.c
echo "$outMain" >> ./haxe.bc.c
mv ./haxe.bc.c ./main_haxe.c

source ../emsdk/emsdk_env.sh


for f in $(find $HOME/haxe/libs -name "Makefile");
    do
    cd ${f%"/Makefile"}
    emmake make
done

cd $cur

for f in $(find $HOME/haxe/libs -name "*.a");
    do
    afiles="$afiles $f"
    
done

wasmArgs='-s USE_ZLIB=1 -s FORCE_FILESYSTEM=1'

sofiles="$HOME/haxec/pcre/.libs/libpcre.so $HOME/haxec/ocaml/runtime/libcamlrun.a $HOME/haxec/ocaml/otherlibs/unix/libunix.so $HOME/haxec/ocaml/otherlibs/systhreads/libthreads.so $HOME/haxec/sha/libsha1.so"
emcc -g3 $includes $sofiles $ofiles main_haxe.c $linkPaths -o haxe.html $wasmArgs -s ERROR_ON_UNDEFINED_SYMBOLS=0 -s TOTAL_MEMORY=1024MB

echo haxe was built

for f in $(find $HOME/haxe/libs -name "Makefile");
    do
    cd ${f%"/Makefile"}
    make clean
done

cd $cur

for f in $(find . -maxdepth 2 -name "*.o");
    do
    rm $f
    
done

sed -i -e 's/HAXE_OUTPUT=haxe.bc.c/HAXE_OUTPUT=haxe/g' ./Makefile
sed -i -e 's/haxe.bc.c/haxe.exe/g' ./Makefile
