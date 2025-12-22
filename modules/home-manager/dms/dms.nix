{ lib, config, osConfig, pkgs, ... }:
let
  e = if (lib.strings.hasPrefix "e" osConfig.networking.hostName) then
    true
  else
    false;
  deviceType = osConfig.DeviceType;
  homeDir = config.home.homeDirectory;
  wallpaperPath = config.WallpaperPath;
  jsonFormat = pkgs.formats.json { };
  settings = if e then {
    currentThemeName = "custom";
    customThemeFile = "${homeDir}/.config/DankMaterialShell/colors.json";
    matugenScheme = "scheme-content";
    runUserMatugenTemplates = false;
    matugenTargetMonitor = "";
    popupTransparency = 1;
    dockTransparency = 1;
    widgetBackgroundColor = "sc";
    widgetColorMode = "default";
    cornerRadius = 10;
    use24HourClock = false;
    showSeconds = false;
    useFahrenheit = true;
    nightModeEnabled = false;
    animationSpeed = 1;
    customAnimationDuration = 500;
    wallpaperFillMode = "Fill";
    blurredWallpaperLayer = true;
    blurWallpaperOnOverview = false;
    showLauncherButton = true;
    showWorkspaceSwitcher = true;
    showFocusedWindow = true;
    showWeather = true;
    showMusic = true;
    showClipboard = true;
    showCpuUsage = true;
    showMemUsage = true;
    showCpuTemp = true;
    showGpuTemp = true;
    selectedGpuIndex = 0;
    enabledGpuPciIds = [ ];
    showSystemTray = true;
    showClock = true;
    showNotificationButton = true;
    showBattery = (deviceType == "laptop");
    showControlCenterButton = true;
    showCapsLockIndicator = true;
    controlCenterShowNetworkIcon = true;
    controlCenterShowBluetoothIcon = true;
    controlCenterShowAudioIcon = true;
    controlCenterShowVpnIcon = true;
    controlCenterShowBrightnessIcon = false;
    controlCenterShowMicIcon = false;
    controlCenterShowBatteryIcon = false;
    controlCenterShowPrinterIcon = false;
    showPrivacyButton = true;
    privacyShowMicIcon = false;
    privacyShowCameraIcon = false;
    privacyShowScreenShareIcon = false;
    controlCenterWidgets = [
      {
        enabled = true;
        id = "volumeSlider";
        width = 50;
      }
      {
        enabled = true;
        id = "brightnessSlider";
        width = 50;
      }
      {
        enabled = true;
        id = "wifi";
        width = 50;
      }
      {
        enabled = true;
        id = "bluetooth";
        width = 50;
      }
      {
        enabled = true;
        id = "audioOutput";
        width = 50;
      }
      {
        enabled = true;
        id = "audioInput";
        width = 50;
      }
      {
        enabled = true;
        id = "nightMode";
        width = 50;
      }
      {
        enabled = true;
        id = "darkMode";
        width = 50;
      }
    ];
    showWorkspaceIndex = false;
    showWorkspacePadding = false;
    workspaceScrolling = false;
    showWorkspaceApps = false;
    maxWorkspaceIcons = 3;
    workspacesPerMonitor = true;
    showOccupiedWorkspacesOnly = true;
    dwlShowAllTags = false;
    workspaceNameIcons = { };
    waveProgressEnabled = true;
    scrollTitleEnabled = true;
    audioVisualizerEnabled = true;
    clockCompactMode = false;
    focusedWindowCompactMode = false;
    runningAppsCompactMode = true;
    keyboardLayoutNameCompactMode = false;
    runningAppsCurrentWorkspace = false;
    runningAppsGroupByApp = false;
    centeringMode = "index";
    clockDateFormat = "ddd MMM d";
    lockDateFormat = "";
    mediaSize = 1;
    appLauncherViewMode = "list";
    spotlightModalViewMode = "list";
    sortAppsAlphabetically = false;
    appLauncherGridColumns = 4;
    spotlightCloseNiriOverview = true;
    niriOverviewOverlayEnabled = true;
    weatherLocation = "Ann Arbor, Michigan";
    weatherCoordinates = "42.2813722,-83.7484616";
    useAutoLocation = false;
    weatherEnabled = true;
    networkPreference = "auto";
    vpnLastConnected = "";
    iconTheme = "System Default";
    launcherLogoMode = "compositor";
    launcherLogoCustomPath = "";
    launcherLogoColorOverride = "primary";
    launcherLogoColorInvertOnMode = false;
    launcherLogoBrightness = 0.5;
    launcherLogoContrast = 1;
    launcherLogoSizeOffset = 0;
    fontFamily = "Inter Variable";
    monoFontFamily = "Fira Code";
    fontWeight = 400;
    fontScale = 1.15;
    notepadUseMonospace = true;
    notepadFontFamily = "";
    notepadFontSize = 14;
    notepadShowLineNumbers = false;
    notepadTransparencyOverride = -1;
    notepadLastCustomTransparency = 0.7;
    soundsEnabled = true;
    useSystemSoundTheme = false;
    soundNewNotification = true;
    soundVolumeChanged = true;
    soundPluggedIn = true;
    acMonitorTimeout = 1200;
    acLockTimeout = 600;
    acSuspendTimeout = 3600;
    acSuspendBehavior = 0;
    acProfileName = "";
    batteryMonitorTimeout = 600;
    batteryLockTimeout = 300;
    batterySuspendTimeout = 1200;
    batterySuspendBehavior = 0;
    batteryProfileName = "";
    lockBeforeSuspend = true;
    loginctlLockIntegration = true;
    fadeToLockEnabled = true;
    fadeToLockGracePeriod = 10;
    launchPrefix = "";
    brightnessDevicePins = { };
    wifiNetworkPins = { };
    bluetoothDevicePins = { };
    audioInputDevicePins = { };
    audioOutputDevicePins = { };
    gtkThemingEnabled = false;
    qtThemingEnabled = false;
    syncModeWithPortal = true;
    terminalsAlwaysDark = false;
    runDmsMatugenTemplates = false;
    matugenTemplateGtk = true;
    matugenTemplateNiri = true;
    matugenTemplateQt5ct = true;
    matugenTemplateQt6ct = true;
    matugenTemplateFirefox = true;
    matugenTemplatePywalfox = true;
    matugenTemplateVesktop = true;
    matugenTemplateGhostty = true;
    matugenTemplateKitty = true;
    matugenTemplateFoot = true;
    matugenTemplateAlacritty = true;
    matugenTemplateWezterm = true;
    matugenTemplateDgop = true;
    matugenTemplateKcolorscheme = true;
    matugenTemplateVscode = true;
    showDock = false;
    dockAutoHide = false;
    dockGroupByApp = false;
    dockOpenOnOverview = false;
    dockPosition = 1;
    dockSpacing = 4;
    dockBottomGap = 0;
    dockMargin = 0;
    dockIconSize = 40;
    dockIndicatorStyle = "circle";
    dockBorderEnabled = false;
    dockBorderColor = "surfaceText";
    dockBorderOpacity = 1;
    dockBorderThickness = 1;
    notificationOverlayEnabled = false;
    modalDarkenBackground = true;
    lockScreenShowPowerActions = true;
    lockScreenShowSystemIcons = false;
    lockScreenShowTime = true;
    lockScreenShowDate = true;
    lockScreenShowProfileImage = false;
    lockScreenShowPasswordField = false;
    enableFprint = false;
    maxFprintTries = 15;
    lockScreenActiveMonitor = "all";
    lockScreenInactiveColor = "#000000";
    hideBrightnessSlider = false;
    notificationTimeoutLow = 5000;
    notificationTimeoutNormal = 5000;
    notificationTimeoutCritical = 0;
    notificationPopupPosition = 0;
    osdAlwaysShowValue = false;
    osdPosition = 0;
    osdVolumeEnabled = true;
    osdMediaVolumeEnabled = true;
    osdBrightnessEnabled = true;
    osdIdleInhibitorEnabled = true;
    osdMicMuteEnabled = true;
    osdCapsLockEnabled = true;
    osdPowerProfileEnabled = false;
    osdAudioOutputEnabled = true;
    powerActionConfirm = true;
    powerActionHoldDuration = 0.5;
    powerMenuActions =
      [ "reboot" "logout" "poweroff" "lock" "suspend" "restart" ];
    powerMenuDefaultAction = "logout";
    powerMenuGridLayout = false;
    customPowerActionLock = "";
    customPowerActionLogout = "";
    customPowerActionSuspend = "";
    customPowerActionHibernate = "";
    customPowerActionReboot = "";
    customPowerActionPowerOff = "";
    updaterUseCustomCommand = false;
    updaterCustomCommand = "";
    updaterTerminalAdditionalParams = "";
    displayNameMode = "system";
    screenPreferences = { wallpaper = [ "all" ]; };
    showOnLastDisplay = { };
    barConfigs = [{
      autoHide = false;
      autoHideDelay = 250;
      borderColor = "primary";
      borderEnabled = true;
      borderOpacity = 1;
      borderThickness = 2;
      bottomGap = 0;
      centerWidgets = [
        {
          id = "clock";
          enabled = true;
          clockCompactMode = false;
        }
        {
          id = "separator";
          enabled = true;
        }
        {
          id = "notificationButton";
          enabled = true;
        }
      ];
      enabled = true;
      fontScale = 1;
      gothCornerRadiusOverride = false;
      gothCornerRadiusValue = 12;
      gothCornersEnabled = false;
      id = "default";
      innerPadding = 4;
      leftWidgets = [
        {
          id = "launcherButton";
          enabled = true;
        }
        {
          id = "separator";
          enabled = true;
        }
        {
          id = "workspaceSwitcher";
          enabled = true;
        }
      ];
      maximizeDetection = true;
      name = "Main Bar";
      noBackground = true;
      openOnOverview = false;
      popupGapsAuto = true;
      popupGapsManual = 4;
      position = 3;
      rightWidgets = [
        {
          id = "systemTray";
          enabled = true;
        }
        {
          id = "separator";
          enabled = true;
        }
        {
          id = "idleInhibitor";
          enabled = true;
        }
        {
          id = "separator";
          enabled = true;
        }
        {
          id = "clipboard";
          enabled = true;
        }
        {
          id = "separator";
          enabled = true;
        }
      ] ++ (if deviceType == "laptop" then [
        {
          id = "battery";
          enabled = true;
        }
        {
          id = "separator";
          enabled = true;
        }
      ] else
        [ ]) ++ [
          {
            id = "spacer";
            enabled = true;
            size = 5;
          }
          {
            id = "controlCenterButton";
            enabled = true;
          }
        ];
      screenPreferences = [ "all" ];
      showOnLastDisplay = true;
      spacing = 4;
      squareCorners = false;
      transparency = 1;
      visible = true;
      widgetOutlineColor = "primary";
      widgetOutlineEnabled = false;
      widgetOutlineOpacity = 1;
      widgetOutlineThickness = 1;
      widgetTransparency = 1;
    }];
    configVersion = 2;
  } else {
    currentThemeName = "custom";
    customThemeFile = "${homeDir}/.config/DankMaterialShell/colors.json";
    matugenScheme = "scheme-content";
    runUserMatugenTemplates = false;
    matugenTargetMonitor = "";
    popupTransparency = 1;
    dockTransparency = 1;
    widgetBackgroundColor = "sc";
    widgetColorMode = "default";
    cornerRadius = 10;
    use24HourClock = false;
    showSeconds = false;
    useFahrenheit = true;
    nightModeEnabled = false;
    animationSpeed = 1;
    customAnimationDuration = 500;
    wallpaperFillMode = "Fill";
    blurredWallpaperLayer = true;
    blurWallpaperOnOverview = false;
    showLauncherButton = true;
    showWorkspaceSwitcher = true;
    showFocusedWindow = true;
    showWeather = true;
    showMusic = true;
    showClipboard = true;
    showCpuUsage = true;
    showMemUsage = true;
    showCpuTemp = true;
    showGpuTemp = true;
    selectedGpuIndex = 0;
    enabledGpuPciIds = [ ];
    showSystemTray = true;
    showClock = true;
    showNotificationButton = true;
    showBattery = (deviceType == "laptop");
    showControlCenterButton = true;
    showCapsLockIndicator = true;
    controlCenterShowNetworkIcon = true;
    controlCenterShowBluetoothIcon = true;
    controlCenterShowAudioIcon = true;
    controlCenterShowVpnIcon = true;
    controlCenterShowBrightnessIcon = false;
    controlCenterShowMicIcon = false;
    controlCenterShowBatteryIcon = false;
    controlCenterShowPrinterIcon = false;
    showPrivacyButton = true;
    privacyShowMicIcon = false;
    privacyShowCameraIcon = false;
    privacyShowScreenShareIcon = false;
    controlCenterWidgets = [
      {
        enabled = true;
        id = "volumeSlider";
        width = 50;
      }
      {
        enabled = true;
        id = "brightnessSlider";
        width = 50;
      }
      {
        enabled = true;
        id = "wifi";
        width = 50;
      }
      {
        enabled = true;
        id = "bluetooth";
        width = 50;
      }
      {
        enabled = true;
        id = "audioOutput";
        width = 50;
      }
      {
        enabled = true;
        id = "audioInput";
        width = 50;
      }
      {
        enabled = true;
        id = "nightMode";
        width = 50;
      }
      {
        enabled = true;
        id = "darkMode";
        width = 50;
      }
    ];
    showWorkspaceIndex = false;
    showWorkspacePadding = false;
    workspaceScrolling = false;
    showWorkspaceApps = false;
    maxWorkspaceIcons = 3;
    workspacesPerMonitor = true;
    showOccupiedWorkspacesOnly = true;
    dwlShowAllTags = false;
    workspaceNameIcons = { };
    waveProgressEnabled = true;
    scrollTitleEnabled = true;
    audioVisualizerEnabled = true;
    clockCompactMode = false;
    focusedWindowCompactMode = false;
    runningAppsCompactMode = true;
    keyboardLayoutNameCompactMode = false;
    runningAppsCurrentWorkspace = false;
    runningAppsGroupByApp = false;
    centeringMode = "geometric";
    clockDateFormat = "ddd MMM d";
    lockDateFormat = "";
    mediaSize = 1;
    appLauncherViewMode = "list";
    spotlightModalViewMode = "list";
    sortAppsAlphabetically = false;
    appLauncherGridColumns = 4;
    spotlightCloseNiriOverview = true;
    niriOverviewOverlayEnabled = true;
    weatherLocation = "Baton Rouge, Louisiana";
    weatherCoordinates = "30.4494155,-91.1869659";
    useAutoLocation = false;
    weatherEnabled = true;
    networkPreference = "auto";
    vpnLastConnected = "";
    iconTheme = "System Default";
    launcherLogoMode = "compositor";
    launcherLogoCustomPath = "";
    launcherLogoColorOverride = "primary";
    launcherLogoColorInvertOnMode = false;
    launcherLogoBrightness = 0.5;
    launcherLogoContrast = 1;
    launcherLogoSizeOffset = 0;
    fontFamily = "Inter Variable";
    monoFontFamily = "Fira Code";
    fontWeight = 400;
    fontScale = 1.15;
    notepadUseMonospace = true;
    notepadFontFamily = "";
    notepadFontSize = 14;
    notepadShowLineNumbers = false;
    notepadTransparencyOverride = -1;
    notepadLastCustomTransparency = 0.7;
    soundsEnabled = true;
    useSystemSoundTheme = false;
    soundNewNotification = true;
    soundVolumeChanged = true;
    soundPluggedIn = true;
    acMonitorTimeout = 1200;
    acLockTimeout = 600;
    acSuspendTimeout = 3600;
    acSuspendBehavior = 0;
    acProfileName = "";
    batteryMonitorTimeout = 600;
    batteryLockTimeout = 300;
    batterySuspendTimeout = 1200;
    batterySuspendBehavior = 0;
    batteryProfileName = "";
    lockBeforeSuspend = true;
    loginctlLockIntegration = true;
    fadeToLockEnabled = true;
    fadeToLockGracePeriod = 10;
    launchPrefix = "";
    brightnessDevicePins = { };
    wifiNetworkPins = { };
    bluetoothDevicePins = { };
    audioInputDevicePins = { };
    audioOutputDevicePins = { };
    gtkThemingEnabled = false;
    qtThemingEnabled = false;
    syncModeWithPortal = true;
    terminalsAlwaysDark = false;
    runDmsMatugenTemplates = false;
    matugenTemplateGtk = true;
    matugenTemplateNiri = true;
    matugenTemplateQt5ct = true;
    matugenTemplateQt6ct = true;
    matugenTemplateFirefox = true;
    matugenTemplatePywalfox = true;
    matugenTemplateVesktop = true;
    matugenTemplateGhostty = true;
    matugenTemplateKitty = true;
    matugenTemplateFoot = true;
    matugenTemplateAlacritty = true;
    matugenTemplateWezterm = true;
    matugenTemplateDgop = true;
    matugenTemplateKcolorscheme = true;
    matugenTemplateVscode = true;
    showDock = false;
    dockAutoHide = false;
    dockGroupByApp = false;
    dockOpenOnOverview = false;
    dockPosition = 1;
    dockSpacing = 4;
    dockBottomGap = 0;
    dockMargin = 0;
    dockIconSize = 40;
    dockIndicatorStyle = "circle";
    dockBorderEnabled = false;
    dockBorderColor = "surfaceText";
    dockBorderOpacity = 1;
    dockBorderThickness = 1;
    notificationOverlayEnabled = false;
    modalDarkenBackground = true;
    lockScreenShowPowerActions = true;
    lockScreenShowSystemIcons = false;
    lockScreenShowTime = true;
    lockScreenShowDate = true;
    lockScreenShowProfileImage = false;
    lockScreenShowPasswordField = false;
    enableFprint = true;
    maxFprintTries = 5;
    lockScreenActiveMonitor = "all";
    lockScreenInactiveColor = "#000000";
    hideBrightnessSlider = false;
    notificationTimeoutLow = 5000;
    notificationTimeoutNormal = 5000;
    notificationTimeoutCritical = 0;
    notificationPopupPosition = 0;
    osdAlwaysShowValue = false;
    osdPosition = 0;
    osdVolumeEnabled = true;
    osdMediaVolumeEnabled = true;
    osdBrightnessEnabled = true;
    osdIdleInhibitorEnabled = true;
    osdMicMuteEnabled = true;
    osdCapsLockEnabled = true;
    osdPowerProfileEnabled = false;
    osdAudioOutputEnabled = true;
    powerActionConfirm = true;
    powerActionHoldDuration = 0.5;
    powerMenuActions =
      [ "reboot" "logout" "poweroff" "lock" "suspend" "restart" ];
    powerMenuDefaultAction = "logout";
    powerMenuGridLayout = false;
    customPowerActionLock = "";
    customPowerActionLogout = "";
    customPowerActionSuspend = "";
    customPowerActionHibernate = "";
    customPowerActionReboot = "";
    customPowerActionPowerOff = "";
    updaterUseCustomCommand = false;
    updaterCustomCommand = "";
    updaterTerminalAdditionalParams = "";
    displayNameMode = "system";
    screenPreferences = { wallpaper = [ "all" ]; };
    showOnLastDisplay = { };
    barConfigs = [{
      autoHide = false;
      autoHideDelay = 250;
      borderColor = "primary";
      borderEnabled = true;
      borderOpacity = 1;
      borderThickness = 2;
      bottomGap = 0;
      centerWidgets = [
        {
          id = "clock";
          enabled = true;
          clockCompactMode = false;
        }
        {
          id = "spacer";
          enabled = true;
          size = 5;
        }

        {
          id = "separator";
          enabled = true;
        }
        {
          id = "notificationButton";
          enabled = true;
        }
      ];
      enabled = true;
      fontScale = 1.1;
      gothCornerRadiusOverride = false;
      gothCornerRadiusValue = 12;
      gothCornersEnabled = false;
      id = "default";
      innerPadding = 1;
      leftWidgets = [
        {
          id = "launcherButton";
          enabled = true;
        }
        {
          id = "separator";
          enabled = true;
        }
        {
          id = "workspaceSwitcher";
          enabled = true;
        }
        {
          id = "separator";
          enabled = true;
        }
        {
          id = "spacer";
          enabled = true;
          size = 5;
        }
        {
          id = "dankPomodoroTimer";
          enabled = true;
        }
      ];
      maximizeDetection = true;
      name = "Main Bar";
      noBackground = true;
      openOnOverview = false;
      popupGapsAuto = true;
      popupGapsManual = 4;
      position = 0;
      rightWidgets = [
        {
          id = "systemTray";
          enabled = true;
        }
        {
          id = "separator";
          enabled = true;
        }
        {
          id = "idleInhibitor";
          enabled = true;
        }
        {
          id = "separator";
          enabled = true;
        }
        {
          id = "clipboard";
          enabled = true;
        }
        {
          id = "separator";
          enabled = true;
        }
      ] ++ (if deviceType == "laptop" then [
        {
          id = "battery";
          enabled = true;
        }
        {
          id = "separator";
          enabled = true;
        }
      ] else
        [ ]) ++ [
          {
            id = "spacer";
            enabled = true;
            size = 5;
          }
          {
            id = "controlCenterButton";
            enabled = true;
          }
        ];
      screenPreferences = [ "all" ];
      showOnLastDisplay = true;
      spacing = 3;
      squareCorners = false;
      transparency = 1;
      visible = true;
      widgetOutlineColor = "primary";
      widgetOutlineEnabled = false;
      widgetOutlineOpacity = 1;
      widgetOutlineThickness = 1;
      widgetTransparency = 1;
    }];
    configVersion = 2;
  };
in {
  imports = [ ./colors.nix ./plugins.nix ];

  programs.dank-material-shell = {
    enable = true;
    systemd = {
      enable = true;
      restartIfChanged = true;
    };
  };

  xdg.stateFile."DankMaterialShell/session.json" = {
    source = jsonFormat.generate "session.json" {
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
      includedTransitions =
        [ "fade" "wipe" "disc" "stripes" "iris bloom" "pixelate" "portal" ];
      recentColors = [ ];
      showThirdPartyPlugins = false;
      configVersion = 1;
    };
  };

  xdg.configFile."DankMaterialShell/clsettings.json" = {
    source = jsonFormat.generate "clsettings.json" {
      maxHistory = 100;
      maxEntrySize = 5242880;
      autoClearDays = 1;
      clearAtStartup = false;
      disabled = false;
      disableHistory = false;
      disablePersist = true;
    };
  };

  xdg.configFile."DankMaterialShell/settings.json" = {
    source = jsonFormat.generate "settings.json" settings;
  };
}
