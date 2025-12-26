{
  pkgs,
  inputs,
  config,
  ...
}:
let
  unstable = inputs.unstable.legacyPackages.${pkgs.system};
in
{
  programs.obs-studio = {
    enable = true;
    package = unstable.obs-studio;
    plugins = with pkgs.obs-studio-plugins; [ obs-backgroundremoval ];
  };
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
  '';

}
