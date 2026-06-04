# Convenience launcher for the SPT client/launcher (SPT.Launcher.exe).
# Delegates to spt-additions run launcher for the umu/Proton setup.
{ pkgs, sptAdditions }:

pkgs.writeShellApplication {
  name = "spt-launcher";
  runtimeInputs = [ sptAdditions ];
  text = ''
    exec spt-additions run launcher "$@"
  '';
  meta = {
    description = "Launch the SPTarkov client/launcher (SPT.Launcher.exe via umu/Proton).";
    longDescription = ''
      Requires that you have previously installed SPT using spt-additions
      (or the Lutris installer). It will use the same install location
      discovery as the other tools.

      This is equivalent to running `spt-additions run launcher` but
      exposed as a first-class command for convenience when using
      this flake as an input.
    '';
    homepage = "https://github.com/MadByteDE/SPT-Linux-Guide";
    license = pkgs.lib.licenses.mit;
    mainProgram = "spt-launcher";
  };
}
