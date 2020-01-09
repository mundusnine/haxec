#!/bin/bash
# https://github.com/DigitalArsenal/openssl.js/blob/master/packages/openssl/build.sh
# @:Incomplete
# We should do something like they did to compile to wasm
# emcc -I. -I../ocaml/runtime -I/home/jsnadeau/.opam/default/lib/ocaml sha1_stubs.c -o libsha1.so
includes="-I$HOME/haxec/ocaml/otherlibs -I$HOME/haxec/ocaml/runtime -I$HOME/haxec/pcre -I$HOME/haxe/libs/objsize -I. -I$HOME/haxec/sha"

linkPaths="-L$HOME/haxec/ocaml/runtime -L/home/jsnadeau/haxec/pcre/.libs -L$HOME/haxec/ocaml/otherlibs/unix -L$HOME/haxec/ocaml/otherlibs/str -L$HOME/haxec/ocaml/otherlibs/systhreads -L$HOME/haxe/libs -L$HOME/haxec/pcre -L$HOME/haxec/sha -L. -L--no-check-features"

afiles=''
path="$HOME/haxe/libs"
ofiles="$HOME/haxec/sha/sha1c.c $path/extc/process_stubs.c $path/pcre/pcre_stubs.c $path/extc/extc_stubs.c $path/objsize/c_objsize.c"

cargs='-lcamlrun_shared -lm -ldl -lthreads -lpthread -lunix -lpcre -lcamstr -lsha1'

outMain='   
int main (int argc, char ** argv)
{   
    caml_startup(argv) ;
    return 0 ;
}'
mainIncludes="#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>"

cur=$HOME/haxe
cd $HOME/haxe

rm -f haxe.html
rm -f haxe.js
rm -f haxe.wasm
rm -f haxe.worker.js
rm -f main.bc

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

cp /usr/include/pcre.h ./
wasmArgs='-s USE_ZLIB=1 -s FORCE_FILESYSTEM=1'

# emcc $includes $ofiles $linkPaths  -o main.bc  $cargs $wasmArgs  --no-check-feature
# emcc $includes  -o main.bc $wasmArgs
sofiles="$HOME/haxec/pcre/.libs/libpcre.so $HOME/haxec/ocaml/runtime/libcamlrun.a $HOME/haxec/ocaml/otherlibs/unix/libunix.so $HOME/haxec/ocaml/otherlibs/systhreads/libthreads.so $HOME/haxec/sha/libsha1.so"
emcc $includes $sofiles $ofiles main_haxe.c $linkPaths -o haxe.html $wasmArgs -s ERROR_ON_UNDEFINED_SYMBOLS=0

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
