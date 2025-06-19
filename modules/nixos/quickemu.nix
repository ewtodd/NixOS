{ pkgs, config, ... }: {
  environment.systemPackages = with pkgs; [ quickemu ];
  environment.shellAliases = {
    windows = "quickemu --vm /home/v-work/.config/qemu/windows-11.conf";
  };

}
