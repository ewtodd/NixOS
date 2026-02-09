{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
let
  unstable = inputs.unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  remarkable = inputs.remarkable.packages.${pkgs.stdenv.hostPlatform.system}.default;
  e = config.systemOptions.owner.e.enable;
in
{

  programs = {
    firefox = {
      enable = true;

      policies = lib.mkIf e {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };

        FirefoxHome = {
          SponsoredPocket = false;
          Pocket = false;
          Highlights = false;
          SponsoredTopSites = false;
          TopSites = false;
          Search = false;
          Locked = true;
        };

        DisablePocket = true;
        DisableFirefoxAccounts = true;
        DisableAccounts = true;
        DisableFirefoxScreenshots = true;
        DisableSetDesktopBackground = true;
        DisableMasterPasswordCreation = true;
        DisableFormHistory = true;
        FirefoxSuggest = {
          WebSuggestions = false;
          SponsoredSuggestions = false;
          ImproveSuggest = false;
          Locked = true;
        };
        SearchSuggestEnabled = false;
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = "";
        DontCheckDefaultBrowser = true;
        DisplayBookmarksToolbar = "never";
        DisplayMenuBar = "default-off";
        SearchBar = "unified";
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;
        GenerativeAI.Enabled = false;
        OfferToSaveLogins = false;
        SearchEngines = {
          Default = "DuckDuckGo";
          Remove = [
            "Google"
            "Bing"
            "Perplexity"
            "Amazon.com"
          ];
        };

        Bookmarks = [
          {
            Title = "Check library access!";
            URL = "javascript:void(location.href='http://apps.lib.umich.edu/api/bookmarklet/proxy/?url=%27+encodeURIComponent(location.href));";
            Placement = "menu";
          }
        ];

        ExtensionSettings = {
          "*".installation_mode = "blocked";
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

        Preferences = {
          "browser.contentblocking.category" = {
            Value = "strict";
            Status = "locked";
          };

          "extensions.pocket.enabled" = false;
          "browser.topsites.contile.enabled" = false;
          "browser.formfill.enable" = false;
          "browser.search.suggest.enabled" = false;
          "browser.search.suggest.enabled.private" = false;
          "browser.urlbar.suggest.addons" = false;
          "browser.urlbar.suggest.amp" = false;
          "browser.urlbar.suggest.bookmark" = false;
          "browser.urlbar.suggest.calculator" = false;
          "browser.urlbar.suggest.clipboard" = false;
          "browser.urlbar.suggest.engines" = false;
          "browser.urlbar.suggest.history" = false;
          "browser.urlbar.suggest.importantDates" = false;
          "browser.urlbar.suggest.mdn" = false;
          "browser.urlbar.suggest.openpage" = false;
          "browser.urlbar.suggest.quickactions" = false;
          "browser.urlbar.suggest.realtimeOptIn" = false;
          "browser.urlbar.suggest.recentsearches" = false;
          "browser.urlbar.suggest.remotetab" = false;
          "browser.urlbar.suggest.semanticHistory.minLength" = 0;
          "browser.urlbar.suggest.sports" = false;
          "browser.urlbar.suggest.topsites" = false;
          "browser.urlbar.suggest.trending" = false;
          "browser.urlbar.suggest.weather" = false;
          "browser.urlbar.suggest.wikipedia" = false;
          "browser.urlbar.suggest.yelp" = false;
          "browser.urlbar.suggest.yelpRealtime" = false;
          "browser.urlbar.showSearchSuggestionsFirst" = false;
          "browser.urlbar.quicksuggest.enabled" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.feeds.snippets" = false;
          "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
          "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false;
          "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false;
          "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.system.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        };
      };
    };
  };

  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };

  programs.obs-studio = {
    enable = true;
    package = unstable.obs-studio;
  };

  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
  '';

  virtualisation.docker.enable = true;
  programs.appimage.enable = true;
  programs.appimage.binfmt = true;

  environment.systemPackages =
    with pkgs;
    [
      git
      gh
      nh
      wget
      libreoffice
      tree
      nixfmt
      tree
      usbutils
      poppler-utils
      pciutils
      unzip
      wineWowPackages.stable
      winetricks
      zip
      gearlever
      imagemagick
      ghostscript
      spotify
      pavucontrol
    ]
    ++ lib.optionals (config.systemOptions.apps.zoom.enable) [ zoom-us ]
    ++ lib.optionals (config.systemOptions.apps.remarkable.enable) [ remarkable ]
    ++ lib.optionals (config.systemOptions.apps.quickemu.enable) [ quickemu ];

  environment.shellAliases = lib.mkIf (config.systemOptions.apps.quickemu.enable) {
    windows = "quickemu --vm /home/v-work/.config/qemu/windows-11.conf";
  };

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.ubuntu
    fira-code
    fira-code-symbols
  ];

}
