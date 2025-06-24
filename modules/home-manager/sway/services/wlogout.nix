{ pkgs, ... }: {
  programs.wlogout = {
    enable = true;
    package = null;
    
    layout = [
      {
        label = "logout";
        action = "swaymsg exit";
        text = "Logout";
        keybind = "e";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Shutdown";
        keybind = "s";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "Suspend";
        keybind = "u";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "Reboot";
        keybind = "r";
      }
    ];

    style = ''
      * {
        background-image: none;
        box-shadow: none;
      }

      window {
        background-color: rgba(40, 42, 54, 0.75);
      }

      button {
        color: #f8f8f2;
        background-color: rgba(68, 71, 90, 0.8);
        border-style: solid;
        border-width: 2px;
        border-radius: 15px;
        border-color: rgba(98, 114, 164, 0.8);
        background-repeat: no-repeat;
        background-position: center;
        background-size: 25%;
        font-family: "JetBrains Mono NF";
        font-size: 14px;
        font-weight: bold;
        margin: 10px;
        min-width: 150px;
        min-height: 150px;
      }

      button:focus, button:active, button:hover {
        background-color: rgba(189, 147, 249, 0.8);
        border-color: #bd93f9;
        outline-style: none;
      }


      #logout {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/logout.png"));
      }

      #suspend {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/suspend.png"));
      }

      #shutdown {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png"));
      }

      #reboot {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/reboot.png"));
      }
    '';
  };

}
