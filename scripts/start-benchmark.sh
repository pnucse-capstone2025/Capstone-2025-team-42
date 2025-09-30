#!/bin/bash
# scripts under scripts/ folder must be added in $PATH

OUTPUT_PATH="/somewhere/for/dump/benchmark/result"

declare -a POLICY=("SLSIA" "SIA" "vanilla")
for branch in "${POLICY[@]}"; do
    echo "start benchmark with policy $policy"
    ZENFS_ALLOC_POLICY=$policy dump.sh   --script=fill_db.sh --output_path="$OUTPUT_PATH/$policy/" \
	    -- --blob_multiplier=2
done
