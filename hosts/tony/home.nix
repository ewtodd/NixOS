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
            # Per-site cookie jars in a single window, which is what suits a
            # single-window compositor -- private windows would need a second
            # toplevel cage cannot manage.
            #
            # NOTE: which sites map to which container lives in the extension's
            # own storage, not in prefs or policy, so it cannot be set from
            # here. One-time setup in the browser: assign play.max.com to a
            # named container, leave everything else on Temporary Containers'
            # automatic mode. Until that is done the cookie rules below are
            # what is actually isolating things.
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

          # Three different lifetimes, one per site.
          #
          # Firefox's cookie permission governs DOM storage as well as cookies,
          # so a Blocked origin gets no localStorage or sessionStorage either --
          # which is most of what a private window would have given us, without
          # needing a second toplevel that cage cannot manage.
          Cookies = {
            Allow = [ "https://play.max.com" ];
            # AllowSession, not Block: with cookies blocked outright YouTube shows
            # its consent interstitial on every single load and forgets quality
            # and volume. Session cookies give normal behaviour inside a
            # session and are dropped when the browser exits -- which the 04:00
            # restart makes happen nightly.
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
