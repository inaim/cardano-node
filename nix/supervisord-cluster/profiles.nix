{ runCommand, ctl
, ...
}:

runCommand "cluster-profiles.json" {} ''
  cd ${ctl}/bin/
  ${ctl}/bin/ctl profile generate-all > $out
  ''
