#!/bin/bash
##

# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=`readlink -f "$0"`
# Absolute path this script is in, thus /home/user/bin
SCRIPTDIR=`dirname "$SCRIPT"`
SCRIPTNAME=`basename "$SCRIPT"`
function print_help {
    echo "Usage: $SCRIPTNAME [-b <backend>] [-s <sim args>]}"
    echo "Run UCB risc-v compliance test suite on backends"
    echo "Optional cli arguments:"
    echo "  -b              backend type, default all"
    echo "  -s <args>       simulator arguments"
    echo "  -h              print help"
    echo "  -v              increase verbosity"
    echo "  -t             set build type"
}
SIM_ARGS="-v1"
BACKENDS=("interp" "tcc" "llvm")
DEBUG=0
BUILD_TYPE=Debug
while getopts 'b:s:hvt:' c
do
  case $c in
    b) BACKENDS=($OPTARG);;
    s) SIM_ARGS=$OPTARG ;;
    h) print_help; exit 0 ;;
    v) DEBUG=1 ;;
    t) BUILD_TYPE = $OPTARG;;
    ?)
      print_help >&2
      exit 1
      ;;
  esac
done

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIR=$DIR

RISCV_TEST=$ROOT_DIR/build/riscv-tests
# prepare riscv-test binaries
if [ ! -d $RISCV_TEST ]; then
    mkdir -p $ROOT_DIR/build; cd $ROOT_DIR/build
    git clone --recursive https://github.com/riscv/riscv-tests.git
    cd $RISCV_TEST
    autoconf
    ./configure --with-xlen=32
    cd $ROOT_DIR
    make -C $RISCV_TEST -j -k 
fi
# check that we have an executable
RISCV_EXE=$ROOT_DIR/build/${BUILD_TYPE}/dbt-rise-tgc/tgc-sim
if [ ! -x $RISCV_EXE ]; then
    mkdir -p build/${BUILD_TYPE}
    echo "running cmake -B build/${BUILD_TYPE} -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DWITH_TCC=ON -DWITH_LLVM=ON "
    cmake -S . -B build/${BUILD_TYPE} -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DWITH_TCC=ON -DWITH_LLVM=ON ../.. || exit 1
    cmake --build build/${BUILD_TYPE} -j 20 || exit 1
fi

test_ui_list=`find ${RISCV_TEST}/isa -type f -name rv32ui-p-\* -executable | grep -v fence | grep -v ma_data |sort`
test_uc_list=`find ${RISCV_TEST}/isa -type f -name rv32uc-p-\* -executable | grep -v fence | sort`
test_um_list=`find ${RISCV_TEST}/isa -type f -name rv32um-p-\* -executable | grep -v fence | sort`
test_list="$test_ui_list $test_uc_list $test_um_list $test_mmode_list"

for backend in "${BACKENDS[@]}"; do
    failed_list=()
    for elf in $test_list; do
    	[ $DEBUG -eq 0 ] || echo Running "${RISCV_EXE} $SIM_ARGS -f $elf --backend $backend"
        ${RISCV_EXE} $SIM_ARGS -f $elf --backend $backend
        if [ $? != 0 ]; then
            failed_list+="$backend:$elf "
        fi
    done
    tcount=`echo $test_list | wc -w`
    if [ ! -z "$failed_list" ]; then
        fcount=`echo $failed_list | wc -w`
        echo "($backend) $fcount of $tcount test(s) failed:" 
        echo $failed_list | tr ' ' '\n'
    else
        echo
        echo "($backend) All $tcount tests passed." 
        if [ $DEBUG -eq 1 ];then
        echo "List of executed tests:"
        for t in $test_list; do
            name=`basename $t`
            echo "  $name"
        done
        fi
    fi
done
