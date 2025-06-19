{ pkgs, config, ... }: {
  environment.systemPackages = with pkgs; [ quickemu ];
  environment.shellAliases = {
    windows = "quickemu --vm /home/v-work/.config/qemu/windows-11.conf";
  };
  boot.kernelParams = [ "intel_iommu=on" "iommu=pt" ];
  boot.kernelModules = [ "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" ];
  boot.extraModprobeConfig = ''
    options vfio-pci ids=10de:2882,10de:22be
  '';

}
