{
  lib,
  pkgs,
  ...
}:
{
  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.firmware = [ pkgs.linux-firmware ];

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 5;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  environment.systemPackages = with pkgs; [
    intel-gpu-tools
    nvtopPackages.intel
    vulkan-tools
  ];

  # nvtop gets Intel GPU usage from each client's /proc/<pid>/fd and fdinfo;
  # reading those for the root-owned llama servers takes both capabilities.
  security.wrappers.nvtop = {
    source = lib.getExe pkgs.nvtopPackages.intel;
    capabilities = "cap_sys_ptrace,cap_dac_read_search+p";
    owner = "root";
    group = "wheel";
    permissions = "u+rx,g+x";
  };
}
