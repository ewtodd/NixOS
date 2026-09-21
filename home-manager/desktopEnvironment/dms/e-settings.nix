{
  config,
  osConfig,
  lib,
  ...
}:
let
  deviceType = if (osConfig.systemOptions.deviceType.desktop.enable) then "desktop" else "laptop";
  homeDir = config.home.homeDirectory;
in
{
  settings = {
    currentThemeName = "custom";
    customThemeFile = "${homeDir}/.config/DankMaterialShell/dms-colors.json";
    matugenScheme = "scheme-content";
    runUserMatugenTemplates = false;
    widgetBackgroundColor = "sth";
    cornerRadius = 10;
    clockFormat = "12h";
    padHours12Hour = true;
    useFahrenheit = true;
    springBounce = 0;
    enableRippleEffects = false;
    m3ElevationEnabled = false;
    barElevationEnabled = false;
    blurredWallpaperLayer = true;
    showOccupiedWorkspacesOnly = true;
    runningAppsCurrentWorkspace = false;
    clockDateFormat = "ddd MMM d";
    greeterRememberLastSession = false;
    greeterRememberLastUser = false;
    greeterEnableFprint = if (deviceType == "laptop") then true else false;
    launcherStyle = "spotlight";
    spotlightBarShowModeChips = true;
    dashTabs = [
      {
        id = "overview";
        enabled = true;
      }
      {
        id = "media";
        enabled = false;
      }
      {
        id = "wallpaper";
        enabled = false;
      }
      {
        id = "weather";
        enabled = true;
      }
      {
        id = "settings";
        enabled = true;
      }
    ];
    launcherLogoMode = "compositor";
    launcherLogoColorOverride = "primary";
    fontScale = 1.15;
    acMonitorTimeout = 1200;
    acLockTimeout = 600;
    acSuspendTimeout = 3600;
    batteryMonitorTimeout = 600;
    batteryLockTimeout = 300;
    batterySuspendTimeout = 1200;
    lockBeforeSuspend = true;
    fadeToLockGracePeriod = 10;
    runDmsMatugenTemplates = false;
    lockScreenShowSystemIcons = false;
    lockScreenShowProfileImage = false;
    lockScreenShowPasswordField = false;
    enableFprint = if (deviceType == "laptop") then true else false;
    lockScreenNotificationMode = 2;
    notificationShowTimeoutBar = true;
    notificationPopupPosition = 2;
    notificationHistoryEnabled = false;
    notificationHistorySaveLow = false;
    notificationHistorySaveNormal = false;
    notificationHistorySaveCritical = false;
    notificationRules = [
      {
        enabled = true;
        field = "body";
        pattern = "Claude";
        matchType = "contains";
        action = "ignore";
        urgency = "default";
      }
      {
        enabled = true;
        field = "body";
        pattern = "Qwen";
        matchType = "contains";
        action = "ignore";
        urgency = "default";
      }
      {
        enabled = true;
        field = "appName";
        pattern = "Xpra";
        matchType = "contains";
        action = "ignore";
        urgency = "default";
      }
    ];
    notificationFocusedMonitor = true;
    osdPosition = 2;
    screenPreferences = {
      wallpaper = [
        "all"
      ];
    };
    desktopClockCustomColor = {
      r = 1;
      g = 1;
      b = 1;
      a = 1;
      hsvHue = -1;
      hsvSaturation = 0;
      hsvValue = 1;
      hslHue = -1;
      hslSaturation = 0;
      hslLightness = 1;
      valid = true;
    };
    systemMonitorCustomColor = {
      r = 1;
      g = 1;
      b = 1;
      a = 1;
      hsvHue = -1;
      hsvSaturation = 0;
      hsvValue = 1;
      hslHue = -1;
      hslSaturation = 0;
      hslLightness = 1;
      valid = true;
    };
    builtInPluginSettings = {
      dms_settings_search = {
        trigger = "?";
      };
      dms_clipboard_search = {
        trigger = "cb";
      };
      dms_power = {
        trigger = "pw";
      };
      dms_qr_generator = {
        trigger = "qrg";
      };
    };
    configVersion = 18;
    barConfigs = [
      {
        autoHide = false;
        autoHideDelay = 250;
        borderColor = "primary";
        borderEnabled = true;
        borderOpacity = 1;
        borderThickness = 2;
        bottomGap = -5;
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
        gothCornersEnabled = true;
        id = "default";
        innerPadding = 4;
        leftWidgets = [
          {
            id = "workspaceSwitcher";
            enabled = true;
          }
        ];
        maximizeDetection = true;
        name = "Main Bar";
        noBackground = false;
        openOnOverview = true;
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
        ]
        ++ (
          if deviceType == "laptop" then
            [
              {
                id = "battery";
                enabled = true;
              }
              {
                id = "separator";
                enabled = true;
              }
            ]
          else
            [ ]
        )
        ++ [
          {
            id = "controlCenterButton";
            enabled = true;
          }
        ];
        screenPreferences = [
        ]
        ++ lib.optionals (deviceType == "desktop") [
          # The ultrawide is sometimes probed as DP-5 / DP-3 / DP-1; match by
          # model (a string pref matches screen.model in "system" mode).
          "Sceptre O34"
        ]
        ++ lib.optionals (deviceType == "laptop") [
          {
            name = "eDP-1";
          }
        ];
        scrollXBehavior = "none";
        scrollYBehavior = "none";
        showOnLastDisplay = true;
        spacing = 0;
        squareCorners = true;
        transparency = 1;
        visible = true;
        widgetOutlineColor = "primary";
        widgetOutlineEnabled = false;
        widgetOutlineOpacity = 1;
        widgetOutlineThickness = 1;
        widgetTransparency = 0;
        hoverPopouts = true;
      }
    ];
  };
}
