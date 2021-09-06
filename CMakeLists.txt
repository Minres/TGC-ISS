cmake_minimum_required(VERSION 3.12)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake ${CMAKE_CURRENT_SOURCE_DIR}/scc/cmake)

project(TGFS-ISS VERSION 1.0.0 LANGUAGES CXX)

set(CORE_NAME TGC_C CACHE STRING "The core to build the ISS for" )
set(WITH_LLVM FALSE CACHE BOOL "Build LLVM based backend")

include(GNUInstallDirs)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
include(CheckCXXCompilerFlag)

CHECK_CXX_COMPILER_FLAG("-march=native" COMPILER_SUPPORTS_MARCH_NATIVE)
if(COMPILER_SUPPORTS_MARCH_NATIVE)
	if("${CMAKE_BUILD_TYPE}" STREQUAL "") 
	    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=native")
	elseif(NOT(${CMAKE_BUILD_TYPE} STREQUAL "RelWithDebInfo"))
	    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=native")
	endif()
endif()

if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU" OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    set(warnings "-Wall -Wextra -Werror")
    #set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_GLIBCXX_USE_CXX11_ABI=0")
    set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")
    set(CMAKE_C_FLAGS_RELEASE "-O3 -DNDEBUG")
elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
    set(warnings "/W4 /WX /EHsc")
endif()

include(ConanInline)
conan_check()
set(CONAN_BOOST_OPTIONS
boost:fPIC=True
boost:shared=True
boost:header_only=False 
boost:without_context=True
boost:without_contract=True
boost:without_coroutine=True
boost:without_fiber=True
boost:without_graph=True
boost:without_graph_parallel=True
boost:without_iostreams=True
boost:without_json=True
boost:without_locale=True
boost:without_log=True
boost:without_math=True
boost:without_mpi=True
boost:without_nowide=True
boost:without_python=True
boost:without_random=True
boost:without_regex=True
boost:without_serialization=True
boost:without_stacktrace=True
boost:without_test=True
boost:without_timer=True
boost:without_type_erasure=True
boost:without_wave=True
)
set(CONAN_PACKAGES fmt/6.1.2 zlib/1.2.11 boost/1.75.0 gsl-lite/0.37.0 elfio/3.8 tcc/0.9.27)
set(CONAN_SETTINGS fmt:header_only=True ${CONAN_BOOST_OPTIONS})
if(NOT DEFINED ENV{SYSTEMC_HOME})
    set(CONAN_PACKAGES ${CONAN_PACKAGES}
        systemc/2.3.3
        systemc-cci/1.0.0
        )
    set(CONAN_SETTINGS ${CONAN_SETTINGS}  
        #systemc:phase_cb=False
        systemc-cci:shared=False
        )
endif()
conan_configure(REQUIRES ${CONAN_PACKAGES}
                GENERATORS cmake_find_package
                OPTIONS ${CONAN_SETTINGS}
                )
conan_install()
conan_setup(TARGETS)
find_package(tcc)
find_package(elfio)
find_package(fmt)
find_package(gsl-lite)

# This line finds the boost lib and headers. 
set(Boost_NO_BOOST_CMAKE ON) #  Don't do a find_package in config mode before searching for a regular boost install.
set(BOOST_ROOT ${CONAN_BOOST_ROOT})
find_package(Threads)
find_package(ZLIB)

include(clang-format)
set(ENABLE_CLANG_TIDY OFF CACHE BOOL "Add clang-tidy automatically to builds")
if (ENABLE_CLANG_TIDY)
    find_program (CLANG_TIDY_EXE NAMES "clang-tidy" PATHS /usr/local/opt/llvm/bin )
    if (CLANG_TIDY_EXE)
        message(STATUS "clang-tidy found: ${CLANG_TIDY_EXE}")
        set(CLANG_TIDY_CHECKS "-*,modernize-*")
        set(CMAKE_CXX_CLANG_TIDY "${CLANG_TIDY_EXE};-checks=${CLANG_TIDY_CHECKS};-header-filter='${CMAKE_SOURCE_DIR}/*';-fix"
            CACHE STRING "" FORCE)
    else()
        message(AUTHOR_WARNING "clang-tidy not found!")
        set(CMAKE_CXX_CLANG_TIDY "" CACHE STRING "" FORCE) # delete it
    endif()
endif()

include(CodeGen)
gen_coredsl(${CORE_NAME} ${CMAKE_CURRENT_SOURCE_DIR}/tgfs/gen_input/${CORE_NAME}.core_desc interp)

add_subdirectory(dbt-core)
add_subdirectory(scc)
add_subdirectory(tgfs)

