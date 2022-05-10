#!/bin/bash
##

# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=`readlink -f "$0"`
# Absolute path this script is in, thus /home/user/bin
SCRIPTDIR=`dirname "$SCRIPT"`
SCRIPTNAME=`basename "$SCRIPT"`

function print_help {
    echo "Usage: $SCRIPTNAME [-h] -c <core name> -v <core variant> <input file>"
    echo "Generate ISS sources for TGC cores"
    echo "  -c <name>         core name"
    echo "  -b <backend>      ISS backend for which sources are generated, interp,tcc, or llvm"
    echo "  -r <repo dir>     repo used for generation"
    echo "  -t <template dir> template dir used for generation"
    exit 0
}


CORE_NAME=
BACKEND=
REPO_DIR=dbt-rise-tgc/gen_input/CoreDSL-Instruction-Set-Description 
TMPL_DIR=dbt-rise-tgc/gen_input/templates
while getopts 'c:b:r:t:h' c
do
  case $c in
    c) CORE_NAME=$OPTARG ;;
    b) BACKEND=$OPTARG ;;
    r) REPO_DIR=$OPTARG ;;
    t) TMPL_DIR=$OPTARG ;;
    h) print_help ;;
  esac
done
shift $((OPTIND-1))

if [ -z "$CORE_NAME" ]; then
    echo "core name missing!"
    exit 1
fi
if [ -z "$BACKEND" ]; then
    echo "core variant missing!"
    exit 1
fi


JAVA_OPTS="--add-modules ALL-SYSTEM --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.lang.annotation=ALL-UNNAMED --add-opens=java.base/java.lang.invoke=ALL-UNNAMED --add-opens=java.base/java.lang.module=ALL-UNNAMED --add-opens=java.base/java.lang.ref=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.math=ALL-UNNAMED --add-opens=java.base/java.net=ALL-UNNAMED --add-opens=java.base/java.net.spi=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/java.nio.channels=ALL-UNNAMED --add-opens=java.base/java.nio.channels.spi=ALL-UNNAMED --add-opens=java.base/java.nio.charset=ALL-UNNAMED --add-opens=java.base/java.nio.charset.spi=ALL-UNNAMED --add-opens=java.base/java.nio.file=ALL-UNNAMED --add-opens=java.base/java.nio.file.attribute=ALL-UNNAMED --add-opens=java.base/java.nio.file.spi=ALL-UNNAMED --add-opens=java.base/java.security=ALL-UNNAMED --add-opens=java.base/java.security.acl=ALL-UNNAMED --add-opens=java.base/java.security.cert=ALL-UNNAMED --add-opens=java.base/java.security.interfaces=ALL-UNNAMED --add-opens=java.base/java.security.spec=ALL-UNNAMED --add-opens=java.base/java.text=ALL-UNNAMED --add-opens=java.base/java.text.spi=ALL-UNNAMED --add-opens=java.base/java.time=ALL-UNNAMED --add-opens=java.base/java.time.chrono=ALL-UNNAMED --add-opens=java.base/java.time.format=ALL-UNNAMED --add-opens=java.base/java.time.temporal=ALL-UNNAMED --add-opens=java.base/java.time.zone=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.util.concurrent=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.locks=ALL-UNNAMED --add-opens=java.base/java.util.function=ALL-UNNAMED --add-opens=java.base/java.util.jar=ALL-UNNAMED --add-opens=java.base/java.util.regex=ALL-UNNAMED --add-opens=java.base/java.util.spi=ALL-UNNAMED --add-opens=java.base/java.util.stream=ALL-UNNAMED --add-opens=java.base/java.util.zip=ALL-UNNAMED --add-opens=java.datatransfer/java.awt.datatransfer=ALL-UNNAMED --add-opens=java.desktop/java.applet=ALL-UNNAMED --add-opens=java.desktop/java.awt=ALL-UNNAMED --add-opens=java.desktop/java.awt.color=ALL-UNNAMED --add-opens=java.desktop/java.awt.desktop=ALL-UNNAMED --add-opens=java.desktop/java.awt.dnd=ALL-UNNAMED --add-opens=java.desktop/java.awt.dnd.peer=ALL-UNNAMED --add-opens=java.desktop/java.awt.event=ALL-UNNAMED --add-opens=java.desktop/java.awt.font=ALL-UNNAMED --add-opens=java.desktop/java.awt.geom=ALL-UNNAMED --add-opens=java.desktop/java.awt.im=ALL-UNNAMED --add-opens=java.desktop/java.awt.im.spi=ALL-UNNAMED --add-opens=java.desktop/java.awt.image=ALL-UNNAMED --add-opens=java.desktop/java.awt.image.renderable=ALL-UNNAMED --add-opens=java.desktop/java.awt.peer=ALL-UNNAMED --add-opens=java.desktop/java.awt.print=ALL-UNNAMED --add-opens=java.desktop/java.beans=ALL-UNNAMED --add-opens=java.desktop/java.beans.beancontext=ALL-UNNAMED --add-opens=java.instrument/java.lang.instrument=ALL-UNNAMED --add-opens=java.logging/java.util.logging=ALL-UNNAMED --add-opens=java.management/java.lang.management=ALL-UNNAMED --add-opens=java.prefs/java.util.prefs=ALL-UNNAMED --add-opens=java.rmi/java.rmi=ALL-UNNAMED --add-opens=java.rmi/java.rmi.activation=ALL-UNNAMED --add-opens=java.rmi/java.rmi.dgc=ALL-UNNAMED --add-opens=java.rmi/java.rmi.registry=ALL-UNNAMED --add-opens=java.rmi/java.rmi.server=ALL-UNNAMED --add-opens=java.sql/java.sql=ALL-UNNAMED"

GENERATOR="java $JAVA_OPTS -jar coredsl/com.minres.coredsl.generator.repository/target/com.minres.coredsl.generator-2.0.0-SNAPSHOT.jar "

INPUT_FILE=$1

CORE_NAME_LC=`echo "$CORE_NAME" | tr '[:upper:]' '[:lower:]'`

MAPPING=""
MAPPING="$MAPPING -m ${TMPL_DIR}/CORENAME.h.gtl:dbt-rise-tgc/incl/iss/arch/${CORE_NAME_LC}.h"
MAPPING="$MAPPING -m ${TMPL_DIR}/CORENAME.cpp.gtl:dbt-rise-tgc/src/iss/${CORE_NAME_LC}.cpp"
MAPPING="$MAPPING -m ${TMPL_DIR}/${BACKEND}/CORENAME.cpp.gtl:dbt-rise-tgc/src/vm/${BACKEND}/vm_${CORE_NAME_LC}.cpp"
MAPPING="$MAPPING -m ${TMPL_DIR}/CORENAME_instr.yaml.gtl:dbt-rise-tgc/${CORE_NAME_LC}_instr.yaml"

[ -f coredsl/com.minres.coredsl.generator.repository/target/com.minres.coredsl.generator-2.0.0-SNAPSHOT.jar ] || (cd coredsl; mvn package)

$GENERATOR -c $CORE_NAME -r $REPO_DIR $MAPPING $INPUT_FILE

