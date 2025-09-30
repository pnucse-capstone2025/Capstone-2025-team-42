#!/bin/bash
ZNS_DEV=nvme0n1
AUX_PATH=/root/aux

echo deadline > /sys/class/block/${ZNS_DEV}/queue/scheduler
rm -r ${AUX_PATH}
/root/rocksdb/plugin/zenfs/util/zenfs mkfs --zbd=${ZNS_DEV} --aux_path=${AUX_PATH} --force --enable_gc=true
