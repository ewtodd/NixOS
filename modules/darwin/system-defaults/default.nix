{ lib, ... }:
{
  config = {
    system.defaults.NSGlobalDomain = {
      AppleSpacesSwitchOnActivate = false;
      InitialKeyRepeat = 14;
      ApplePressAndHoldEnabled = false;
      KeyRepeat = 1;
    };

    system.defaults.dock = {
      autohide = true;
      mru-spaces = false;
    };

    system.defaults.smb.NetBIOSName = lib.mkDefault "darwin-host";

    system.defaults.CustomUserPreferences = {
      "com.apple.symbolichotkeys" = {
        AppleSymbolicHotKeys = {
          # Mission Control & Spaces
          "32" = {
            enabled = true;
            value = {
              type = "standard";
              parameters = [
                65535
                48
                1048576
              ];
            };
          }; # Mission Control (now ⌘)
          "34" = {
            enabled = true;
            value = {
              type = "standard";
              parameters = [
                65535
                48
                1179648
              ];
            };
          }; # Application Windows (⌘⇧)
          "79" = {
            enabled = true;
            value = {
              type = "standard";
              parameters = [
                106
                38
                524288
              ];
            };
          }; # Move left a space (now ⌥j)
          "81" = {
            enabled = true;
            value = {
              type = "standard";
              parameters = [
                107
                40
                524288
              ];
            };
          }; # Move right a space (now ⌥k)

          # Screenshots (swapped to use Cmd instead of Opt)
          "28" = {
            enabled = true;
            value = {
              type = "standard";
              parameters = [
                51
                20
                1441792
              ];
            };
          }; # Save screenshot (now ⌘⌃⇧3)
          "29" = {
            enabled = true;
            value = {
              type = "standard";
              parameters = [
                51
                20
                1179648
              ];
            };
          }; # Copy screenshot (now ⌘⇧3)
          "30" = {
            enabled = true;
            value = {
              type = "standard";
              parameters = [
                52
                21
                1441792
              ];
            };
          }; # Save area screenshot (⌘⌃⇧4)
          "31" = {
            enabled = true;
            value = {
              type = "standard";
              parameters = [
                52
                21
                1179648
              ];
            };
          }; # Copy area screenshot (⌘⇧4)

          # Spotlight & Search
          "64" = {
            enabled = true;
            value = {
              type = "standard";
              parameters = [
                100
                2
                524288
              ];
            };
          }; # Spotlight search (now ⌥d)

          # Stage Manager & UI
          "222" = {
            enabled = true;
            value = {
              type = "standard";
              parameters = [
                115
                1
                524288
              ];
            };
          }; # Toggle Stage Manager (now ⌥s)
          "248" = {
            enabled = false;
            value = {
              type = "standard";
              parameters = [
                97
                0
                524288
              ];
            };
          }; # Show help menu (now ⌥a)

          # Accessibility
          "163" = {
            enabled = false;
            value = {
              type = "standard";
              parameters = [
                110
                45
                655360
              ];
            };
          }; # Full keyboard access (⌥⇧n)

          "21" = {
            enabled = false;
          };
          "25" = {
            enabled = false;
          };
          "26" = {
            enabled = false;
          };
          "27" = {
            enabled = false;
          };
          "33" = {
            enabled = false;
          };
          "35" = {
            enabled = false;
          };
          "36" = {
            enabled = false;
          };
          "37" = {
            enabled = false;
          };
          "59" = {
            enabled = false;
          };
          "65" = {
            enabled = false;
          };
          "98" = {
            enabled = false;
          };
          "118" = {
            enabled = false;
          };
          "119" = {
            enabled = false;
          };
          "162" = {
            enabled = false;
          };
          "184" = {
            enabled = false;
          };
          "190" = {
            enabled = false;
          };
          "215" = {
            enabled = false;
          };
          "216" = {
            enabled = false;
          };
          "217" = {
            enabled = false;
          };
          "218" = {
            enabled = false;
          };
          "219" = {
            enabled = false;
          };
          "223" = {
            enabled = false;
          };
          "224" = {
            enabled = false;
          };
          "225" = {
            enabled = false;
          };
          "226" = {
            enabled = false;
          };
          "227" = {
            enabled = false;
          };
          "228" = {
            enabled = false;
          };
          "229" = {
            enabled = false;
          };
          "230" = {
            enabled = false;
          };
          "231" = {
            enabled = false;
          };
          "232" = {
            enabled = false;
          };
          "240" = {
            enabled = false;
          };
          "241" = {
            enabled = false;
          };
          "242" = {
            enabled = false;
          };
          "243" = {
            enabled = false;
          };
          "249" = {
            enabled = false;
          };
          "250" = {
            enabled = false;
          };
          "251" = {
            enabled = false;
          };
          "256" = {
            enabled = false;
          };
          "257" = {
            enabled = false;
          };
          "258" = {
            enabled = false;
          };
          "260" = {
            enabled = false;
          };
        };
      };
    };
  };
}
