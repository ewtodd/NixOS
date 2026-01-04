{
  lib,
  osConfig,
  config,
  inputs,
  ...
}:
let
  e = if (lib.strings.hasPrefix "e" osConfig.networking.hostName) then true else false;
  wallpaperPath = config.WallpaperPath;
  settingsFile = if e then ./e-settings.nix else ./v-settings.nix;
  importedSettings = import settingsFile { inherit config osConfig; };
  settings = importedSettings.settings;
in
{
  imports = [
    ./colors.nix
    ./plugins.nix
  ];

  programs.dank-material-shell = {
    enable = true;
    dgop.package = inputs.dgop.packages."x86_64-linux".default;
    systemd = {
      enable = true;
      restartIfChanged = true;
    };

    session = {
      isLightMode = false;
      wallpaperPath = "${wallpaperPath}";
      perMonitorWallpaper = false;
      monitorWallpapers = { };
      perModeWallpaper = false;
      wallpaperPathLight = "${wallpaperPath}";
      wallpaperPathDark = "${wallpaperPath}";
      monitorWallpapersLight = { };
      monitorWallpapersDark = { };
      brightnessExponentialDevices = { };
      brightnessUserSetValues = { };
      brightnessExponentValues = { };
      doNotDisturb = false;
      nightModeEnabled = true;
      nightModeTemperature = 4500;
      nightModeHighTemperature = 6500;
      nightModeAutoEnabled = true;
      nightModeAutoMode = "time";
      nightModeStartHour = 18;
      nightModeStartMinute = 0;
      nightModeEndHour = 7;
      nightModeEndMinute = 0;
      latitude = 0;
      longitude = 0;
      nightModeUseIPLocation = false;
      nightModeLocationProvider = "";
      pinnedApps = [ ];
      hiddenTrayIds = [ ];
      selectedGpuIndex = 0;
      nvidiaGpuTempEnabled = false;
      nonNvidiaGpuTempEnabled = false;
      enabledGpuPciIds = [ ];
      wifiDeviceOverride = "";
      weatherHourlyDetailed = true;
      wallpaperCyclingEnabled = false;
      wallpaperCyclingMode = "interval";
      wallpaperCyclingInterval = 300;
      wallpaperCyclingTime = "06:00";
      monitorCyclingSettings = { };
      lastBrightnessDevice = "";
      launchPrefix = "";
      wallpaperTransition = "fade";
      includedTransitions = [
        "fade"
        "wipe"
        "disc"
        "stripes"
        "iris bloom"
        "pixelate"
        "portal"
      ];
      recentColors = [ ];
      showThirdPartyPlugins = false;
      configVersion = 1;
    };
    clipboardSettings = {
      maxHistory = 25;
      maxEntrySize = 5242880;
      autoClearDays = 1;
      clearAtStartup = true;
      disabled = false;
      disableHistory = false;
      disablePersist = true;
    };
    settings = settings;
  };

}
