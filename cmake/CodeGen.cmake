cmake_minimum_required(VERSION 3.11)
option(ENABLE_CODEGEN "Enable code generation for supported cores" ON)

set(ROOT_DIR ${CMAKE_CURRENT_LIST_DIR}/..)
set(DBT_CORE_TGC_DIR ${ROOT_DIR}/tgfs)

#helper to setup code generation and generate outputs
set(GENERATOR_JAR ${ROOT_DIR}/coredsl/com.minres.coredsl.generator.repository/target/com.minres.coredsl.generator-2.0.0-SNAPSHOT.jar)

if(EXISTS ${ROOT_DIR}/coredsl/pom.xml AND NOT EXISTS ${GENERATOR_JAR})
   execute_process(
   		COMMAND mvn package
   		WORKING_DIRECTORY ${ROOT_DIR}/coredsl
	    RESULT_VARIABLE return_code)
endif()

set(JAVA_OPTS --add-modules ALL-SYSTEM --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED
  --add-opens=java.base/java.lang.annotation=ALL-UNNAMED --add-opens=java.base/java.lang.invoke=ALL-UNNAMED 
  --add-opens=java.base/java.lang.module=ALL-UNNAMED --add-opens=java.base/java.lang.ref=ALL-UNNAMED 
  --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.math=ALL-UNNAMED 
  --add-opens=java.base/java.net=ALL-UNNAMED --add-opens=java.base/java.net.spi=ALL-UNNAMED 
  --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/java.nio.channels=ALL-UNNAMED 
  --add-opens=java.base/java.nio.channels.spi=ALL-UNNAMED --add-opens=java.base/java.nio.charset=ALL-UNNAMED 
  --add-opens=java.base/java.nio.charset.spi=ALL-UNNAMED --add-opens=java.base/java.nio.file=ALL-UNNAMED 
  --add-opens=java.base/java.nio.file.attribute=ALL-UNNAMED --add-opens=java.base/java.nio.file.spi=ALL-UNNAMED 
  --add-opens=java.base/java.security=ALL-UNNAMED --add-opens=java.base/java.security.acl=ALL-UNNAMED 
  --add-opens=java.base/java.security.cert=ALL-UNNAMED --add-opens=java.base/java.security.interfaces=ALL-UNNAMED 
  --add-opens=java.base/java.security.spec=ALL-UNNAMED --add-opens=java.base/java.text=ALL-UNNAMED 
  --add-opens=java.base/java.text.spi=ALL-UNNAMED --add-opens=java.base/java.time=ALL-UNNAMED 
  --add-opens=java.base/java.time.chrono=ALL-UNNAMED --add-opens=java.base/java.time.format=ALL-UNNAMED 
  --add-opens=java.base/java.time.temporal=ALL-UNNAMED --add-opens=java.base/java.time.zone=ALL-UNNAMED 
  --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.util.concurrent=ALL-UNNAMED
  --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.locks=ALL-UNNAMED 
  --add-opens=java.base/java.util.function=ALL-UNNAMED --add-opens=java.base/java.util.jar=ALL-UNNAMED 
  --add-opens=java.base/java.util.regex=ALL-UNNAMED --add-opens=java.base/java.util.spi=ALL-UNNAMED 
  --add-opens=java.base/java.util.stream=ALL-UNNAMED --add-opens=java.base/java.util.zip=ALL-UNNAMED 
  --add-opens=java.datatransfer/java.awt.datatransfer=ALL-UNNAMED --add-opens=java.desktop/java.applet=ALL-UNNAMED 
  --add-opens=java.desktop/java.awt=ALL-UNNAMED --add-opens=java.desktop/java.awt.color=ALL-UNNAMED 
  --add-opens=java.desktop/java.awt.desktop=ALL-UNNAMED --add-opens=java.desktop/java.awt.dnd=ALL-UNNAMED 
  --add-opens=java.desktop/java.awt.dnd.peer=ALL-UNNAMED --add-opens=java.desktop/java.awt.event=ALL-UNNAMED 
  --add-opens=java.desktop/java.awt.font=ALL-UNNAMED --add-opens=java.desktop/java.awt.geom=ALL-UNNAMED 
  --add-opens=java.desktop/java.awt.im=ALL-UNNAMED --add-opens=java.desktop/java.awt.im.spi=ALL-UNNAMED 
  --add-opens=java.desktop/java.awt.image=ALL-UNNAMED --add-opens=java.desktop/java.awt.image.renderable=ALL-UNNAMED 
  --add-opens=java.desktop/java.awt.peer=ALL-UNNAMED --add-opens=java.desktop/java.awt.print=ALL-UNNAMED 
  --add-opens=java.desktop/java.beans=ALL-UNNAMED --add-opens=java.desktop/java.beans.beancontext=ALL-UNNAMED 
  --add-opens=java.instrument/java.lang.instrument=ALL-UNNAMED --add-opens=java.logging/java.util.logging=ALL-UNNAMED 
  --add-opens=java.management/java.lang.management=ALL-UNNAMED --add-opens=java.prefs/java.util.prefs=ALL-UNNAMED 
  --add-opens=java.rmi/java.rmi=ALL-UNNAMED --add-opens=java.rmi/java.rmi.activation=ALL-UNNAMED 
  --add-opens=java.rmi/java.rmi.dgc=ALL-UNNAMED --add-opens=java.rmi/java.rmi.registry=ALL-UNNAMED 
  --add-opens=java.rmi/java.rmi.server=ALL-UNNAMED --add-opens=java.sql/java.sql=ALL-UNNAMED)
