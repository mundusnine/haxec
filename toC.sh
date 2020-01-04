#!/bin/bash 

command='ocamlc -output-complete-obj -o'
packages=''
solution="ocamlfind ocamlc"
extension=.ml
extensions="$extension .mli .cma"
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
        if [ $f != ${f%".cma"} ] 
            then
            package=$f
        fi
        cp $f ./
    done
#  do echo "$f"
done

ocamldep options -native -sort -all -modules *.mli *.ml > .depend
depends=`cat .depend`
files=''
# echo $depends
for f in $(echo $depends | tr " " "\n")
    do
    # cName=''
    
    #     do 
    #     i=${i%"$extension"}
    #     i="$i.c"
    #     cName=$i
    # done
    s="$files"
    
    if [ "globals.ml" = $f ] 
        then packages="$packages -package ptmap -linkpkg globals.ml" 
    fi  
    if [ "png.mli" = $f ] 
        then packages="$packages  -package extlib -linkpkg hlcode.ml png.ml png.mli" 
    fi  
    if [ "json.ml" = $f ] 
        then packages="$packages -package sedlex -linkpkg json.ml -package sedlex.ppx -linkpkg json.ml" 
    fi  
    if [ "_ppx.ml" = $f ] 
        then packages="$packages -package ppx_tools_versioned -linkpkg _ppx.ml" 
    fi  
    if [ "socket.ml" = $f ] 
        then packages="-thread $packages -package threads -linkpkg socket.ml" 
    fi  
    if [ "genxml.ml" = $f ] 
        then packages="$packages -package xml-light -linkpkg genxml.ml" 
    fi  
    if [ "evalStdLib.ml" = $f ] 
        then packages="$packages -package sha -linkpkg evalStdLib.ml" 
    fi  

    if [ "ocamake.ml" != $f ] && [ "tests.ml" != $f ] && [ "test.ml" != $f ] && [ "example.ml" != $f ] && [ "main.ml" != $f ] && [ "dump.ml" != $f ] && [ "minizip.ml" != $f ]
        then
        echo $f
        $solution -thread $packages -c $s $f
        orig=$f
        mli=${orig%".mli"}
        f=${f%".ml"}
        if [ $f != $orig ]
            then
            f="$f.cmo"
            s="$s $f"
        fi
        # if [ $mli != $orig ]
        #     then
        #     f="$mli.cmi"
        # fi
        if [ $orig == "asdgajsdh.ml" ]
            then 
            exit
        fi
    fi
    files="$s"
done
# Build

echo $solution -I . -thread $packages -output-obj -o haxe_embeded.c $files

# Clean folder
for ext in $(echo $extensions | tr " " "\n")
    do
    for f in $(find . -name "*$ext");
        do
        rm $f
    done
done