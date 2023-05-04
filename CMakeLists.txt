cmake_minimum_required(VERSION 3.16)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake ${CMAKE_CURRENT_SOURCE_DIR}/scc/cmake)

project(TGFS-ISS VERSION 1.0.0 LANGUAGES CXX)

option(CODEGEN "enable generation of ISS code" ON)
set(CORE_NAME TGC_C CACHE STRING "The core to build the ISS for" )
set(WITH_LLVM FALSE CACHE BOOL "Build LLVM based backend")

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set(CMAKE_INSTALL_RPATH "${ORIGIN}")
include(CheckCXXCompilerFlag)
include(GNUInstallDirs)

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
if(BUILD_SHARED_LIBS)
	set(SHARED_FLAG "True")
else()
	set(SHARED_FLAG "False")
endif()

set(CONAN_BOOST_OPTIONS
boost:fPIC=True
boost:shared=${SHARED_FLAG}
boost:header_only=False 
boost:without_contract=True
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
boost:without_stacktrace=True
boost:without_test=True
boost:without_timer=True
boost:without_type_erasure=True
boost:without_wave=True
)

set(B2_VERSION 4.9.3)
set(CONAN_PACKAGE_LIST 
	fmt/8.0.1
	spdlog/1.9.2
	boost/1.75.0 
	gsl-lite/0.37.0 
	elfio/3.8 
	tcc/0.9.27 
	lz4/1.9.3 
	yaml-cpp/0.7.0 
	jsoncpp/1.9.5
)

set(CONAN_PACKAGE_OPTIONS fmt:header_only=True ${CONAN_BOOST_OPTIONS})
if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
     list(APPEND CONAN_PACKAGE_OPTIONS lua:compile_as_cpp=False)
     list(APPEND CONAN_PACKAGE_LIST tcc/0.9.27 seasocks/1.4.4 lua/5.4.3)
endif()
if(NOT USE_CWR_SYSTEMC AND NOT USE_NCSC_SYSTEMC AND NOT DEFINED ENV{SYSTEMC_HOME})
    set(CONAN_PACKAGE_LIST ${CONAN_PACKAGE_LIST}
        systemc/2.3.3
        systemc-cci/1.0.0
        )
    set(CONAN_PACKAGE_OPTIONS ${CONAN_PACKAGE_OPTIONS}  
        systemc:shared=${SHARED_FLAG}
        systemc-cci:shared=${SHARED_FLAG}
        )
endif()

conan_check()
conan_add_remote(NAME minres URL https://git.minres.com/api/packages/Tooling/conan)
# Boost on CentOS 7 quirks: the b2 of conan-center is build against a newer libstdc++ and therefore does not run
# with the oooooold libs on CentOS 7. Therefore we build our own version of b2 if it is not there
set(B2_META $ENV{HOME}/.conan/data/b2/${B2_VERSION}/_/_/metadata.json)
if(DEFINED ENV{CONAN_USER_HOME})
	set(B2_META $ENV{CONAN_USER_HOME}/.conan/data/b2/${B2_VERSION}/_/_/metadata.json)
endif()
if(NOT EXISTS ${B2_META})
	conan_configure(REQUIRES b2/${B2_VERSION})
	conan_cmake_autodetect(settings)
	conan_cmake_install(PATH_OR_REFERENCE . BUILD b2 SETTINGS ${settings})
endif()
# Boost on CentOS 7 quirks end
conan_cmake_configure(REQUIRES ${CONAN_PACKAGE_LIST}
                GENERATORS cmake_find_package
                OPTIONS ${CONAN_PACKAGE_OPTIONS}
                )
conan_cmake_autodetect(settings)
conan_install()
set(CONAN_CMAKE_SILENT_OUTPUT ON)               
find_package(tcc QUIET)
find_package(elfio)
find_package(fmt)
find_package(spdlog)
find_package(gsl-lite)

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

add_subdirectory(dbt-rise-core)
add_subdirectory(scc)
add_subdirectory(dbt-rise-tgc)

