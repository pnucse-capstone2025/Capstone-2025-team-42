#!/bin/bash

ZENFS_DEV=nvme0n1

MB=$((1024 * 1024))
KB=$((1024))

DB_BENCH_PATH=/root/rocksdb/db_bench
ZENFS_UTIL_PATH=/root/rocksdb/plugin/zenfs/util/zenfs

calculate() {
    echo "scale = 0; ($1) / 1" | bc -l
}
clean_zenfs() {
    /root/scripts/init-zenfs.sh
}

get_zenfs_size() {
    ZENFS_SIZE_MB=$($ZENFS_UTIL_PATH df --zbd $ZENFS_DEV | grep '^Free' | grep -E '[0-9]+' -o)
    echo "$(($ZENFS_SIZE_MB * $MB))"
}

BLOB_MULTIPLIER=""
for arg in "$@"; do
    case $arg in
	--blob_multiplier=*)

	    BLOB_MULTIPLIER="${arg#--blob_multiplier=}"
	    ;;
	*)
	    echo "invalid params $arg"
	    exit 1
	    ;;
    esac
done


clean_zenfs
ZENFS_SIZE=$(get_zenfs_size ) 	# get zenfs's free space

# calculate parameters

WRITE_BUFFER_SIZE=$((256 * $MB)) # = memtable size

VALUE_SIZE=$((128 * $KB)) # 4kb
KEY_SIZE=16
ENTRY_SIZE=$(calculate "$KEY_SIZE + $VALUE_SIZE")


NUM_ENTRY=$(calculate "$ZENFS_SIZE / $ENTRY_SIZE")
NUM_OPS=$(( ($NUM_ENTRY * 70) / 100))

SST_FILE_SIZE=$((32 * $KB))
BLOB_FILE_SIZE=$(calculate "$WRITE_BUFFER_SIZE * $BLOB_MULTIPLIER")

LEVEL_BASE_SIZE=$(($SST_FILE_SIZE * 4)) #parameter for level 0/level 1 
LEVEL_MULTIPLIER=4
WORKLOAD=overwrite
ZENFS_STATLOGGER_PERIOD=10

SEED=4
DB_STATISTIC_OPTS="--statistics=true -stats_dump_period_sec=60"
ZENFS_OPTS="--fs_uri=zenfs://dev:${ZENFS_DEV}"
COMMON_DB_OPTS="-use_direct_io_for_flush_and_compaction=true \
    -use_direct_reads=true \
    -target_file_size_base=$SST_FILE_SIZE \
    -write_buffer_size=$WRITE_BUFFER_SIZE \
    -max_bytes_for_level_base=$LEVEL_BASE_SIZE \
    -max_bytes_for_level_multiplier=$LEVEL_MULTIPLIER"

# turn on blob file
BLOB_OPTS="-enable_blob_files=true \
    -enable_blob_garbage_collection=true \
    -blob_file_size=$BLOB_FILE_SIZE"

WORKLOAD_OPTS="-benchmarks=$WORKLOAD,stats\
    -num=$NUM_OPS \
    -value_size=$VALUE_SIZE \
    -key_size=$KEY_SIZE"

# --min_level_to_compress=7: compression을 끄기 위함.
# compression이 켜져있는 경우 리퀘스트한 I/O와 실제 디스크 사용량이 판이하게 차이나서 예측이 힘듬

MISC_OPTS="--seed=${SEED} --min_level_to_compress=7"
echo "=================== benchmark settings   ====================="
echo ""
echo "summray of db_bench parameters"
echo "memtable size(mb): $(($WRITE_BUFFER_SIZE / $MB))"
echo "sst file size(kb): $(($SST_FILE_SIZE / $KB))"
echo "blob file size(mb): $(($BLOB_FILE_SIZE / $MB))"
echo "level base size(kb): $(($LEVEL_BASE_SIZE / $KB))"
echo "level multiplier: $LEVEL_MULTIPLIER"
echo "workload: $WORKLOAD"
echo ""
echo "${DB_BENCH_PATH} ${ZENFS_OPTS} ${COMMON_DB_OPTS} \
		       ${WORKLOAD_OPTS} ${BLOB_OPTS} ${DB_STATISTIC_OPTS} \
		       ${MISC_OPTS}"
echo ""
echo "====================== benchmark output   ====================="
echo ""

if [ ${ZENFS_STATLOGGER_PERIOD} -ne 0 ]; then
    ZENFS_STATLOGGER_PERIOD=${ZENFS_STATLOGGER_PERIOD} \
		       ${DB_BENCH_PATH} ${ZENFS_OPTS} ${COMMON_DB_OPTS} \
		       ${WORKLOAD_OPTS} ${BLOB_OPTS} ${DB_STATISTIC_OPTS} \
		       ${MISC_OPTS}
else
    ${DB_BENCH_PATH} ${ZENFS_OPTS} ${COMMON_DB_OPTS} \
		     ${WORKLOAD_OPTS} ${BLOB_OPTS} ${DB_STATISTIC_OPTS} \
		     ${MISC_OPTS}
fi
