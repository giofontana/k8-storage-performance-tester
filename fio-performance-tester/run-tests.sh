#!/bin/bash

# Usage: run-tests.sh -s [gp2, cephfs, ceph-rbd or vmware]"
#    Examples:
#       ./run-tests.sh -s gp2
#       ./run-tests.sh -s cephfs
#       ./run-tests.sh -s ceph-rbd
#       ./run-tests.sh -s vmware

STORAGE_CLASSES=("gp2" "cephfs" "ceph-rbd" "vmware")
VERSION=1.0
SUBJECT=fio-performance-tester
USAGE="Usage: run-tests.sh -s [gp2, cephfs, ceph-rbd or vmware]"

if [ $# == 0 ] ; then
    echo $USAGE
    exit 1;
fi

while getopts ":s:vh" optname
do
    case "$optname" in
        "v")
            echo "Version $VERSION"
            exit 0;
        ;;
        "s")
            if [[ " ${STORAGE_CLASSES[*]} " =~ " $OPTARG " ]]; then
                storageclass=$OPTARG
            else
                echo "Use one of the following options: gp2, cephfs, ceph-rbd or vmware"
                exit 0;
            fi
        ;;
        "h")
            echo -e $USAGE
            exit 0;
        ;;
        "?")
            echo "Unknown option $OPTARG"
            exit 0;
        ;;
        ":")
            echo "No argument value for option $OPTARG"
            exit 0;
        ;;
        *)
            echo "Unknown error while processing options"
            exit 0;
        ;;
    esac
done

if [ -z "$storageclass" ]; then
    echo "No valid argument"
    exit 0;
fi

# Checking if is logged to openshift cluster already
oc whoami > /dev/null 2>&1
ret=$?
if [ $ret -ne 0 ]; then
    echo "You are not logged in yet, please run the 'oc login' first."
    exit 1
fi

# Run fio
echo -e "\n*** Deploying job ..."
oc apply -k k8s/overlay/$storageclass/

# Collecting results
namespace="fio-perf-test-$storageclass"

echo -e "\n*** Collecting results for $namespace and storing on file $namespace-$bs-results.txt ..."
fio_bs=('4k' '16k' '32k' '64k')

for bs in ${fio_bs[@]}
do
    
    echo "Performance report for $namespace and $bs" > $namespace-$bs-results.txt
    echo "Test details:" >> $namespace-$bs-results.txt
    echo "  POD NAME: $(oc get pods -l job-name=fio-perf-tester-$bs -n $namespace -ojsonpath='{.items[0].metadata.name}')" >> $namespace-$bs-results.txt
    echo "  FIO COMMAND: $(oc get pods -l job-name=fio-perf-tester-$bs -n $namespace -ojsonpath='{.items[0].spec.containers[0].env[?(@.name == "FIO_CMD")].value}')" >> $namespace-$bs-results.txt
    echo -e "  PVC: $(oc -n $namespace get pvc $(oc get pods -l job-name=fio-perf-tester-$bs -n $namespace -ojsonpath='{.items[0].spec.volumes[?(@.name == "vol-to-test")].persistentVolumeClaim.claimName}') -ojsonpath='{.metadata.name}') / STORAGECLASS: $(oc -n $namespace get pvc $(oc get pods -l job-name=fio-perf-tester-$bs -n $namespace -ojsonpath='{.items[0].spec.volumes[?(@.name == "vol-to-test")].persistentVolumeClaim.claimName}') -ojsonpath='{.spec.storageClassName}')\n"  >> $namespace-$bs-results.txt
    
    pod_status=$(oc get pods -l job-name=fio-perf-tester-$bs -n $namespace -ojsonpath="{.items[0].status.phase}")
    timer=0
    while [[ "$pod_status" != "Succeeded" ]]
    do
        timer=$(($timer+1))
        echo "Job is not finished yet, waiting more 15 seconds..."
        if [ $timer -gt 20 ]; then
            echo "Timeout reached... Check the status of the job on OpenShift."
            exit 1
        fi
        sleep 15
        pod_status=$(oc get pods -l job-name=fio-perf-tester-$bs -n $namespace -ojsonpath="{.items[0].status.phase}")
    done
    
    oc -n $namespace logs $(oc get pods -l job-name=fio-perf-tester-$bs -n $namespace -ojsonpath="{.items[0].metadata.name}") >> $namespace-$bs-results.txt
done

# Cleaning
echo -e "\n*** Cleaning the environment (Deleting objects) ..."
oc delete namespace $namespace
