{ stdenv, runCommand, makeWrapper, lib, jq }:

let
  ctl =
    stdenv.mkDerivation {
      pname = "ctl";

      version = "0.1";

      src = ./.;

      buildInputs = [ jq makeWrapper ];

      buildPhase = ''
        patchShebangs .
      '';

      postFixup = ''
        wrapProgram "$out/bin/ctl" --prefix PATH ":" ${stdenv.lib.makeBinPath [ jq ]}
      '';

      installPhase = ''
        mkdir -p         $out/bin
        cp ctl *.sh *.jq $out/bin
      '';

      dontStrip = true;
    };

  runCtl =
    name: command:
    runCommand name {} ''
      ${ctl}/bin/ctl ${command} > $out
    '';

  profiles-all =
    runCtl "all-profiles.json" "profiles all";

  profiles = __fromJSON (__readFile profiles-all);

  mkProfile =
    name:
    runCtl "all-profiles.json" "profile get ${name}";
in

__mapAttrs (name: _: mkProfile name) profiles
//
{
  inherit ctl runCtl;

  inherit profiles-all;
}
