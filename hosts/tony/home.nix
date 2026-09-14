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
            # Per-site cookie jars in one window (private windows would need a second toplevel cage cannot manage).
            # NOTE: site->container mapping lives in the extension's own storage, not prefs/policy -- assign
            # play.max.com to a named container once in the browser; the cookie rules below isolate until then.
            "@testpilot-containers" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi";
              installation_mode = "force_installed";
            };
            "{c607c8df-14a7-4f28-894f-29e8722976af}" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/temporary-containers/latest.xpi";
              installation_mode = "force_installed";
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

          # Three different lifetimes, one per site. Firefox's cookie permission governs DOM storage too, so a
          # Blocked origin gets no localStorage/sessionStorage either -- most of a private window's value, no cage.
          Cookies = {
            Allow = [ "https://play.max.com" ];
            # AllowSession, not Block: blocked outright, YouTube shows its consent interstitial every load and
            # forgets quality/volume. Session cookies behave normally and die on exit -- the 04:00 restart does that.
            AllowSession = [ "https://www.youtube.com" ];
            # Sportsurge gets nothing: no login, no settings worth keeping, and
            # aggregator sites are exactly what you do not want persisting.
            Block = [ "https://sportsurge.net" ];
            Locked = true;
          };

          # Belt and braces alongside AllowSession. Cookies is deliberately
          # NOT cleared here -- the Allow list above is what protects Max, and
          # clearing history/cache/formdata does not touch logins.
          SanitizeOnShutdown = {
            Cache = true;
            History = true;
            FormData = true;
            Sessions = true;
            SiteSettings = false;
            Locked = true;
          };
        };

        profiles.tv = {
          id = 0;
          isDefault = true;
          settings = {
            "browser.startup.homepage" = "file://${./landing}/index.html";
            "browser.startup.page" = 1;

            # Containers must be enabled at the pref level, or both extensions
            # install and silently do nothing.
            "privacy.userContext.enabled" = true;
            "privacy.userContext.ui.enabled" = true;

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
