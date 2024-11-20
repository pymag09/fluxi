detect_export_kind() {
    kinds="$1"
    for w in $2; do
        kinds=$(echo "$kinds" | grep ${w::-2})
    done
    echo "$kinds"
}
