{ stdenv, runCommand, ctl }:

let
  profiles-all =
    runCommand "all-profiles.json" {} ''
      ${ctl}/bin/ctl profiles all > $out
    '';

  profiles = __fromJSON (__readFile profiles-all);

  mkProfile =
    name:
    runCommand "profile-${name}.json" {} ''
      ${ctl}/bin/ctl profile get ${name} > $out
    '';
in
{
  inherit profiles-all;
}
//
__mapAttrs
  (name: _: mkProfile name)
  profiles
