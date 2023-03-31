FROM quay.io/centos/centos:stream9

LABEL version="1.0" \
description="Performance Tester with fio" \
creationDate="2023-03-30" \
updatedDate="2023-03-30"

ENV FIO_DIR="/vol-to-test"
ENV FIO_CMD="fio --rw=write --ioengine=sync --fdatasync=1 --size=100m --bs=32k --name=perf_test --runtime=60 --time_based=1"

LABEL RUN="podman run --volume /<host-path>:/vol-to-test:Z IMAGE -e FIO_CMD='fio --name=seqwrite --rw=write --direct=1 --ioengine=libaio --bs=32k --numjobs=4 --size=10M --runtime=600 --group_reporting'"

RUN dnf install jq fio -y && dnf clean all && rm -rf /var/cache/dnf

COPY run.sh /tmp/run.sh

RUN chmod +x /tmp/run.sh

ENTRYPOINT ["/tmp/run.sh"]
