# The spt-additions installer, wrapped with its native dependencies.
# This is the main entrypoint for installing/running SPT on Nix.
{ pkgs, coreScriptDeps }:

pkgs.writeShellApplication {
  name = "spt-additions";
  runtimeInputs = coreScriptDeps ++ [ (import ./spt-server.nix { inherit pkgs; lib = pkgs.lib; }) ];
  text = ''
    export DOTNET_ROOT="${pkgs.dotnet-aspnetcore_9}/share/dotnet"
    exec ${../../scripts/spt-additions} "$@"
  '';
  meta = {
    description = "The SPT-Linux-Guide additions installer (native Linux path using umu/GE-Proton).";
    homepage = "https://github.com/MadByteDE/SPT-Linux-Guide";
    license = pkgs.lib.licenses.mit;
    mainProgram = "spt-additions";
  };
}
