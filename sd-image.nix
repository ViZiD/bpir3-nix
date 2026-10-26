{ pkgs }:
{
  rootfsImage,
  uboot,
  version ? "0.3",
}:
pkgs.callPackage (
  {
    stdenv,
    e2fsprogs,
    gptfdisk,
    util-linux,
    zstd,
  }:
  let
    name = "nixos-sd-BananaPi-BPiR3";
    compress = true;
    imageName = "${name}-v${version}.raw";
  in
  stdenv.mkDerivation {
    inherit name;
    nativeBuildInputs = [
      e2fsprogs
      gptfdisk
      util-linux
      zstd
    ];
    buildInputs = [ uboot ];

    buildCommand = ''
      root_fs=${rootfsImage}

      mkdir -p $out/nix-support $out/sd-image
      export img=$out/sd-image/${imageName}

      echo "${pkgs.stdenv.buildPlatform.system}" > $out/nix-support/system
      echo "file sd-image $img${if compress then ".zst" else ""}" >> $out/nix-support/hydra-build-products

      bl2Start=34
      bl2End=8191

      envStart=8192
      envEnd=9215

      factoryStart=9216
      factoryEnd=13311

      fipStart=13312
      fipEnd=17407

      rootSizeBlocks=$(du -B 512 --apparent-size $root_fs | awk '{ print $1 }')
      rootPartStart=$((fipEnd + 1))
      rootPartEnd=$((rootPartStart + rootSizeBlocks - 1))

      imageSize=$((rootPartEnd + 100))
      imageSizeB=$((imageSize * 512))

      truncate -s $imageSizeB $img

      sgdisk -o \
        --set-alignment=2 \
        -n 1:$bl2Start:$bl2End -c 1:bl2 -A 1:set:2:1 \
        -n 2:$envStart:$envEnd -c 2:u-boot-env \
        -n 3:$factoryStart:$factoryEnd -c 3:factory \
        -n 4:$fipStart:$fipEnd -c 4:fip \
        -n 5:$rootPartStart:$rootPartEnd -c 5:root -A 5:set:2 \
        $img

      dd conv=notrunc if=${uboot}/bl2.img of=$img seek=$bl2Start
      dd conv=notrunc if=${uboot}/fip.bin of=$img seek=$fipStart
      dd conv=notrunc if=$root_fs of=$img seek=$rootPartStart

      if [ ${builtins.toString compress} = 1 ]; then
        zstd --rm -T$NIX_BUILD_CORES -19 $img
      fi
    '';
  }
) { }
