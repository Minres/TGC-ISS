# TGC-ISS

The ISS for the cores of The Good Folk Series (TGFS) of MINRES.

This ISS is based in DBT-RISE, a library to allow rapid ISS creation.

## Quick start

* you need to have a C++14 capable compiler, make or ninja, python, and cmake installed
 
### common setup

* install conan.io (see also http://docs.conan.io/en/latest/installation.html):
  
  ```

  pip3 install --user conan==1.59

  ```
  
  Another option is to use a Python VENV to isolate the used models from the system.
  In case of please run:
  
  ```sh

  python -mvenv .venv
  source .venv/bin/activate
  pip3 install conan==1.59

  ``` 
  
  Using conan for the first time you need to create a profile:
  
  ```
  
  conan profile create default --detect
  
  ```
  
* checkout source from git

  ```sh

  git clone --recursive -b develop https://git.minres.com/TGFS/TGC-ISS.git

  ``` 

### Accellera SystemC build

* start an out-of-source build:
  
  ```

  cd TGC-ISS
  cmake -S . -B build/Debug
  cmake --build build/Debug -j10

  ```
  

### Synopsys Platform Architect build

Assuming environment for Platform Architect is properly set up.

```

  cd TGC-ISS/
  export TGFS_INSTALL_ROOT `pwd`/install
  export SNPS_ENABLE_MEM_ON_DEMAND_IN_GENERIC_MEM=1
  export CC=$COWAREHOME/SLS/linux/common/bin/gcc
  export CXX=$COWAREHOME/SLS/linux/common/bin/g++
  cmake -S . -B build/PA -DCMAKE_BUILD_TYPE=Debug -DUSE_CWR_SYSTEMC=ON \
    -DBUILD_SHARED_LIBS=ON -DCODEGEN=OFF -DCMAKE_INSTALL_PREFIX=${TGFS_INSTALL_ROOT}
  cmake --build build/PA --target install -j16

```

Now you may change to dbt-rise-tgc/contrib to import the core model