{
  osConfig ? null,
  pkgs,
  lib,
  ...
}:

let
  hasAMD = if osConfig != null then (osConfig.systemOptions.graphics.amd.enable or false) else false;
  hasNvidia =
    if osConfig != null then (osConfig.systemOptions.graphics.nvidia.enable or false) else false;
  deviceType =
    if osConfig.systemOptions.deviceType.server.enable then
      "server"
    else
      (
        if osConfig.systemOptions.deviceType.desktop.enable then
          "desktop"
        else
          (if osConfig.systemOptions.deviceType.laptop.enable then "laptop" else null)
      );
in
{
  programs.btop = {
    enable = true;
    package =
      if hasNvidia then
        pkgs.btop-cuda
      else if hasAMD then
        pkgs.btop-rocm
      else
        pkgs.btop;
    settings = {
      color_theme = "TTY";
      vim_keys = true;
      proc_tree = true;
      proc_per_core = false;
      proc_mem_bytes = false;
      nvml_measure_pcie_speeds = lib.mkIf hasNvidia false;
      rsmi_measure_pcie_speeds = lib.mkIf hasAMD false;
      show_swap = false;
      io_mode = true;
      update_ms = 1000;
      base_10_sizes = true;
      shown_boxes =
        if (deviceType != null) then
          (
            if deviceType == "laptop" then
              "cpu mem proc"
            else if deviceType == "desktop" then
              "cpu gpu0"
            else
              "mem net"
          )
        else
          "";
    };
  };

}
