#!/bin/bash

set -e

# Create etcd write dir if it doesn't exist
cd ${FIO_DIR}

# Run fio
echo "---------------------------------------------------------------- Running fio ---------------------------------------------------------------------------"
${FIO_CMD} | tee /tmp/fio.out
echo "--------------------------------------------------------------------------------------------------------------------------------------------------------"

# Scrape the fio output for p99 of fsync in ns
fsync=$(cat /tmp/fio.out)
echo "$fsync"

