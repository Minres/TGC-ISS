export TGFS_INSTALL_ROOT=`pwd`/install
module load tools/pa/T-2022.06
module load tools/cmake
export SNPS_ENABLE_MEM_ON_DEMAND_IN_GENERIC_MEM=1
export CC=$COWAREHOME/common/bin/gcc
export CXX=$COWAREHOME/common/bin/g++
cmake -S . -B build/PA -DCMAKE_BUILD_TYPE=Debug -DUSE_CWR_SYSTEMC=ON -DBUILD_SHARED_LIBS=ON \
    -DCODEGEN=OFF -DCMAKE_INSTALL_PREFIX=${TGFS_INSTALL_ROOT}
cmake --build build/PA --target install -j16
#cd dbt-rise-tgc/contrib
# import the TGC core itself
#pct tgc_import.tcl

