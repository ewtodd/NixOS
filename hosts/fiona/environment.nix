{
  lib,
  pkgs,
  ...
}:
{
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # The A770M (5690) on xe, which takes Alchemist only by force_probe; the
  # Iris Xe stays on i915. Under i915, a long llama.cpp prefill tripped the
  # 10 s CONFIG_DRM_I915_FENCE_TIMEOUT, after which the server's GPU work was
  # silently skipped and Gemma answered with garbage until it restarted.
  boot.kernelParams = [
    "i915.force_probe=!5690"
    "xe.force_probe=5690"
  ];
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
