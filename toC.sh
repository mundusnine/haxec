#!/bin/bash 

command='ocamlc -output-complete-obj -o'
packages='-package threads -linkpkg socket.ml -package evalBytes.ml -linkpkg socket.ml -package ptmap -linkpkg globals.ml -package extlib -linkpkg hlcode.ml -package sedlex -linkpkg json.ml -package sedlex.ppx -linkpkg json.ml -package ppx_tools_versioned -linkpkg _ppx.ml -package xml-light -linkpkg genxml.ml'
solution="ocamlfind ocamlc -thread $packages -output-complete-obj -o haxe_embeded.c"
extension=.ml
extensions="$extension .mli"
path=$PWD
export OCAMLFIND_IGNORE_DUPS_IN=/home/jsnadeau/.opam/default/lib/ocaml/compiler-libs
cd ../haxe
make
cd $path
cp ../haxe/_build/default/src/core/defineList.ml .
cp ../haxe/_build/default/src/core/metaList.ml .
# rm -rf ../haxe/_build
for ext in $(echo $extensions | tr " " "\n")
    do
    for f in $(find ../haxe -name "*$ext");
        do 
        cp $f ./
    done
#  do echo "$f"
done
extensions="$extensions .cmi .cmo"
ocamldep options -native -sort -all -modules *.mli *.ml > .depend
depends=`cat .depend`
# echo $depends
for f in $(echo $depends | tr " " "\n")
    do
    # cName=''
    
    #     do 
    #     i=${i%"$extension"}
    #     i="$i.c"
    #     cName=$i
    # done
    s="$solution"
    if [ "ocamake.ml" != $f ] && [ "tests.ml" != $f ] && [ "test.ml" != $f ]
        then 
        echo $f
        s="$s $f"
    fi
    solution=$s
done
# Build
$solution

# Clean folder
for ext in $(echo $extensions | tr " " "\n")
    do
    for f in $(find . -name "*$ext");
        do
        rm $f
    done
done