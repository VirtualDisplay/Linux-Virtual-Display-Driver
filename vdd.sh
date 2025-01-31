#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if xrandr and cvt are installed
if ! command_exists xrandr || ! command_exists cvt; then
    echo "Error: 'xrandr' and/or 'cvt' are not installed."
    read -p "Would you like to install them now? (y/n): " install_choice
    if [[ "$install_choice" =~ ^[Yy]$ ]]; then
        sudo apt update && sudo apt install -y x11-xserver-utils
        echo "'xrandr' and 'cvt' have been installed."
    else
        echo "Installation skipped. The script cannot continue without 'xrandr' and 'cvt'."
        exit 1
    fi
fi

# Get the current primary display name
default_display=$(xrandr | grep " primary" | cut -d" " -f1)

# Get available displays
echo "Available displays:"
xrandr | grep " connected" | awk '{print $1}'
echo ""

# Ask user for the output display
read -p "Enter the name of the secondary display (e.g., HDMI-1, DP-2, DVI-D-0): " secondary_display

# Verify that the secondary display exists
if ! xrandr | grep -q "^$secondary_display connected"; then
    echo "Error: Display '$secondary_display' not found."
    exit 1
fi

# Ask user for the resolution
read -p "Enter the desired resolution (e.g., 1920x1080): " custom_resolution

# Ask user for the refresh rate
read -p "Enter the refresh rate (e.g., 60): " refresh_rate

# Check if the mode already exists
if ! xrandr | grep -q "$custom_resolution"; then
    # Generate modeline using cvt
    modeline=$(cvt $(echo $custom_resolution | tr 'x' ' ') $refresh_rate | grep Modeline | cut -d ' ' -f2-)

    # Add the new mode
    xrandr --newmode $modeline
    xrandr --addmode $secondary_display $custom_resolution
fi

# Get the resolution of the primary display
resolution=$(xrandr | grep "*" | awk '{print $1}')
width=$(echo $resolution | cut -d"x" -f1)
height=$(echo $resolution | cut -d"x" -f2)

# Set the output mode for the secondary display and position it
xrandr --output $secondary_display --mode $custom_resolution --right-of $default_display

# Calculate the new framebuffer size
res_width=$(echo $custom_resolution | cut -d"x" -f1)
res_height=$(echo $custom_resolution | cut -d"x" -f2)

new_width=$(($width + $res_width))
new_height=$((height > res_height ? height : res_height))

# Configure the framebuffer (virtual screen size) to accommodate both monitors
xrandr --fb ${new_width}x${new_height} --output $default_display --panning ${width}x${height}/${new_width}x${new_height}

# Create a virtual monitor configuration
xrandr --setmonitor virtual ${res_width}/64x${res_height}/48+${width}+0 none

echo "Configuration applied successfully!"
