#!/usr/bin/env bash
set -euo pipefail

results="regression_results.log"
rm -f "$results"

if [ -f case.list ]; then
    # read non-empty, non-comment lines into an array, stripping Windows CR and BOM
    readarray -t cases < <(sed -e 's/\r//g' -e 's/^\xef\xbb\xbf//' -e 's/#.*//' -e '/^[[:space:]]*$/d' case.list)
else
    cases=( $(for d in ../cases/*; do [ -d "$d" ] && basename "$d"; done) )
fi

passed_list=()
failed_list=()

for tc in "${cases[@]}"; do
    # Trim leading/trailing whitespace just to be safe
    tc=$(echo "$tc" | xargs)
    if [ -z "$tc" ]; then continue; fi

    echo "--------------------------------------------------------"
    echo "Running case : $tc"
    make sim tc="$tc" || true
    logfile="${tc}_sim.log"
    counts=""
    if [ -f "$logfile" ]; then
        counts=$(grep -E '^\s*\[[^]]+\]' "$logfile" || true)
    fi
    
    if grep -q "TEST PASSED" "$logfile" 2>/dev/null; then
        echo "$tc: PASS" | tee -a "$results"
        if [ -n "$counts" ]; then
            echo "-- Report counts by id for $tc --" | tee -a "$results"
            echo "$counts" | sed -E 's/^[[:space:]]*//; s/[[:space:]]+/    /g' | tee -a "$results"
        fi
        passed_list+=("$tc")
    else
        echo "$tc: FAIL" | tee -a "$results"
        if [ -n "$counts" ]; then
            echo "-- Report counts by id for $tc --" | tee -a "$results"
            echo "$counts" | sed -E 's/^[[:space:]]*//; s/[[:space:]]+/    /g' | tee -a "$results"
        fi
        failed_list+=("$tc")
    fi
done

{
    echo ""
    echo "========================================================"
    echo "                 REGRESSION SUMMARY                     "
    echo "========================================================"
    echo "Passed (${#passed_list[@]}):"
    for p in "${passed_list[@]:-}"; do echo "  - $p"; done
    echo "Failed (${#failed_list[@]}):"
    if [ ${#failed_list[@]} -gt 0 ]; then
        for f in "${failed_list[@]:-}"; do echo "  - $f"; done
    else
        echo "  (None)"
    fi
    echo "========================================================"
} | tee -a "$results"
echo "See $results for details."
