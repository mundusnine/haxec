#!/bin/bash
# https://github.com/DigitalArsenal/openssl.js/blob/master/packages/openssl/build.sh
# @:Incomplete
# We should do something like they did to compile to wasm
includes="-I$HOME/.opam/default/lib/ocaml -I$HOME/haxe/libs/objsize -I."

linkPaths="-L$HOME/.opam/default/lib/ocaml -L$HOME/haxe/libs -L$HOME/.opam/default/lib/sha -L."

afiles=''
path="$HOME/haxe/libs"
ofiles="$path/extc/process_stubs.c $path/pcre/pcre_stubs.c $path/extc/extc_stubs.c $path/objsize/c_objsize.c"

cargs='-lcamlrun -lm -ldl -lncurses -lthreads -lpthread -lpcre -lz -lunix -lcamlstr -lsha1'

outMain='   
int main (int argc, char ** argv)
{   
    caml_startup(argv) ;
    return 0 ;
}'
mainIncludes="#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>"

sed -i -e 's/HAXE_OUTPUT=haxe/HAXE_OUTPUT=haxe.bc.c/g' ./Makefile
sed -i -e 's/haxe.exe/haxe.bc.c/g' ./Makefile

make

sed -i "1i$mainIncludes" ./haxe.bc.c
echo "$outMain" >> ./haxe.bc.c
mv ./haxe.bc.c ./main.c

cur=$PWD
for f in $(find $HOME/haxe/libs -name "Makefile");
    do
    cd ${f%"/Makefile"}
    make
done
cd $cur

for f in $(find $HOME/haxe/libs -name "*.a");
    do
    afiles="$afiles $f"
    
done

clang $includes main.c $ofiles $afiles $linkPaths -o haxe  $cargs
echo haxe was built

for f in $(find $HOME/haxe/libs -name "Makefile");
    do
    cd ${f%"/Makefile"}
    make clean
done

for f in $(find . -maxdepth 2 -name "*.o");
    do
    rm $f
    
done