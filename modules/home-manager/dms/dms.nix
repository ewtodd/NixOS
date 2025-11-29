{ config, lib, inputs, osConfig, ... }:

with lib;

let
  colors = config.colorScheme.palette;
  deviceType = osConfig.DeviceType;

  themeContent = builtins.toJSON {
    name = config.colorScheme.slug;
    primary = "#${colors.base0D}"; # Main accent (blue)
    primaryText = "#${colors.base00}"; # Text on primary
    primaryContainer = "#${colors.base0C}"; # Container variant (cyan)
    secondary = "#${colors.base0E}"; # Secondary accent (magenta)
    surface = "#${colors.base01}"; # Surface background
    surfaceText = "#${colors.base05}"; # Text on surface
    surfaceVariant = "#${colors.base02}"; # Variant surface
    surfaceVariantText = "#${colors.base06}"; # Text on variant
    surfaceTint = "#${colors.base0D}"; # Tint color
    background = "#${colors.base00}"; # Base background
    backgroundText = "#${colors.base05}"; # Main text color
    outline = "#${colors.base03}"; # Borders and dividers
    surfaceContainer = "#${colors.base01}"; # Container background
    surfaceContainerHigh = "#${colors.base02}"; # Elevated container
    surfaceContainerHighest = "#${colors.base03}"; # Highest elevation
    error = "#${colors.base08}"; # Error state (red)
    warning = "#${colors.base0A}"; # Warning state (yellow)
    info = "#${colors.base0D}"; # Info state (blue)
  };

  unstable = import inputs.unstable { system = "x86_64-linux"; };

  baseRightWidgets = [
    {
      id = "systemTray";
      enabled = true;
    }
    {
      id = "clipboard";
      enabled = true;
    }
  ];

  # Right widgets with battery for non-desktop devices
  rightWidgets = baseRightWidgets ++ optionals (deviceType != "desktop") [{
    id = "battery";
    enabled = true;
  }] ++ [{
    id = "controlCenterButton";
    enabled = true;
  }];
  settingsContent = builtins.toJSON {
    currentThemeName = "custom";
    customThemeFile =
      "${config.xdg.configHome}/DankMaterialShell/nix-colors-theme.json";
    matugenScheme = "scheme-rainbow";
    runUserMatugenTemplates = true;
    matugenTargetMonitor = "";

    # UI appearance
    popupTransparency = 1;
    dockTransparency = 1;
    widgetBackgroundColor = "s";
    widgetColorMode = "default";
    cornerRadius = 12;

    # Clock & time
    use24HourClock = false;
    showSeconds = false;
    useFahrenheit = true;

    # Animation
    nightModeEnabled = false;
    animationSpeed = 1;
    customAnimationDuration = 500;

    # Wallpaper
    wallpaperFillMode = "Fill";
    blurredWallpaperLayer = true;
    blurWallpaperOnOverview = false;

    # Widget visibility
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
    showBattery = (deviceType != "desktop");
    showControlCenterButton = true;
    showCapsLockIndicator = true;

    # Control center icons
    controlCenterShowNetworkIcon = true;
    controlCenterShowBluetoothIcon = true;
    controlCenterShowAudioIcon = true;
    controlCenterShowVpnIcon = false;
    controlCenterShowBrightnessIcon = false;
    controlCenterShowMicIcon = false;
    controlCenterShowBatteryIcon = false;
    controlCenterShowPrinterIcon = false;

    # Privacy indicators
    showPrivacyButton = true;
    privacyShowMicIcon = false;
    privacyShowCameraIcon = false;
    privacyShowScreenShareIcon = false;

    # Control center widgets
    controlCenterWidgets = [
      {
        id = "volumeSlider";
        enabled = true;
        width = 50;
      }
      {
        id = "brightnessSlider";
        enabled = true;
        width = 50;
      }
      {
        id = "wifi";
        enabled = true;
        width = 50;
      }
      {
        id = "bluetooth";
        enabled = true;
        width = 50;
      }
      {
        id = "audioOutput";
        enabled = true;
        width = 50;
      }
      {
        id = "audioInput";
        enabled = true;
        width = 50;
      }
      {
        id = "nightMode";
        enabled = true;
        width = 50;
      }
      {
        id = "darkMode";
        enabled = true;
        width = 50;
      }
    ];

    # Workspace settings
    showWorkspaceIndex = false;
    showWorkspacePadding = false;
    workspaceScrolling = false;
    showWorkspaceApps = false;
    maxWorkspaceIcons = 3;
    workspacesPerMonitor = true;
    showOccupiedWorkspacesOnly = true;
    dwlShowAllTags = false;
    workspaceNameIcons = { };

    # Widget modes
    waveProgressEnabled = true;
    clockCompactMode = false;
    focusedWindowCompactMode = false;
    runningAppsCompactMode = true;
    keyboardLayoutNameCompactMode = false;
    runningAppsCurrentWorkspace = false;
    runningAppsGroupByApp = false;

    # Date formats
    clockDateFormat = "yyyy-MM-dd";
    lockDateFormat = "";

    # Media & apps
    mediaSize = 1;
    appLauncherViewMode = "list";
    spotlightModalViewMode = "list";
    sortAppsAlphabetically = false;
    appLauncherGridColumns = 4;
    spotlightCloseNiriOverview = true;

    # Weather
    weatherLocation = "Ann Arbor, Michigan";
    weatherCoordinates = "42.2813722,-83.7484616";
    useAutoLocation = false;
    weatherEnabled = true;

    # Network
    networkPreference = "auto";
    vpnLastConnected = "";

    # Appearance
    iconTheme = "System Default";
    launcherLogoMode = "apps";
    launcherLogoCustomPath = "";
    launcherLogoColorOverride = "";
    launcherLogoColorInvertOnMode = false;
    launcherLogoBrightness = 0.5;
    launcherLogoContrast = 1;
    launcherLogoSizeOffset = 0;

    # Fonts
    fontFamily = "Ubuntu Nerd Font";
    monoFontFamily = "Fira Code";
    fontWeight = 400;
    fontScale = 1.15;

    # Notepad
    notepadUseMonospace = true;
    notepadFontFamily = "";
    notepadFontSize = 14;
    notepadShowLineNumbers = false;
    notepadTransparencyOverride = -1;
    notepadLastCustomTransparency = 0.7;

    # Sounds
    soundsEnabled = true;
    useSystemSoundTheme = false;
    soundNewNotification = true;
    soundVolumeChanged = true;
    soundPluggedIn = true;

    # Power management
    acMonitorTimeout = 1200;
    acLockTimeout = 600;
    acSuspendTimeout = 3600;
    acSuspendBehavior = 0;
    batteryMonitorTimeout = 0;
    batteryLockTimeout = 0;
    batterySuspendTimeout = 0;
    batterySuspendBehavior = 0;
    lockBeforeSuspend = true;
    preventIdleForMedia = false;
    loginctlLockIntegration = true;
    fadeToLockEnabled = false;
    fadeToLockGracePeriod = 10;

    # Launch & devices
    launchPrefix = "";
    brightnessDevicePins = { };
    wifiNetworkPins = { };
    bluetoothDevicePins = { };
    audioInputDevicePins = { };
    audioOutputDevicePins = { };

    # Theming integration
    gtkThemingEnabled = false;
    qtThemingEnabled = false;
    syncModeWithPortal = true;
    terminalsAlwaysDark = false;

    # Dock settings
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

    # Notifications
    notificationOverlayEnabled = false;
    modalDarkenBackground = true;
    lockScreenShowPowerActions = true;
    enableFprint = false;
    maxFprintTries = 3;
    hideBrightnessSlider = false;
    notificationTimeoutLow = 5000;
    notificationTimeoutNormal = 5000;
    notificationTimeoutCritical = 0;
    notificationPopupPosition = 0;

    # OSD
    osdAlwaysShowValue = false;
    osdPosition = 0;
    osdVolumeEnabled = true;
    osdMediaVolumeEnabled = true;
    osdBrightnessEnabled = true;
    osdIdleInhibitorEnabled = true;
    osdMicMuteEnabled = true;
    osdCapsLockEnabled = true;
    osdPowerProfileEnabled = false;

    # Power menu
    powerActionConfirm = true;
    powerActionHoldDuration = 1;
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

    # System updates
    updaterUseCustomCommand = false;
    updaterCustomCommand = "";
    updaterTerminalAdditionalParams = "";

    # Display
    displayNameMode = "system";
    screenPreferences = { };
    showOnLastDisplay = { };

    # Bar configuration
    barConfigs = [{
      id = "default";
      name = "Main Bar";
      enabled = true;
      position = 3;
      screenPreferences = [ "all" ];
      showOnLastDisplay = true;
      leftWidgets = [ "launcherButton" "workspaceSwitcher" ];
      centerWidgets = [
        {
          id = "clock";
          enabled = true;
        }
        {
          id = "notificationButton";
          enabled = true;
        }
        {
          id = "privacyIndicator";
          enabled = true;
        }
      ];
      rightWidgets = rightWidgets;
      spacing = 4;
      innerPadding = 4;
      bottomGap = 0;
      transparency = 1;
      widgetTransparency = 1;
      squareCorners = false;
      noBackground = true;
      gothCornersEnabled = false;
      gothCornerRadiusOverride = false;
      gothCornerRadiusValue = 12;
      borderEnabled = true;
      borderColor = "primary";
      borderOpacity = 1;
      borderThickness = 3;
      widgetOutlineEnabled = false;
      widgetOutlineColor = "primary";
      widgetOutlineOpacity = 1;
      widgetOutlineThickness = 1;
      fontScale = 1.2;
      autoHide = false;
      autoHideDelay = 250;
      openOnOverview = false;
      visible = true;
      popupGapsAuto = true;
      popupGapsManual = 4;
    }];

    configVersion = 2;
  };
in {
  programs.dankMaterialShell = {
    enable = true;
    quickshell.package = unstable.quickshell;
    systemd = {
      enable = true;
      restartIfChanged = true;
    };

    enableSystemMonitoring = true;
    enableClipboard = true;
    enableVPN = true;
    enableBrightnessControl = true;
    enableColorPicker = true;
    enableDynamicTheming = true;
    enableAudioWavelength = true;
    enableCalendarEvents = true;
    enableSystemSound = true;
  };

  xdg.configFile."DankMaterialShell/nix-colors-theme.json".text = themeContent;
  xdg.configFile."DankMaterialShell/settings.json".text = settingsContent;

}
