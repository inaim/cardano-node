usage_run() {
     usage "run" "Managing benchmark runs" <<EOF
    list                  List benchmark runs
    mkname                Allocate a benchmark run name/id/tag
    create                Create a benchmark run storage directory
EOF
}

run() {
local op=${1:-list}; test $# -gt 0 && shift

case "${op}" in
    list )
        (test -d "$global_ctl_runsdir" && cd "$global_ctl_runsdir" && find . -type d)
        ;;

    mkname )
        local batch=$1
        local profjson=$2
        echo "$(date +'%Y'-'%m'-'%d'-'%H.%M').$batch.$prof"
        ;;

    create )
        ## Assumptions:
        ##   - genesis has been created
        ##   - the cluster is operating
        local name=$1
        local batch=$2
        local prof=$3

        local dir=$runsdir/$name
        if test "$(realpath "$dir")" = test "$(realpath "$global_ctl_runsdir")" -o "$name" = '.'
        then fatal "bad, bad tag '$name'"; fi
        ;;

    * ) usage_run;; esac
}
