#%Module######################################################################
##
##      Project Module
##
proc ModulesHelp { } {
  puts stderr "\tThe TGFS-ISS Project Module\n"
  puts stderr "\tThis module loads PATHs and variables for accessing Verilator."
}


set distro [exec /bin/lsb_release -i -s]
if { $distro == "CentOS" && ![info exists ::env(PROJECT)] && ![info exists ::env(PCP_DIR)] } {
    puts stderr     "Don't forget to execute 'scl enable devtoolset-7 bash'"
}

if {![info exists ::env(PROJECT)] && [file exists $::env(HOME)/.sdkman/candidates/java/11.0.9.hs-adpt/] != 1} { 
    puts stderr "Please install java via 'sdk install java 11.0.9.hs-adpt'!"
    prereq java/11.0.9
} else {
    prepend-path PATH $::env(HOME)/.sdkman/candidates/java/11.0.9.hs-adpt/bin
}

if {![info exists ::env(PROJECT)] && [file exists $::env(HOME)/.sdkman/candidates/maven/3.6.3] != 1} { 
    puts stderr "Please install sbt via 'sdk install maven 3.6.3'!"
    prereq maven/3.6.3
} else {
    prepend-path PATH $::env(HOME)/.sdkman/candidates/sbt/1.4.4/bin
}

module load tools/cmake

setenv PROJECT TGFS-ISS

