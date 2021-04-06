usage_topology() {
     usage "topology" "Topology generation" <<EOF
    make PROFILE OUTDIR   Generate the full cluster topology, including:
                            - the Nixops/'cardano-ops' style topology
                            - the .dot and .pdf rendering

    for-local-node TOPO-DIR PORT-BASE N
                          Given the full cluster topology,
                            print topology for the N-th node,
                            while assigning it a local port number PORT-BASE+N

    for-local-observer PROFILE TOPO-DIR PORT-BASE
                          Given the profile and the full cluster topology,
                            print topology for the observer node,
                            while assigning it a local port number PORT-BASE+NODE-COUNT
EOF
}

topology() {
local op=${1:---help)}; shift

case "${op}" in
    make )
        local usage="USAGE:  ctl topology make PROFILE OUTDIR"
        local profile=${1:?$usage}
        local outdir=${2:?$usage}

        local prof=$(profile get $profile)
        local n_hosts=$(jq .composition.n_hosts <<<$prof)

        ## 0. Generate:
        #
        args=( --topology-output "$outdir"/topology-nixops.json
               --dot-output      "$outdir"/topology.dot
               --size             $n_hosts

               $(jq '.composition.locations
                    | map("--loc " + .)
                    | join(" ")
                    ' --raw-output <<<$prof)
             )
        topology "${args[@]}"

        ## 1. Render PDF:
        #
        neato -s120 -Tpdf \
              "$outdir"/topology.dot > "$outdir"/topology.pdf

        ## 2. Patch the nixops topology with the density information:
        #
        jq --argjson prof "$prof" '
           def nixops_topology_set_pool_density($topo; $density):
              $topo *
              { coreNodes:
                ( .coreNodes
                | map
                  ( . *
                    { pools:
                      (if .pools == null then 0 else
                       if .pools == 1    then 1 else
                          ([$density, 1] | max) end end)
                    }
                  )
                )
              };

           nixops_topology_set_pool_density(.; $prof.dense_pool_density)
           '   "$outdir"/topology-nixops.json |
        sponge "$outdir"/topology-nixops.json
        ;;

    for-local-node )
        local usage="USAGE:  ctl topology for-local-node TOPO-DIR PORT-BASE N"
        local topo_dir=${1:?$usage}
        local port_base=${2:?$usage}
        local i=${3:?$usage}

        args=(--slurpfile topology "$topo_dir"/topology-nixops.json
              --argjson   port_base $port_base
              --argjson   i         $i
              --null-input
             )
        jq 'def loopback_node_topology_from_nixops_topology($topo; $i):
              $topo.coreNodes[$i].producers                      as $producers
            | ($producers | map(ltrimstr("node-") | fromjson))   as $prod_indices
            | { Producers:
                ( $prod_indices
                | map
                  ({ addr:    "127.0.0.1"
                   , port:    ($port_base + .)
                   , valency: 1
                   }
                  ))
              };

            loopback_node_topology_from_nixops_topology($topology[0]; $i)
           ' "${args[@]}";;

    for-local-observer )
        local usage="USAGE:  ctl topology for-local-observer PROFILE TOPO-DIR PORT-BASE"
        local profile=${1:?$usage}
        local topo_dir=${2:?$usage}
        local port_base=${3:?$usage}

        local prof=$(profile get $profile)

        args=(--slurpfile topology "$topo_dir"/topology-nixops.json
              --argjson   port_base $port_base
              --null-input
             )
        jq 'def loopback_observer_topology_from_nixops_topology($topo):
              [range(0; $topo.coreNodes | length)] as $prod_indices
            | { Producers:
                ( $prod_indices
                | map
                  ({ addr:    "127.0.0.1"
                   , port:    ($port_base + .)
                   , valency: 1
                   }
                  ))
              };

            loopback_observer_topology_from_nixops_topology($topology[0])
            ' "${args[@]}";;

    * ) usage_topology;; esac
}
