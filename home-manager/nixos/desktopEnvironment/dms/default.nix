{
  osConfig,
  config,
  inputs,
  ...
}:
let
  wallpaperPath = config.WallpaperPath;
  settingsFile =
    if (osConfig.systemOptions.owner.e.enable) then ./e-settings.nix else ./v-settings.nix;
  importedSettings = import settingsFile { inherit config osConfig; };
  settings = importedSettings.settings;
  weatherLocation =
    if (osConfig.systemOptions.owner.e.enable) then "Ann Arbor, Michigan" else "Baton Rouge, Louisiana";
  weatherCoordinates =
    if (osConfig.systemOptions.owner.e.enable) then
      "42.2813722,-83.7484616"
    else
      "30.4494155,-91.1869659";
in
{
  imports = [
    ./colors.nix
    ./dsearch.nix
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
      weatherLocation = weatherLocation;
      weatherCoordinates = weatherCoordinates;
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
    };
    clipboardSettings = {
      disabled = false;
      disableHistory = true;
      disablePersist = true;
    };
    settings = settings;
  };

}