set(GENERATOR java ${JAVA_OPTS} -jar ${GENERATOR_JAR})

set(INPUT_DIR ${DBT_CORE_TGC_DIR}/gen_input)
set(REPO_DIR ${DBT_CORE_TGC_DIR}/gen_input/CoreDSL-Instruction-Set-Description)
set(TMPL_DIR ${DBT_CORE_TGC_DIR}/gen_input/templates/)

if(ENABLE_CODEGEN AND EXISTS ${GENERATOR_JAR})
    	macro(gen_coredsl CORE_NAME INPUT_FILE BACKEND)
            message(STATUS "Adding generation steps for ${CORE_NAME} in ${DBT_CORE_TGC_DIR} for ${BACKEND}")
            
    		string(TOUPPER ${BACKEND} BE_UPPER)
    		string(TOLOWER ${CORE_NAME} CORE_NAMEL)

            if(EXISTS ${DBT_CORE_TGC_DIR}/generate.sh AND NOT EXISTS ${DBT_CORE_TGC_DIR}/incl/iss/arch/${CORE_NAMEL}.h)
                # make sure source file exist initially 
                execute_process(
                    COMMAND /bin/bash ${DBT_CORE_TGC_DIR}/../generate.sh $CORE_NAME $BACKEND
                    WORKING_DIRECTORY ${DBT_CORE_TGC_DIR}/..
                    RESULT_VARIABLE return_code)
            endif()

    		list(APPEND ${CORE_NAME}_MAPPING -m "${TMPL_DIR}/CORENAME.h.gtl:${DBT_CORE_TGC_DIR}/incl/iss/arch/${CORE_NAMEL}.h")
    		list(APPEND ${CORE_NAME}_MAPPING -m "${TMPL_DIR}/CORENAME.cpp.gtl:${DBT_CORE_TGC_DIR}/src/iss/${CORE_NAMEL}.cpp")
    		list(APPEND ${CORE_NAME}_MAPPING -m "${TMPL_DIR}/${BACKEND}/CORENAME.cpp.gtl:${DBT_CORE_TGC_DIR}/src/vm/interp/vm_${CORE_NAMEL}.cpp")
    		set(${CORE_NAME}_OUTPUT_FILES ${DBT_CORE_TGC_DIR}/incl/iss/arch/${CORE_NAMEL}.h ${DBT_CORE_TGC_DIR}/src/iss/${CORE_NAMEL}.cpp ${DBT_CORE_TGC_DIR}/src/vm/interp/vm_${CORE_NAMEL}.cpp)
    		add_custom_command(
    		    COMMAND ${GENERATOR} -b ${BE_UPPER} -c ${CORE_NAME} -r ${REPO_DIR} ${${CORE_NAME}_MAPPING} ${INPUT_FILE}
    		    DEPENDS ${GENERATOR_JAR} ${INPUT_FILE} ${TMPL_DIR}/CORENAME.h.gtl ${TMPL_DIR}/CORENAME.cpp.gtl ${TMPL_DIR}/${BACKEND}/CORENAME.cpp.gtl
    		    OUTPUT ${${CORE_NAME}_OUTPUT_FILES}
    		    COMMENT "Generating code for ${CORE_NAME}."
    		    USES_TERMINAL VERBATIM
    		)    		
    		add_custom_target(${CORE_NAME}_src DEPENDS ${${CORE_NAME}_OUTPUT_FILES})
    	endmacro()
else()
	macro(gen_coredsl CORE_NAME INPUT_FILE BACKEND)
		add_custom_target(${CORE_NAME}_src)
        message(STATUS "Not adding generation steps for ${CORE_NAME}(${ENABLE_CODEGEN}, ${GENERATOR_JAR})")
	endmacro()
endif()
