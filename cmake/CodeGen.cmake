set(ENABLE_CODEGEN "Enable code generation for supported cores" ON)

#helper to setup code generation and generate outputs
set(GENERATOR_JAR ${CMAKE_CURRENT_SOURCE_DIR}/coredsl/plugins/com.minres.coredsl.generator.standalone/target/com.minres.coredsl.generator-1.0.0-SNAPSHOT.jar)

if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/coredsl/plugins AND NOT EXISTS ${GENERATOR_JAR})
   execute_process(
   		COMMAND mvn package
   		WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/coredsl
	    RESULT_VARIABLE return_code)
endif()

if(ENABLE_CODEGEN AND EXISTS ${GENERATOR_JAR})
	macro(gen_coredsl CORE_NAME INPUT_FILE BACKEND)
	
		#set(CORE_NAME TGF_C)
		#set(BACKEND interp)
		#set(INPUT_FILE TGFS.core_desc)
		
		set(TGFS ${CMAKE_CURRENT_SOURCE_DIR}/tgfs)
		set(INPUT_DIR ${TGFS}/gen_input)
		set(REPO_DIR ${TGFS}/gen_input/CoreDSL-Instruction-Set-Description)
		set(TMPL_DIR ${TGFS}/gen_input/templates/${BACKEND})
		
		string(TOUPPER ${BACKEND} BE_UPPER)
		string(TOLOWER ${CORE_NAME} CORE_NAMEL)
		
		set(JAVA_OPTS --add-modules ALL-SYSTEM --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.lang.annotation=ALL-UNNAMED --add-opens=java.base/java.lang.invoke=ALL-UNNAMED --add-opens=java.base/java.lang.module=ALL-UNNAMED --add-opens=java.base/java.lang.ref=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.math=ALL-UNNAMED --add-opens=java.base/java.net=ALL-UNNAMED --add-opens=java.base/java.net.spi=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/java.nio.channels=ALL-UNNAMED --add-opens=java.base/java.nio.channels.spi=ALL-UNNAMED --add-opens=java.base/java.nio.charset=ALL-UNNAMED --add-opens=java.base/java.nio.charset.spi=ALL-UNNAMED --add-opens=java.base/java.nio.file=ALL-UNNAMED --add-opens=java.base/java.nio.file.attribute=ALL-UNNAMED --add-opens=java.base/java.nio.file.spi=ALL-UNNAMED --add-opens=java.base/java.security=ALL-UNNAMED --add-opens=java.base/java.security.acl=ALL-UNNAMED --add-opens=java.base/java.security.cert=ALL-UNNAMED --add-opens=java.base/java.security.interfaces=ALL-UNNAMED --add-opens=java.base/java.security.spec=ALL-UNNAMED --add-opens=java.base/java.text=ALL-UNNAMED --add-opens=java.base/java.text.spi=ALL-UNNAMED --add-opens=java.base/java.time=ALL-UNNAMED --add-opens=java.base/java.time.chrono=ALL-UNNAMED --add-opens=java.base/java.time.format=ALL-UNNAMED --add-opens=java.base/java.time.temporal=ALL-UNNAMED --add-opens=java.base/java.time.zone=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.util.concurrent=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.locks=ALL-UNNAMED --add-opens=java.base/java.util.function=ALL-UNNAMED --add-opens=java.base/java.util.jar=ALL-UNNAMED --add-opens=java.base/java.util.regex=ALL-UNNAMED --add-opens=java.base/java.util.spi=ALL-UNNAMED --add-opens=java.base/java.util.stream=ALL-UNNAMED --add-opens=java.base/java.util.zip=ALL-UNNAMED --add-opens=java.datatransfer/java.awt.datatransfer=ALL-UNNAMED --add-opens=java.desktop/java.applet=ALL-UNNAMED --add-opens=java.desktop/java.awt=ALL-UNNAMED --add-opens=java.desktop/java.awt.color=ALL-UNNAMED --add-opens=java.desktop/java.awt.desktop=ALL-UNNAMED --add-opens=java.desktop/java.awt.dnd=ALL-UNNAMED --add-opens=java.desktop/java.awt.dnd.peer=ALL-UNNAMED --add-opens=java.desktop/java.awt.event=ALL-UNNAMED --add-opens=java.desktop/java.awt.font=ALL-UNNAMED --add-opens=java.desktop/java.awt.geom=ALL-UNNAMED --add-opens=java.desktop/java.awt.im=ALL-UNNAMED --add-opens=java.desktop/java.awt.im.spi=ALL-UNNAMED --add-opens=java.desktop/java.awt.image=ALL-UNNAMED --add-opens=java.desktop/java.awt.image.renderable=ALL-UNNAMED --add-opens=java.desktop/java.awt.peer=ALL-UNNAMED --add-opens=java.desktop/java.awt.print=ALL-UNNAMED --add-opens=java.desktop/java.beans=ALL-UNNAMED --add-opens=java.desktop/java.beans.beancontext=ALL-UNNAMED --add-opens=java.instrument/java.lang.instrument=ALL-UNNAMED --add-opens=java.logging/java.util.logging=ALL-UNNAMED --add-opens=java.management/java.lang.management=ALL-UNNAMED --add-opens=java.prefs/java.util.prefs=ALL-UNNAMED --add-opens=java.rmi/java.rmi=ALL-UNNAMED --add-opens=java.rmi/java.rmi.activation=ALL-UNNAMED --add-opens=java.rmi/java.rmi.dgc=ALL-UNNAMED --add-opens=java.rmi/java.rmi.registry=ALL-UNNAMED --add-opens=java.rmi/java.rmi.server=ALL-UNNAMED --add-opens=java.sql/java.sql=ALL-UNNAMED)
		set(GENERATOR java ${JAVA_OPTS} -jar ${GENERATOR_JAR})
		
		list(APPEND MAPPING -m "${TMPL_DIR}/CORENAME.h.gtl:${TGFS}/incl/iss/arch/${CORE_NAMEL}.h")
		list(APPEND MAPPING -m "${TMPL_DIR}/CORENAME.cpp.gtl:${TGFS}/src/iss/${CORE_NAMEL}.cpp")
		list(APPEND MAPPING -m "${TMPL_DIR}/vm_CORENAME.cpp.gtl:${TGFS}/src/vm/interp/vm_${CORE_NAMEL}.cpp")
		
		set(OUTPUT_FILES ${TGFS}/incl/iss/arch/${CORE_NAMEL}.h ${TGFS}/src/iss/${CORE_NAMEL}.cpp ${TGFS}/src/vm/interp/vm_${CORE_NAMEL}.cpp)
		
		add_custom_command(
		    COMMAND ${GENERATOR} -b ${BE_UPPER} -c ${CORE_NAME} -r ${REPO_DIR} ${MAPPING} ${INPUT_FILE}
		    DEPENDS ${INPUT_FILE} ${TMPL_DIR}/CORENAME.h.gtl ${TMPL_DIR}/CORENAME.cpp.gtl ${TMPL_DIR}/vm_CORENAME.cpp.gtl
		    OUTPUT ${OUTPUT_FILES}
		    COMMENT "Generating code for ${CORE_NAME}."
		    USES_TERMINAL VERBATIM
		)
		
		add_custom_target(${CORE_NAME}_src DEPENDS ${OUTPUT_FILES})
		
	endmacro()
else()
	macro(gen_coredsl CORE_NAME INPUT_FILE BACKEND)
		add_custom_target(${CORE_NAME}_src)
	endmacro()
endif()
