{
  pkgs,
  lib ? pkgs.lib,
}:
let
  kernelPackages = import ./kernel.nix { inherit pkgs lib; };
  inherit (import ./uboot.nix { inherit pkgs; }) atf uboot;
  mkSdImage = import ./sd-image.nix { inherit pkgs; };
in
{
  inherit
    kernelPackages
    atf
    uboot
    mkSdImage
    ;
}
