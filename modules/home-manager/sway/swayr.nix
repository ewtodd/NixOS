{ config, pkgs, ... }: {
  programs.swayr = {
    enable = true;
    settings = {
      menu = {
        executable = "${pkgs.fuzzel}/bin/fuzzel";
        args = [
          "--dmenu" # Enable dmenu mode for swayr integration
          "--prompt={prompt}" # Use the prompt provided by swayr
          "--lines=15" # Show up to 15 results
          "--width=60" # Window width in characters
          "--horizontal-pad=20" # Horizontal padding in pixels
          "--vertical-pad=10" # Vertical padding in pixels
          "--inner-pad=5" # Padding between prompt and list
          "--border-radius=12" # Match your waybar styling
          "--border-width=1" # Thin border
          "--font=JetBrains Mono NF:size=14" # Match your system font
          "--background-color=1e1e2eff" # Match your theme
          "--text-color=cdd6f4ff" # Light text
          "--selection-color=cba6f7ff" # Purple selection
          "--selection-text-color=181825ff" # Dark text on selection
          "--border-color=6272a4ff" # Border color
          "--match-color=f9e2afff" # Highlight matched text
          "--prompt-color=be257eff"
        ];
      };

      format = {
        output_format = "{indent}Output {name}    ({id})";
        workspace_format =
          "{indent}Workspace {name} [{layout}] on output {output_name}    ({id})";
        container_format =
          "{indent}Container [{layout}] {marks} on workspace {workspace_name}    ({id})";
        window_format =
          "img:{app_icon}:text:{indent}{app_name} — {urgency_start}“{title}”{urgency_end} {marks} on workspace {workspace_name} / {output_name}    ({id})";
        indent = "    ";
        urgency_start = "";
        urgency_end = "";
        html_escape = true;
      };

      layout = { auto_tile = true; };

      focus = { lockin_delay = 500; };

      misc = {
        seq_inhibit = false;
        auto_nop_delay = 3000;
      };
    };
  };

}
