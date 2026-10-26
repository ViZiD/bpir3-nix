{
  description = "NixOS board support for the Banana Pi BPI-R3 (MT7986)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.aarch64-linux;

      btrfsProgs = pkgs.btrfs-progs.overrideAttrs (_old: {
        patches = [ ./patches/mkfs-btrfs-force-root-ownership-and-time.patch ];
        postPatch = "";
      });

      board = import ./default.nix { inherit pkgs lib; };

      mkBtrfsFs =
        args:
        pkgs.callPackage ./make-btrfs-fs.nix (
          {
            btrfs-progs = btrfsProgs;
          }
          // args
        );

      dts = {
        sd = ./dts/mt7986a-bananapi-bpi-r3-sd.dts;
        wireless = ./dts/mt7986a-bananapi-bpi-r3-wirless.dts;
        pcieButton = ./dts/mt7986a-bananapi-bpi-r3-pcie-button.dts;
      };
    in
    {
      packages.aarch64-linux = {
        kernel = board.kernelPackages.kernel;
        kernelModules = board.kernelPackages.kernel.modules;
        uboot = board.uboot;
        atf = board.atf;
        inherit btrfsProgs;
      };

      legacyPackages.aarch64-linux = board // {
        inherit btrfsProgs mkBtrfsFs dts;
      };

      lib = {
        inherit (board) kernelPackages atf uboot mkSdImage;
        inherit btrfsProgs mkBtrfsFs dts;
      };

      overlays.default = _final: _prev: {
        bpir3 = board;
      };
    };
}
