# Performance Tester

## Note: Repo under development

fio-performance-tester
    Objectives:
        1. Dockerfile which generates an image that runs fio job according env variables
        2. The result need to be written in an output file that can be accessed from K8s/OpenShift (how?)
        3. Create yaml manifests to use it on OCP as a job.

file-generator:
    Objectives:
        1. Job to generate files according env variables
