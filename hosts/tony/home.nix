{
  "tony" =
    { pkgs, ... }:
    {
      home.username = "tony";
      home.homeDirectory = "/home/tony";
      home.stateVersion = "25.11";

      programs.firefox = {
        enable = true;

        policies = {
          # The reason this box exists: block ads on an ad-tier subscription
          # and on YouTube. Force-installed so it survives a profile reset.
          ExtensionSettings = {
            "uBlock0@raymondhill.net" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
              installation_mode = "force_installed";
            };
          };
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          DisablePocket = true;
          DisableFirefoxAccounts = true;
          NoDefaultBookmarks = true;
          OfferToSaveLogins = false;
          # Max and Netflix need Widevine; Firefox fetches the CDM at runtime.
          # Without this the pages load and then refuse to play.
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

            # ── The important one ────────────────────────────────────────────
            # Comet Lake's media engine (Gen9.5) decodes H.264, HEVC and VP9 in
            # hardware but NOT AV1 -- that arrived with Tiger Lake. YouTube
            # serves AV1 by default to capable clients, so Firefox would
            # software-decode it with dav1d and cook a 15 W part. Turning AV1
            # off makes YouTube fall back to VP9, which this iGPU decodes for
            # free. Disabling a codec to go faster is counterintuitive and
            # correct.
            "media.av1.enabled" = false;

            "media.ffmpeg.vaapi.enabled" = true;
            "media.hardware-video-decoding.force-enabled" = true;
            "gfx.webrender.all" = true;

            # DRM. Linux gets Widevine L3 only, which caps Max and Netflix at
            # 720p; there is no software path to L1, it is hardware-attested.
            "media.eme.enabled" = true;
            "media.gmp-widevinecdm.enabled" = true;

            # Kiosk hygiene: nothing should ever sit waiting for a click.
            "browser.sessionstore.resume_from_crash" = false;
            "browser.shell.checkDefaultBrowser" = false;
            "browser.aboutConfig.showWarning" = false;
            "datareporting.healthreport.uploadEnabled" = false;
            "app.update.auto" = false;
            "browser.tabs.warnOnClose" = false;
            "full-screen-api.warning.timeout" = 0;
            "browser.download.useDownloadDir" = true;

            # Some services check the UA and refuse Linux outright before any
            # DRM negotiation happens. Left off by default -- turn it on only
            # if Max blocks you, since a mismatched UA can cause its own
            # problems.
            # "general.useragent.override" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:155.0) Gecko/20100101 Firefox/155.0";
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
