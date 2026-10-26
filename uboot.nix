{ pkgs }:
let
  atf =
    (pkgs.buildArmTrustedFirmware {
      platform = "mt7986";
      extraMakeFlags = [
        "USE_MKIMAGE=1"
        "DRAM_USE_DDR4=1"
        "BOOT_DEVICE=sdmmc"
        "bl2"
        "bl31"
      ];
      extraMeta.platforms = [ "aarch64-linux" ];
      filesToInstall = [
        "build/mt7986/release/bl2.img"
        "build/mt7986/release/bl31.bin"
      ];
    }).overrideAttrs
      (old: {
        version = "2.12.0-mtk";
        src = pkgs.fetchFromGitHub {
          owner = "mtk-openwrt";
          repo = "arm-trusted-firmware";
          rev = "e090770684e775711a624e68e0b28112227a4c38";
          hash = "sha256-VI5OB2nWdXUjkSuUXl/0yQN+/aJp9Jkt+hy7DlL+PMg=";
        };
        nativeBuildInputs = old.nativeBuildInputs ++ [
          pkgs.dtc
          pkgs.ubootTools
          pkgs.which
          pkgs.python3
        ];
      });

  ubootVersion = "2025.04";
  ubootSrc = pkgs.fetchurl {
    url = "https://ftp.denx.de/pub/u-boot/u-boot-${ubootVersion}.tar.bz2";
    hash = "sha256-Q5077ylu/9VBML5qcxxbEYvn/d1/zGY8y8X7GClNhxg=";
  };

  sbcConfig = ''
    CONFIG_AUTOBOOT=y
    CONFIG_BOOTDELAY=1
    CONFIG_USE_BOOTCOMMAND=y
    CONFIG_BOOTSTD_DEFAULTS=y
    CONFIG_BOOTSTD_FULL=y
    CONFIG_CMD_BOOTFLOW_FULL=y
    CONFIG_BOOTCOMMAND="bootflow scan -lb"
    CONFIG_DEVICE_TREE_INCLUDES="nixos-mmcboot.dtsi"
    CONFIG_ENV_IS_NOWHERE=y
    CONFIG_LZ4=y
    CONFIG_BZIP2=y
    CONFIG_ZSTD=y
    CONFIG_CMD_EXT4=y
    CONFIG_FS_BTRFS=y
    CONFIG_CMD_BTRFS=y
  '';

  bpiR3Config = ''
    CONFIG_ENV_SOURCE_FILE="mt7986-nixos"
    CONFIG_DEFAULT_FDT_FILE="mediatek/mt7986a-bananapi-bpi-r3.dtb"
    CONFIG_SYS_BOOTM_LEN=0x6000000
    CONFIG_BOARD_LATE_INIT=y
    CONFIG_SHA1=y
    CONFIG_OF_BOARD_SETUP=y
  '';

  uboot =
    (pkgs.buildUBoot {
      defconfig = "mt7986a_bpir3_sd_defconfig";
      version = ubootVersion;
      src = ubootSrc;
      extraConfig = sbcConfig + bpiR3Config;
      extraPatches = [
        ./patches/mt7986-persistent-mac-from-cpu-uid.patch
        ./patches/mt7986-persistent-wlan-mac-from-cpu-uid.patch
      ];
      filesToInstall = [
        "bl2.img"
        "fip.bin"
      ];
      extraMeta.platforms = [ "aarch64-linux" ];
      postBuild = ''
        fiptool create --soc-fw ${atf}/bl31.bin --nt-fw u-boot.bin fip.bin
        cp ${atf}/bl2.img bl2.img
      '';
    }).overrideAttrs
      (old: {
        nativeBuildInputs = old.nativeBuildInputs ++ [
          pkgs.pkg-config
          pkgs.ncurses
          pkgs.armTrustedFirmwareTools
        ];
        postPatch = old.postPatch + ''
          cp ${./mt7986-nixos.env} board/mediatek/mt7986/mt7986-nixos.env
          cp ${./mt7986-mmcboot.dtsi} arch/arm/dts/nixos-mmcboot.dtsi
        '';
        configurePhase = ''
          echo "-$(basename $out | cut -d - -f 1)" > localversion.nix
        ''
        + old.configurePhase;
      });
in
{
  inherit atf uboot;
}
