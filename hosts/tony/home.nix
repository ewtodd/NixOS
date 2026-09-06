{
  "tony" =
    { ... }:
    {
      home.username = "tony";
      home.homeDirectory = "/home/tony";
      home.stateVersion = "25.11";

      imports = [ ../../home-manager/profiles/server.nix ];

      programs.firefox = {
        enable = true;

        policies = {
          ExtensionSettings = {
            "uBlock0@raymondhill.net" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
              installation_mode = "force_installed";
              private_browsing = true;
            };
            "jid1-MnnxcxisBPnSXQ@jetpack" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
              installation_mode = "force_installed";
              private_browsing = true;
            };

            "vimium-c@gdh1995.cn" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-c/latest.xpi";
              installation_mode = "force_installed";
              private_browsing = true;
            };
          };
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          DisablePocket = true;
          DisableFirefoxAccounts = true;
          NoDefaultBookmarks = true;
          OfferToSaveLogins = false;
          DontCheckDefaultBrowser = true;
          OverrideFirstRunPage = "";
          OverridePostUpdatePage = "";
          EncryptedMediaExtensions = {
            Enabled = true;
            Locked = true;
          };
        };

        profiles.tv = {
          id = 0;
          isDefault = true;
          settings = {
            "browser.startup.homepage" = "file://${./landing}/index.html";
            "browser.startup.page" = 1;

            "media.av1.enabled" = false;

            "media.ffmpeg.vaapi.enabled" = true;
            "media.hardware-video-decoding.force-enabled" = true;
            "gfx.webrender.all" = true;

            "media.eme.enabled" = true;
            "media.gmp-widevinecdm.enabled" = true;

            "browser.sessionstore.resume_from_crash" = false;
            "browser.shell.checkDefaultBrowser" = false;
            "browser.aboutConfig.showWarning" = false;
            "datareporting.healthreport.uploadEnabled" = false;
            "app.update.auto" = false;
            "browser.tabs.warnOnClose" = false;
            "full-screen-api.warning.timeout" = 0;
          };
        };
      };
    };

  "root" =
    { ... }:
    {
      home.username = "root";
      home.stateVersion = "25.11";
      imports = [ ../../home-manager/profiles/server.nix ];
    };
}
