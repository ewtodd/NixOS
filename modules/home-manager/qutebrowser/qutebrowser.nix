{ pkgs, ... }: {
  imports = [ ./colors.nix ];
  programs.qutebrowser = {
    enable = true;
    settings = {
      tabs = {
        position = "left";
        width = "3%";
      };
    };

    greasemonkey = [
      (pkgs.fetchurl {
        url =
          "https://raw.githubusercontent.com/afreakk/greasemonkeyscripts/1d1be041a65c251692ee082eda64d2637edf6444/youtube_sponsorblock.js";
        sha256 = "sha256-e3QgDPa3AOpPyzwvVjPQyEsSUC9goisjBUDMxLwg8ZE=";
      })
      (pkgs.fetchurl {
        url =
          "https://raw.githubusercontent.com/afreakk/greasemonkeyscripts/refs/heads/master/youtube_adblock.js";
        sha256 = "sha256-AyD9VoLJbKPfqmDEwFIEBMl//EIV/FYnZ1+ona+VU9c=";
      })
      (pkgs.fetchurl {
        url =
          "https://raw.githubusercontent.com/afreakk/greasemonkeyscripts/refs/heads/master/reddit_adblock.js";
        sha256 = "sha256-KmCXL4GrZtwPLRyAvAxADpyjbdY5UFnS/XKZFKtg7tk=";
      })
      (pkgs.fetchurl {
        url =
          "https://raw.githubusercontent.com/afreakk/greasemonkeyscripts/refs/heads/master/youtube_shorts_block.js";
        sha256 = "sha256-e9qCSAuEMoNivepy7W/W5F9D1PJZrPAJoejsBi9ejiY=";
      })
      (pkgs.fetchurl {
        url =
          "https://openuserjs.org/install/AdGuard/Adguard_Popup_Blocker.user.js";
        sha256 = "sha256-xDYNqnz7o2rm21h3byFoko127Sh/JDtZDe7cReoUCfA=";
      })
    ];
  };
}
