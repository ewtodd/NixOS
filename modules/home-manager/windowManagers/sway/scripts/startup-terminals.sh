#!/bin/sh

# Start foot terminals with explicit app_id and title
kitty --app-id=kitty-htop -T "htop" htop &
kitty --app-id=kitty-nvtop -T "nvtop" nvtop &

# Wait for windows to spawn, then move them to workspace 6
sleep 1  # Short delay to ensure windows exist
swaymsg "[app_id=\"kitty-htop\"] move to workspace 6"
swaymsg "[app_id=\"kitty-nvtop\"] move to workspace 6"

