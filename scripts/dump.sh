#!/bin/bash
# driver script for fill_db.sh
# execute db_bench and dump all log

OUTPUT_PATH=""
SCRIPT_PATH=""
LOG_PATH=/root/aux/rocksdbtest/dbbench/LOG
BENCHMARK_ARGS=()

while [[ "$1" != "--" && -n "$1" ]] ; do
    case "$1" in
	--script=*)
	    SCRIPT_PATH=$(which "${1#--script=}")
	    shift
	    ;;
	--output_path=*)
	    OUTPUT_PATH="${1#--output_path=}"
	    shift
	    ;;
	*)
	    echo "unexpected opts $1"
	    exit 1
	    ;;
    esac
done

if [[ "$1" == "--" ]]; then
    shift
    BENCHMARK_ARGS=("$@")
fi

	
rm -rf $OUTPUT_PATH/*


if [ ! -e $OUTPUT_PATH ]; then
	mkdir -p $OUTPUT_PATH	
fi

if [ ! -d $OUTPUT_PATH ]; then
	echo "invalid path: $OUTPUT_PATH"
	exit
fi

$SCRIPT_PATH "${BENCHMARK_ARGS[@]}" | tee $OUTPUT_PATH/stdout

cp /tmp/zenfs_*.log ${OUTPUT_PATH}
cp ${SCRIPT_PATH} ${OUTPUT_PATH}
cp ${LOG_PATH} ${OUTPUT_PATH}

ZENFS_STATS=`grep -E -o \
-e "write amplification :[0-9][\.0-9]*|" \
-e "total written data :[0-9]+" \
-e "user written data :[0-9]+" \
${OUTPUT_PATH}/zenfs_*.log`

echo $ZENFS_STATS | tee -a $OUTPUT_PATH/stdout
