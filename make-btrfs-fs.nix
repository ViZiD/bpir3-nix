{
  pkgs,
  lib,
  storePaths,
  compressImage ? false,
  zstd,
  populateImageCommands ? "",
  volumeLabel,
  uuid ? "44444444-4444-4444-8888-888888888888",
  btrfs-progs,
  libfaketime,
  util-linux,
  subvolMap ? { },
}:

let
  sdClosureInfo = pkgs.buildPackages.closureInfo { rootPaths = storePaths; };
in
pkgs.stdenv.mkDerivation {
  name = "btrfs-fs.img${lib.optionalString compressImage ".zst"}";

  nativeBuildInputs = [
    btrfs-progs
    libfaketime
    util-linux
  ]
  ++ lib.optional compressImage zstd;

  buildCommand =
    let
      rootIsSubvol = builtins.elem "/" (builtins.attrNames subvolMap);
      rootImagePath = if rootIsSubvol then "./rootImage/${subvolMap."/"}" else "./rootImage";
      rootSubvolCmd = lib.optionalString rootIsSubvol ''
        mv ./rootImage rootSubVol
        mkdir ./rootImage
        mv ./rootSubVol ./rootImage/${subvolMap."/"}
      '';

      filteredSubvolMap = builtins.removeAttrs subvolMap [ "/" ];
      subvolMovePaths = builtins.concatStringsSep "\n" (
        builtins.attrValues (
          builtins.mapAttrs (
            origPath: subvolPath:
            "[ -d ${rootImagePath}/${origPath} ] && mv ${rootImagePath}/${origPath} ./rootImage/${subvolPath} || mkdir ./rootImage/${subvolPath}"
          ) filteredSubvolMap
        )
      );
      subvolMkfsArgs = builtins.concatStringsSep " " (
        builtins.attrValues (builtins.mapAttrs (_: subvolPath: "--subvol \"${subvolPath}\"") subvolMap)
      );
    in
    ''
      ${if compressImage then "img=temp.img" else "img=$out"}

      set -x
      (
          mkdir -p ./files
          ${populateImageCommands}
      )

      mkdir -p ./rootImage/nix/store

      xargs -I % cp -a --reflink=auto % -t ./rootImage/nix/store/ < ${sdClosureInfo}/store-paths
      (
        GLOBIGNORE=".:.."
        shopt -u dotglob

        for f in ./files/*; do
            cp -a --reflink=auto -t ./rootImage/ "$f"
        done
      )

      cp ${sdClosureInfo}/registration ./rootImage/nix/nix-path-registration

      ${rootSubvolCmd}
      ${subvolMovePaths}

      touch $img
      faketime -f "1970-01-01 00:00:01" mkfs.btrfs -L ${volumeLabel} -U ${uuid} ${subvolMkfsArgs} -r ./rootImage --shrink $img

      if ! btrfs check $img; then
        echo "--- 'btrfs check' failed for BTRFS image ---"
        return 1
      fi

      if [ ${builtins.toString compressImage} ]; then
        echo "Compressing image"
        zstd -v --no-progress ./$img -o $out
      fi
    '';
}
