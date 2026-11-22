{
  "tony" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      landing = "file://${./landing}/index.html";
      wpctl = "${pkgs.wireplumber}/bin/wpctl";
      jellyfinClient = lib.getExe pkgs.jellyfin-mpv-shim;

      kiosk = pkgs.writeShellApplication {
        name = "tony-kiosk";
        text = ''
          export MOZ_ENABLE_WAYLAND=1
          export MOZ_DISABLE_RDD_SANDBOX=1
          export LIBVA_DRIVER_NAME=iHD

          runtime="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
          for _ in $(seq 1 300); do
            if [ -S "$runtime/pulse/native" ]; then break; fi
            sleep 0.1
          done

          exec ${lib.getExe config.programs.firefox.finalPackage} --kiosk "$@"
        '';
      };
    in
    {
      home.username = "tony";
      home.homeDirectory = "/home/tony";
      home.stateVersion = "25.11";

      imports = [ ../../home-manager/profiles/server.nix ];

      wayland.windowManager.niri = {
        enable = true;
        settings = {
          input = {
            keyboard = {
              xkb.layout = "us";
              repeat-delay = 280;
              repeat-rate = 30;
            };
            mouse.natural-scroll = [ ];
            disable-power-key-handling = [ ];
          };

          output = [
            {
              _args = [ "HDMI-A-1" ];
              # change to @ 60 when get new cable
              mode = "3840x2160@30";
              scale = 1.5;
            }
          ];

          # The size is in logical pixels: 160 at scale 1.5 is 240 on screen,
          # 10x the 24px default, which is invisible at 4K from a sofa. Bibata
          # ships large bitmaps, so it stays sharp instead of scaling a 48px
          # source into mush.
          cursor = {
            xcursor-theme = "Bibata-Modern-Classic";
            xcursor-size = 160;
            hide-after-inactive-ms = 3000;
          };

          prefer-no-csd = [ ];
          hotkey-overlay.skip-at-startup = [ ];
          gestures.hot-corners.off = [ ];
          recent-windows.off = [ ];

          layout = {
            gaps = 0;
            background-color = "#170c22";
            default-column-width.proportion = 1.0;
            focus-ring.off = [ ];
            empty-workspace-above-first = [ ];
          };

          binds = {
            "Mod+f".spawn = [ (lib.getExe kiosk) ];
            "Mod+m".spawn = [ jellyfinClient ];
            "Mod+Shift+p".spawn = [
              (lib.getExe kiosk)
              "--private-window"
            ];
            "Mod+h".focus-column-or-monitor-left = [ ];
            "Mod+j".focus-window-or-workspace-down = [ ];
            "Mod+k".focus-window-or-workspace-up = [ ];
            "Mod+l".focus-column-or-monitor-right = [ ];
            "Mod+Shift+h".move-column-left-or-to-monitor-left = [ ];
            "Mod+Shift+j".move-window-down-or-to-workspace-down = [ ];
            "Mod+Shift+k".move-window-up-or-to-workspace-up = [ ];
            "Mod+Shift+l".move-column-right-or-to-monitor-right = [ ];
            "Mod+Tab".toggle-overview = [ ];
            "Mod+WheelScrollDown" = {
              _props.cooldown-ms = 150;
              focus-workspace-down = [ ];
            };
            "Mod+WheelScrollUp" = {
              _props.cooldown-ms = 150;
              focus-workspace-up = [ ];
            };
            XF86AudioRaiseVolume.spawn = [
              wpctl
              "set-volume"
              "-l"
              "1"
              "@DEFAULT_AUDIO_SINK@"
              "5%+"
            ];
            XF86AudioLowerVolume.spawn = [
              wpctl
              "set-volume"
              "@DEFAULT_AUDIO_SINK@"
              "5%-"
            ];
            XF86AudioMute.spawn = [
              wpctl
              "set-mute"
              "@DEFAULT_AUDIO_SINK@"
              "toggle"
            ];
          };

          spawn-at-startup = [ [ (lib.getExe kiosk) ] ];
        };
      };

      programs.firefox = {
        enable = true;

        # ESR, not the release channel: Firefox 158 locks up the Prime Video tab (the
        # Watch button spins forever). Reproduced headless against a copy of this
        # profile: 158 hangs with or without extensions and policies, while 157.0.1
        # and 153 ESR load it with Widevine working. An appliance wants the slower
        # channel anyway.
        package = pkgs.firefox-esr.override {
          extraPrefsFiles = [ (pkgs.replaceVars ./autoconfig.js { inherit landing; }) ];
        };

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
            # Per-site cookie jars in one window, so no site needs a private window of its own.
            # NOTE: site->container mapping lives in the extension's own storage, not prefs/policy -- assign
            # play.max.com and www.amazon.com to named containers once in the browser; the cookie rules below
            # isolate until then.
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

          # Firefox's cookie permission governs DOM storage too, so an AllowSession origin's
          # localStorage dies with its cookies -- most of a private window's value, in the one window.
          Cookies = {
            # Prime Video (US) lives on amazon.com: the storefront, the login and the
            # playback session cookies all sit under www.amazon.com, so that is the
            # origin to keep. primevideo.com only redirects there for a US account.
            Allow = [
              "https://play.max.com"
              "https://www.amazon.com"
              "https://www.hulu.com"
            ];
            # AllowSession, not Block: blocked outright, YouTube shows its consent interstitial every load and
            # forgets quality/volume, and Sportsurge never gets past Cloudflare's challenge, which needs a
            # cookie and otherwise sits on "Enable JavaScript and cookies to continue". Session cookies behave
            # normally and die on exit -- the 04:00 reboot does that.
            AllowSession = [
              "https://www.youtube.com"
              "https://sportsurge.net"
            ];
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
            # New tabs follow from autoconfig.js; no pref can set them.
            "browser.startup.homepage" = landing;
            "browser.startup.page" = 1;

            # Containers must be enabled at the pref level, or both extensions
            # install and silently do nothing.
            "privacy.userContext.enabled" = true;
            "privacy.userContext.ui.enabled" = true;

            "widget.wayland.fractional-scale.enabled" = true;

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

      xdg.configFile."jellyfin-mpv-shim/conf.json".text = builtins.toJSON {
        fullscreen = true;
        mpv_log_level = "info";
      };

      xdg.configFile."jellyfin-mpv-shim/mpv.conf".text = ''
        ao=pipewire
        audio-exclusive=yes
        audio-spdif=ac3,eac3,dts,dts-hd,truehd
        audio-channels=5.1,stereo
        hwdec=vaapi
        vo=gpu-next
      '';
    };

  "root" =
    { ... }:
    {
      home.username = "root";
      home.stateVersion = "25.11";
      imports = [ ../../home-manager/profiles/server.nix ];
    };
}
