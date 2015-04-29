#!/bin/bash

# when export srs-librtmp single files
# package the whole project to srs_librtmp.h and srs_librtmp.cpp
#
# params:
#     $SRS_OBJS_DIR the objs directory for Makefile. ie. objs
#     $SRS_EXPORT_LIBRTMP_SINGLE the export srs-librtmp single path. ie. srs-librtmp
#

# the target dir must created
if [[ ! -d $SRS_EXPORT_LIBRTMP_SINGLE ]]; then
    echo -e "${RED}error, target dir not created: $SRS_EXPORT_LIBRTMP_SINGLE${BLACK}"
    exit -1
fi

# generate the srs_librtmp.h
cp $SRS_EXPORT_LIBRTMP_SINGLE/src/libs/srs_librtmp.hpp $SRS_EXPORT_LIBRTMP_SINGLE/srs_librtmp.h

# create srs_librtmp.cpp
FILE=$SRS_EXPORT_LIBRTMP_SINGLE/srs_librtmp.cpp
cat << END >$FILE
/*
The MIT License (MIT)

Copyright (c) 2013-2015 SRS(simple-rtmp-server)

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "srs_librtmp.h"

END
# build objs auto files to cpp
cat $SRS_EXPORT_LIBRTMP_SINGLE/$SRS_OBJS_DIR/srs_auto_headers.hpp >>$FILE
ret=$?; if [[ $ret -ne 0 ]]; then 
    echo -e "${RED}failed to generate the srs_librtmp.cpp${BLACK}"
    exit $ret
fi
# module to cpp files.
function build_module_hpp()
{
    echo "build files ${SRS_LIBRTMP_OBJS} to $FILE"
    for item in ${SRS_LIBRTMP_OBJS[*]}; do
        FILE_NAME="${item%.*}"
        echo "// following is generated by ${FILE_NAME}.hpp" >> $FILE &&
        sed -i "s|#include <srs_|//#include <srs_|g" $SRS_EXPORT_LIBRTMP_SINGLE/${FILE_NAME}.hpp &&
        cat $SRS_EXPORT_LIBRTMP_SINGLE/${FILE_NAME}.hpp >>$FILE
        ret=$?; if [[ $ret -ne 0 ]]; then 
            echo -e "${RED}failed to generate the srs_librtmp.cpp by ${FILE_NAME}.hpp. {${BLACK}"
            exit $ret
        fi
    done
}
SRS_LIBRTMP_OBJS="${CORE_OBJS[@]}" && build_module_hpp
SRS_LIBRTMP_OBJS="${KERNEL_OBJS[@]}" && build_module_hpp
SRS_LIBRTMP_OBJS="${RTMP_OBJS[@]}" && build_module_hpp
SRS_LIBRTMP_OBJS="${LIBS_OBJS[@]}" && build_module_hpp
# module to cpp files.
function build_module_cpp()
{
    echo "build files ${SRS_LIBRTMP_OBJS} to $FILE"
    for item in ${SRS_LIBRTMP_OBJS[*]}; do
        FILE_NAME="${item%.*}"
        echo "// following is generated by ${FILE_NAME}.cpp" >> $FILE &&
        sed -i "s|#include <srs_|//#include <srs_|g" $SRS_EXPORT_LIBRTMP_SINGLE/${FILE_NAME}.cpp &&
        cat $SRS_EXPORT_LIBRTMP_SINGLE/${FILE_NAME}.cpp >>$FILE
        ret=$?; if [[ $ret -ne 0 ]]; then 
            echo -e "${RED}failed to generate the srs_librtmp.cpp by ${FILE_NAME}.cpp. {${BLACK}"
            exit $ret
        fi
    done
}
SRS_LIBRTMP_OBJS="${CORE_OBJS[@]}" && build_module_cpp
SRS_LIBRTMP_OBJS="${KERNEL_OBJS[@]}" && build_module_cpp
SRS_LIBRTMP_OBJS="${RTMP_OBJS[@]}" && build_module_cpp
SRS_LIBRTMP_OBJS="${LIBS_OBJS[@]}" && build_module_cpp

# create example.cpp
FILE=$SRS_EXPORT_LIBRTMP_SINGLE/example.c
SRS_SINGLE_LIBRTMP_COMPILE='gcc example.c srs_librtmp.cpp -g -O0 -lstdc++ -o example'
cat << END >$FILE
/**
# Example to use srs-librtmp
# see: https://github.com/simple-rtmp-server/srs/wiki/v2_CN_SrsLibrtmp
    ${SRS_SINGLE_LIBRTMP_COMPILE}
*/
#include <stdio.h>
#include "srs_librtmp.h"

int main(int argc, char** argv) 
{
    srs_rtmp_t rtmp;
    
    printf("Example for srs-librtmp\n");
    printf("SRS(simple-rtmp-server) client librtmp library.\n");
    printf("version: %d.%d.%d\n", srs_version_major(), srs_version_minor(), srs_version_revision());
    
    rtmp = srs_rtmp_create("rtmp://ossrs.net/live/livestream");
    srs_human_trace("create rtmp success");
    srs_rtmp_destroy(rtmp);
    
    return 0;
}

END

# compile the example
(cd $SRS_EXPORT_LIBRTMP_SINGLE && echo "${SRS_SINGLE_LIBRTMP_COMPILE}" && 
`${SRS_SINGLE_LIBRTMP_COMPILE}` && ./example && rm -f example)
ret=$?; if [[ $ret -ne 0 ]]; then 
    echo "(cd $SRS_EXPORT_LIBRTMP_SINGLE && ${SRS_SINGLE_LIBRTMP_COMPILE} && ./example && rm -f example)"
    echo -e "${RED}failed to compile example.${BLACK}"
    exit $ret
fi

# clear the files for srs-librtmp project, generated by generate-srs-librtmp-project.sh
(cd $SRS_EXPORT_LIBRTMP_SINGLE && rm -rf auto $SRS_OBJS_DIR research src Makefile)
