{
  osConfig ? null,
  config,
  lib,
  pkgs,
  ...
}:
let
  wallpaperPath = config.WallpaperPath or "/etc/nixos/hosts/HOSTNAME_PLACEHOLDER/wallpaper.png";
  isEOwner = if osConfig != null then (osConfig.systemOptions.owner.e.enable or false) else false;
  settingsFile = if isEOwner then ./e-settings.nix else ./v-settings.nix;
  importedSettings = import settingsFile { inherit config osConfig lib; };
  settings = importedSettings.settings;
  weatherLocation = "Woodridge, 60517";
  weatherCoordinates = "41.7563344,-88.0455590";
in
{
  imports = [
    ./colors.nix
    ./dsearch.nix
    ./plugins.nix
  ];

  programs.dank-material-shell = {
    enable = true;
    package = pkgs.dms-shell;
    quickshell.package = pkgs.quickshell;
    enableDynamicTheming = false;
    enableAudioWavelength = false;
    enableCalendarEvents = false;
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

  systemd.user.services.dms.Service.Environment = "DMS_DISABLE_MATUGEN=1";

}
