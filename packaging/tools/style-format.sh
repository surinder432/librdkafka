#!/bin/bash
#
# Check or apply/fix the project coding style to all files passed as arguments.
#

set -e

ret=0

if [[ -z $1 ]]; then
    echo "Usage: $0 [--fix] srcfile1.c srcfile2.h srcfile3.c ..."
    echo ""
    exit 0
fi

if [[ $1 == "--fix" ]]; then
    fix=1
    shift
else
    fix=0
fi

function ignore {
    local file=${1//q./\.}

    grep -q "^$file$" .formatignore
}


for f in $*; do

    if ignore $f ; then
        echo "$f is ignored by .formatignore" 1>&2
        continue
    fi

    if [[ $f == *.cpp ]]; then
        style="Google"
    elif [[ $f == *.h && $(basename $f) == *cpp* ]]; then
        style="Google"
    else
        style="file"  # Use .clang-format
    fi

    if [[ $fix == 0 ]]; then
        # Check for tabs
        if grep -q $'\t' "$f" ; then
            echo "$f: contains tabs: convert to 8 spaces instead"
            ret=1
        fi

        # Check style
        if ! clang-format --style=$style --dry-run "$f" ; then
            echo "$f: had style errors ($style): see clang-format output above"
            ret=1
        fi

    else
        # Convert tabs to spaces first.
        sed -i -e 's/\t/        /g' "$f"

        # Run clang-format to reformat the file
        clang-format --style=$style "$f" > _styletmp

        if ! cmp -s "$f" _styletmp; then
            echo "$f: style fixed ($style)"
            mv _styletmp "$f"
        fi
    fi
done

rm -f _styletmp

if [[ $ret != 0 ]]; then
    echo "You can run the following command to automatically fix the style:"
    echo "  $ $0 --fix $*"
fi

exit $ret
