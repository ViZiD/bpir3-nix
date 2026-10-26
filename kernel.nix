{ pkgs, lib }:
let
  kernel = pkgs.linuxPackages_7_2.kernel.override {
    kernelPatches = [
      {
        name = "avoid-crashing-missing-band.patch";
        patch = ./patches/780-avoid-crashing-missing-band.patch;
      }
      {
        name = "hsr-config-ordering-7.2.patch";
        patch = ./patches/hsr-config-ordering-7.2.patch;
      }
    ];

    ignoreConfigErrors = true;
    structuredExtraConfig = with lib.kernel; {
      FB = lib.mkForce no;
      DRM = lib.mkForce no;
      SOUND = no;
      INFINIBAND = lib.mkForce no;

      PCIE_MEDIATEK = yes;
      PCIE_MEDIATEK_GEN3 = yes;

      MTD_NAND_ECC_MEDIATEK = yes;

      BRIDGE = yes;
      HSR = yes;
      NET_DSA = yes;
      NET_DSA_TAG_MTK = yes;
      NET_DSA_MT7530 = yes;
      NET_VENDOR_MEDIATEK = yes;
      PCS_MTK_LYNXI = yes;
      NET_MEDIATEK_SOC_WED = yes;
      NET_MEDIATEK_SOC = yes;
      NET_MEDIATEK_STAR_EMAC = yes;
      MEDIATEK_GE_PHY = yes;

      WLAN = yes;
      WLAN_VENDOR_MEDIATEK = yes;
      MT76_CORE = module;
      MT76_LEDS = yes;
      MT76_CONNAC_LIB = module;
      MT7915E = module;
      MT798X_WMAC = yes;

      EINT_MTK = yes;
      PINCTRL_MTK = yes;
      PINCTRL_MT7986 = yes;
      MTK_THERMAL = yes;
      MTK_SOC_THERMAL = yes;
      MTK_LVTS_THERMAL = yes;
      COMMON_CLK_MEDIATEK = yes;
      COMMON_CLK_MEDIATEK_FHCTL = yes;
      COMMON_CLK_MT7986 = yes;
      COMMON_CLK_MT7986_ETHSYS = yes;
      MEDIATEK_WATCHDOG = yes;
      REGULATOR_MT6380 = yes;
    };
  };
in
pkgs.linuxPackagesFor kernel
