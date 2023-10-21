cmake_minimum_required(VERSION 3.16)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/scc/cmake)

project(TGC-ISS VERSION 1.0.0 LANGUAGES CXX)

set(WITH_LLVM FALSE CACHE BOOL "Build LLVM based backend")
if(CMAKE_PROJECT_NAME STREQUAL "TGC-ISS")
	###########################################################################
	# stand alone build settings
	###########################################################################
	set(CORE_NAME TGC5C CACHE STRING "The core to build the ISS for" )
	option(FW_BUILD "Enable the automatic download and build of some firmware to run on the ISS" OFF)
	option(ENABLE_SANITIZER "Enable address sanitizer" OFF)
	
	set(CMAKE_CXX_STANDARD 14)
	set(CMAKE_CXX_STANDARD_REQUIRED ON)
	set(CMAKE_CXX_EXTENSIONS OFF)
	set(CMAKE_POSITION_INDEPENDENT_CODE ON)
	set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
	set(CMAKE_INSTALL_RPATH "${ORIGIN}")
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
	    set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")
	    set(CMAKE_C_FLAGS_RELEASE "-O3 -DNDEBUG")
	elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
	    set(warnings "/W4 /WX /EHsc")
	endif()
	if(ENABLE_SANITIZER)
		set(CMAKE_C_FLAGS             "${CMAKE_C_FLAGS} -fsanitize=address")
		set(CMAKE_CXX_FLAGS           "${CMAKE_CXX_FLAGS} -fsanitize=address")
		set(CMAKE_EXE_LINKER_FLAGS    "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=address")
		set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -fsanitize=address")
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
	
	set(B2_VERSION 4.9.6)
	set(CM_VERSION 3.20.5)
	set(CONAN_PACKAGE_LIST 
		fmt/8.0.1
		spdlog/1.9.2
		boost/1.75.0 
		gsl-lite/0.37.0 
		elfio/3.8 
		lz4/1.9.3 
		yaml-cpp/0.7.0 
		jsoncpp/1.9.5
		zlib/1.2.13
	)
	set(CONAN_PACKAGE_OPTIONS fmt:header_only=True ${CONAN_BOOST_OPTIONS})

	if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
	    list(APPEND CONAN_PACKAGE_LIST tcc/0.9.27)
		option(WITH_TCC "Build TCC backend" ON)
	endif()

	if(WITH_LLVM)
	    list(APPEND CONAN_PACKAGE_LIST llvm-core/13.0.0)
		list(APPEND CONAN_PACKAGE_OPTIONS libiconv:shared=True)
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
	set(B2_META $ENV{HOME}/.conan/data/b2/${B2_VERSION}/_/_/metadata.json)
	set(CM_META $ENV{HOME}/.conan/data/cmake/${CM_VERSION}/_/_/metadata.json)
	if(DEFINED ENV{CONAN_USER_HOME})
		set(B2_META $ENV{CONAN_USER_HOME}/.conan/data/b2/${B2_VERSION}/_/_/metadata.json)
		set(CMAKE_META $ENV{CONAN_USER_HOME}/.conan/data/cmake/${CM_VERSION}/_/_/metadata.json)
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
	if(FW_BUILD)
		include(FetchContent)
		set(FETCHCONTENT_BASE_DIR ${CMAKE_CURRENT_BINARY_DIR}/..)
		FetchContent_Declare(
		  	riscvfw
		  	GIT_REPOSITORY https://git.minres.com/VP/Firmwares.git
		  	GIT_TAG        main
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
add_subdirectory(scc)
add_subdirectory(dbt-rise-tgc)
if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/dbt-rise-plugins)
	add_subdirectory(dbt-rise-plugins)
endif()


include(CTest)
