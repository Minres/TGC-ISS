void checkout_project(String repoUrl, String branch = 'develop') {
    checkout([
        $class: 'GitSCM',
        branches: [
            [name: "*/${branch}"]
        ],
        extensions: [
            [$class: 'CleanBeforeCheckout'],
            [$class: 'SubmoduleOption', disableSubmodules: false, parentCredentials: true, recursiveSubmodules: true, reference: '', trackingSubmodules: false, shallow: true]
        ],
        submoduleCfg: [],
        userRemoteConfigs: [
            [credentialsId: 'gitea-jenkins', url: repoUrl]
        ]
    ])
}

pipeline {
    agent any
    stages {
        stage("Checkout and build"){
            agent {docker { image 'ubuntu-riscv' }}
            stages{
                stage("Checkout TGC-Compliance and TGC-GEN"){
                    steps {
                        sh 'rm -rf * .??* '
                        checkout_project("https://git.minres.com/TGFS/TGC-ISS.git", "develop")
                        dir("TGC-COMPLIANCE"){
                            checkout_project("https://git.minres.com/TGFS/TGC-COMPLIANCE.git", "master")
                        }
                        dir("TGC-GEN"){
                            checkout_project("https://git.minres.com/TGFS/TGC-GEN.git", "develop")
                        }
                    }
                }
                stage("Generate cores and build TGC-ISS"){
                    steps {
                        sh '''
                            for core in TGC5D TGC5E; do #TGC5A TGC5B
                                for backend in interp llvm tcc asmjit; do 
                                    TGC-GEN/scripts/generate_iss.sh -o dbt-rise-tgc/ -c $core -b ${backend} TGC-GEN/CoreDSL/${core}.core_desc
                                done
                            done
                            for core in TGC6B TGC6C TGC6D TGC6E; do
                                for backend in interp llvm asmjit; do 
                                    TGC-GEN/scripts/generate_iss.sh -o dbt-rise-tgc/ -c $core -b ${backend} TGC-GEN/CoreDSL/${core}.core_desc
                                done
                            done
                            '''
                        sh 'conan profile new default --detect --force'
                        sh 'cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DWITH_ASMJIT=ON -DWITH_TCC=ON -DWITH_LLVM=ON'
                        sh 'cmake --build build -j'
                    }
                }
            }
        }
        stage("Run test suite") {
            agent {
                docker { 
                    image 'git.minres.com/tooling/riscof_sail:latest'
                    args ' -e CONAN_USER_HOME=/var/jenkins_home/workspace/riscof_sail'
                } 
            }
            stages {
                stage('ACT 32bit') {
                    matrix {
                        axes {
                            axis {
                                name 'CORE'
                                values 'TGC5C', 'TGC5D', 'TGC5E' // TGC5A, 'TGC5B', 
                            }
                            axis {
                                name 'BACKEND'
                                values 'interp', 'llvm', 'tcc', 'asmjit'
                            }
                        }
                        stages {
                            stage('Run riscof') {
                                steps {
                                    sh "mkdir -p ${BACKEND}"
                                    sh "python3 TGC-COMPLIANCE/run_act.py -core ${CORE} -sim build/dbt-rise-tgc/tgc-sim -w ${BACKEND} --local --backend ${BACKEND}"
                                }
                            }
                        }
                    }
                }
                stage('ACT 64bit') {
                    matrix {
                        axes {
                            axis {
                                name 'CORE'
                                    values 'TGC6B', 'TGC6C', 'TGC6D', 'TGC6E'
                            }
                            axis {
                                name 'BACKEND'
                                values 'interp', 'llvm', 'asmjit'
                            }
                        }
                        stages {
                            stage('Run riscof') {
                                steps {
                                    sh "mkdir -p ${BACKEND}"
                                    sh "python3 TGC-COMPLIANCE/run_act.py -core ${CORE} -sim build/dbt-rise-tgc/tgc-sim -w ${BACKEND} --local --backend ${BACKEND}"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
