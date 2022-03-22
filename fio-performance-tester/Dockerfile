FROM registry.access.redhat.com/rhel8/toolbox

LABEL version="1.0" \
description="Performance Tester with fio" \
creationDate="2022-03-07" \
updatedDate="2022-03-07"

ENV PATH=/tmp
ENV 

RUN fio --name=seqwrite --rw=write --direct=1 --ioengine=libaio --bs=32k --numjobs=4 --size=10M --runtime=600 --group_reporting
