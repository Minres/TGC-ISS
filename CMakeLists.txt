cmake_minimum_required(VERSION 3.20)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

project(TGC-ISS VERSION 1.0.0 LANGUAGES CXX)

set(WITH_LLVM FALSE CACHE BOOL "Build LLVM based backend")
if(CMAKE_PROJECT_NAME STREQUAL "TGC-ISS")
    ###########################################################################
    # stand alone build settings
    ###########################################################################
    set(CORE_NAME TGC5C CACHE STRING "The core to build the ISS for" )
    option(BUILD_COMMON_FW "Enable the automatic download and build of some firmware to run on the ISS" OFF)
    option(ENABLE_SANITIZER "Enable address sanitizer" OFF)
    option(ENABLE_GRPOF "Enable gprof instrumentation" OFF)
    option(ENABLE_CLANG_TIDY "Add clang-tidy and clang-format automatically to builds" OFF)
    option(WITH_TCC "Build TCC backend" OFF)
    option(WITH_LLVM "Build LLVM backend" OFF)
    option(WITH_ASMJIT "Build ASMJIT backend" ON)
    option(PORTABLE "Build executable without platform specific optimizations" OFF)

    set(CMAKE_CXX_STANDARD 14)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    set(CMAKE_CXX_EXTENSIONS OFF)
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
    set(CMAKE_INSTALL_RPATH "${ORIGIN}")
    include(CheckCXXCompilerFlag)
    CHECK_CXX_COMPILER_FLAG("-march=native" COMPILER_SUPPORTS_MARCH_NATIVE)
    if(COMPILER_SUPPORTS_MARCH_NATIVE AND NOT PORTABLE)
        message(STATUS "Applying platform specific optimizations")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=native")
    endif()
    
    if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU" OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
        set(warnings "-Wall -Wextra -Werror")
        set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")
        set(CMAKE_C_FLAGS_RELEASE "-O3 -DNDEBUG")
    elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
        set(warnings "/W4 /WX /EHsc")
    endif()
    if(ENABLE_SANITIZER)
        list(APPEND CMAKE_C_FLAGS             "-fsanitize=address")
        list(APPEND CMAKE_CXX_FLAGS           "-fsanitize=address")
        list(APPEND CMAKE_EXE_LINKER_FLAGS    "-fsanitize=address")
        list(APPEND CMAKE_SHARED_LINKER_FLAGS "-fsanitize=address")
    endif()
    if(ENABLE_GPROF)
    	list(APPEND CMAKE_C_FLAGS             "-pg")
    	list(APPEND CMAKE_CXX_FLAGS           "-pg")
		list(APPEND CMAKE_EXE_LINKER_FLAGS    "-pg")
		list(APPEND CMAKE_SHARED_LINKER_FLAGS "-pg")
    endif()
    include(GNUInstallDirs)
    include(ConanInline)
    if(BUILD_SHARED_LIBS)
        set(SHARED_FLAG "True")
    else()
        set(SHARED_FLAG "False")
    endif()
    
    set(CONAN_BOOST_OPTIONS
    boost:fPIC=True
    boost:shared=False
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
    
    set(B2_VERSION 4.9.6)
    set(CM_VERSION 3.20.5)
    set(LLVM_VERSION 13.0.0)
    set(CONAN_PACKAGE_LIST 
        fmt/8.0.1
        spdlog/1.9.2
        boost/1.75.0 
        gsl-lite/0.37.0 
        elfio/3.11 
        lz4/1.9.3 
        yaml-cpp/0.7.0 
        jsoncpp/1.9.5
        zlib/1.2.12
    )
    set(CONAN_PACKAGE_OPTIONS fmt:header_only=True ${CONAN_BOOST_OPTIONS})

    if(WITH_LLVM)
        list(APPEND CONAN_PACKAGE_LIST llvm-core/${LLVM_VERSION})
        list(APPEND CONAN_PACKAGE_OPTIONS libiconv:shared=True llvm-code:targets=X85)
    endif()
    if(WITH_ASMJIT)
        list(APPEND CONAN_PACKAGE_LIST asmjit/cci.20240531)
        list(APPEND CONAN_PACKAGE_OPTIONS asmjit:shared=False)
    endif()
    if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/dbt-rise-plugins)
         list(APPEND CONAN_PACKAGE_OPTIONS lua:compile_as_cpp=False)
         list(APPEND CONAN_PACKAGE_LIST lua/5.4.3)
    endif()

    conan_check()
    conan_add_remote(NAME minres URL https://git.minres.com/api/packages/Tooling/conan)
    ###########################################################################
    # Boost on CentOS 7 quirks: the b2 of conan-center is build against a newer libstdc++ and therefore does not run
    # with the oooooold libs on CentOS 7. Therefore we build our own version of b2 if it is not there
    ###########################################################################
    find_program(LSB_RELEASE_EXEC lsb_release)
    if(NOT LSB_RELEASE_EXEC-NOTFOUND)
        execute_process(COMMAND "${LSB_RELEASE_EXEC}" --short --id OUTPUT_VARIABLE LSB_RELEASE_ID_SHORT OUTPUT_STRIP_TRAILING_WHITESPACE)
	    if(LSB_RELEASE_ID_SHORT MATCHES "CentOS")
	        set(B2_META   $ENV{HOME}/.conan/data/b2/${B2_VERSION}/_/_/metadata.json)
	        set(CM_META   $ENV{HOME}/.conan/data/cmake/${CM_VERSION}/_/_/metadata.json)
	        set(LLVM_META $ENV{HOME}/.conan/data/llvm-core/${LLVM_VERSION}/_/_/metadata.json)
	        if(DEFINED ENV{CONAN_USER_HOME})
                set(B2_META    $ENV{CONAN_USER_HOME}/.conan/data/b2/${B2_VERSION}/_/_/metadata.json)
                set(CMAKE_META $ENV{CONAN_USER_HOME}/.conan/data/cmake/${CM_VERSION}/_/_/metadata.json)
	            set(LLVM_META  $ENV{CONAN_USER_HOME}/.conan/data/llvm-core/${LLVM_VERSION}/_/_/metadata.json)
            endif()
            if(NOT EXISTS ${B2_META})
                conan_configure(REQUIRES b2/${B2_VERSION})
                conan_cmake_autodetect(settings BUILD_TYPE Release)
                conan_cmake_install(PATH_OR_REFERENCE . BUILD b2 SETTINGS ${settings})
            endif()
            if(NOT EXISTS ${CM_META})
                conan_configure(REQUIRES cmake/${CM_VERSION})
                conan_cmake_autodetect(settings BUILD_TYPE Release)
                conan_cmake_install(PATH_OR_REFERENCE . BUILD cmake SETTINGS ${settings})
            endif()
            if(NOT EXISTS ${LLVM_META})
                conan_configure(REQUIRES llvm-core/13.0.0)
                conan_cmake_autodetect(settings BUILD_TYPE Release)
                conan_cmake_install(PATH_OR_REFERENCE . BUILD llvm-core SETTINGS ${settings})
            endif()
        endif()
    endif()
    ###########################################################################
    # Boost on CentOS 7 quirks end
    ###########################################################################
    conan_cmake_configure(REQUIRES ${CONAN_PACKAGE_LIST}
                          GENERATORS cmake_find_package
                          OPTIONS ${CONAN_PACKAGE_OPTIONS}
                          )
    conan_cmake_autodetect(settings)
    conan_install()
    set(CONAN_CMAKE_SILENT_OUTPUT ON)               
    
    find_package(fmt)
    find_package(spdlog)
    find_package(lz4)
    find_package(gsl-lite)
    find_package(yaml-cpp)
    set(Boost_NO_BOOST_CMAKE ON) #  Don't do a find_package in config mode before searching for a regular boost install.
    set(BOOST_ROOT ${CONAN_BOOST_ROOT})
    find_package(Threads)
    find_package(ZLIB)
    
    if(USE_CWR_SYSTEMC)
        include(SystemCPackage)
    endif()
    ###############################################################################
    # setup clang-format and clang-tidy
    ###############################################################################
    if (ENABLE_CLANG_TIDY)
        set(CLANG_FORMAT_EXCLUDE_PATTERNS "build" "install")
        find_package(ClangFormat)
        find_program (CLANG_TIDY_EXE NAMES "clang-tidy" PATHS /usr/bin )
        if (CLANG_TIDY_EXE)
            message(STATUS "clang-tidy found: ${CLANG_TIDY_EXE}")
            set(CLANG_TIDY_CHECKS "-*")
            set(CLANG_TIDY_CHECKS "${CLANG_TIDY_CHECKS},modernize-avoid-bind.PermissiveParameterList")
            set(CLANG_TIDY_CHECKS "${CLANG_TIDY_CHECKS},modernize-loop-convert.*")
            set(CLANG_TIDY_CHECKS "${CLANG_TIDY_CHECKS},modernize-make-shared.")
            set(CLANG_TIDY_CHECKS "${CLANG_TIDY_CHECKS},modernize-make-unique.")
            set(CLANG_TIDY_CHECKS "${CLANG_TIDY_CHECKS},modernize-pass-by-value.*")
            set(CLANG_TIDY_CHECKS "${CLANG_TIDY_CHECKS},modernize-raw-string-literal.*")
            set(CLANG_TIDY_CHECKS "${CLANG_TIDY_CHECKS},modernize-replace-auto-ptr.IncludeStyle")
            set(CLANG_TIDY_CHECKS "${CLANG_TIDY_CHECKS},modernize-replace-disallow-copy-and-assign-macro.MacroName")
            set(CLANG_TIDY_CHECKS "${CLANG_TIDY_CHECKS},modernize-replace-random-shuffle.IncludeStyle")
            set(CLANG_TIDY_CHECKS "${CLANG_TIDY_CHECKS},modernize-use-auto.*")
            set(CLANG_TIDY_CHECKS "${CLANG_TIDY_CHECKS},modernize-use-bool-literals.IgnoreMacros")
            set(CLANG_TIDY_CHECKS "${CLANG_TIDY_CHECKS},modernize-use-default-member-init.*")
            set(CLANG_TIDY_CHECKS "${CLANG_TIDY_CHECKS},modernize-use-emplace.*")
            set(CLANG_TIDY_CHECKS "${CLANG_TIDY_CHECKS},modernize-use-equals-default.IgnoreMacros")
            set(CLANG_TIDY_CHECKS "${CLANG_TIDY_CHECKS},modernize-use-equals-delete.IgnoreMacros")
            set(CLANG_TIDY_CHECKS "${CLANG_TIDY_CHECKS},modernize-use-nodiscard.ReplacementString")
            set(CLANG_TIDY_CHECKS "${CLANG_TIDY_CHECKS},modernize-use-noexcept.*")
            set(CLANG_TIDY_CHECKS "${CLANG_TIDY_CHECKS},modernize-use-nullptr.NullMacros")
            set(CLANG_TIDY_CHECKS "${CLANG_TIDY_CHECKS},modernize-use-override.*")
            set(CLANG_TIDY_CHECKS "${CLANG_TIDY_CHECKS},modernize-use-transparent-functors.SafeMode")
            set(CLANG_TIDY_CHECKS "${CLANG_TIDY_CHECKS},modernize-use-using.IgnoreMacros")
            set(CLANG_TIDY_CHECKS "${CLANG_TIDY_CHECKS},cppcoreguidelines-explicit-virtual-functions.IgnoreDestructors")
            #set(CLANG_TIDY_CHECKS "${CLANG_TIDY_CHECKS},cppcoreguidelines-*")
            set(CLANG_TIDY_CHECKS "${CLANG_TIDY_CHECKS},clang-diagnostic-*,clang-analyzer-*")
            set(DO_CLANG_TIDY "${CLANG_TIDY_EXE};-checks=${CLANG_TIDY_CHECKS};-header-filter='${CMAKE_SOURCE_DIR}/*';-fix"
                CACHE STRING "" FORCE)
        else()
            message(WARNING "clang-tidy not found!")
            set(CMAKE_CXX_CLANG_TIDY "" CACHE STRING "" FORCE) # delete it
        endif()
    endif()
    
    if(FW_BUILD)
        include(FetchContent)
        set(FETCHCONTENT_BASE_DIR ${CMAKE_CURRENT_BINARY_DIR}/..)
        FetchContent_Declare(
              riscvfw
              GIT_REPOSITORY https://git.minres.com/Firmware/Firmwares.git
              GIT_TAG        develop
              GIT_SHALLOW OFF
              UPDATE_DISCONNECTED ON
        )
        FetchContent_GetProperties(riscvfw)
        if(NOT riscvfw_POPULATED)
              FetchContent_Populate(riscvfw)
        endif()
         add_subdirectory(${riscvfw_SOURCE_DIR})
    endif()
endif()

add_subdirectory(dbt-rise-core)
add_subdirectory(dbt-rise-tgc)
if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/dbt-rise-plugins)
    add_subdirectory(dbt-rise-plugins)
endif()

include(CTest)
