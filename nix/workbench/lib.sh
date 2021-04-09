to_jsonlist() {
    for x in "$@"
    do echo "\"$x\""
    done | jq --slurp '.'
}

__usage() {
    local op=$1 desc=$2
    cat >&2 <<EOF
USAGE:  $(basename "$0") OPTIONS.. $op SUBOP SUBOP-ARGS..

  $desc:

$(cat)

EOF
}

usage() {
    __usage "$@"
    exit 1
}

fail() {
    echo "$*" >&2
    exit 1
}

fatal() {
    fail "FATAL: $*"
}
