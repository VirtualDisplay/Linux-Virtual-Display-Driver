#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if xrandr is installed
if ! command_exists xrandr; then
    echo "Error: 'xrandr' is not installed."
    read -p "Would you like to install it now? (y/n): " install_choice
    if [[ "$install_choice" =~ ^[Yy]$ ]]; then
        sudo apt update && sudo apt install -y x11-xserver-utils
        echo "'xrandr' has been installed."
    else
        echo "Installation skipped. The script cannot continue without 'xrandr'."
        exit 1
    fi
fi

# Get primary display information
default_display=$(xrandr | grep " primary" | cut -d" " -f1)

# Ask user how many virtual displays to create
read -p "Enter the number of virtual displays to create: " num_displays

# Ask for resolution and refresh rate
read -p "Enter the desired resolution for virtual displays (e.g., 1920x1080): " virtual_resolution
read -p "Enter the refresh rate (e.g., 60): " refresh_rate

# Extract width and height
virtual_width=$(echo $virtual_resolution | cut -d"x" -f1)
virtual_height=$(echo $virtual_resolution | cut -d"x" -f2)

# Get the resolution of the primary display
primary_resolution=$(xrandr | grep " primary" | awk '{print $4}')
primary_width=$(echo $primary_resolution | cut -d'+' -f1 | cut -d'x' -f1)
primary_height=$(echo $primary_resolution | cut -d'+' -f1 | cut -d'x' -f2)

# Initialize total width
total_width=$primary_width
total_height=$primary_height

# Create virtual displays
for i in $(seq 1 $num_displays); do
    virtual_display="Virtual-$i"

    # Generate a new mode if it doesn't exist
    if ! xrandr | grep -q "$virtual_resolution"; then
        modeline=$(cvt $virtual_width $virtual_height $refresh_rate | grep Modeline | cut -d ' ' -f2-)
        xrandr --newmode $modeline
    fi

    # Add mode and configure the virtual monitor
    xrandr --addmode $virtual_display $virtual_resolution
    xrandr --setmonitor $virtual_display ${virtual_width}/64x${virtual_height}/48+${total_width}+0 none
    xrandr --output $virtual_display --mode $virtual_resolution --right-of $default_display

    # Update total width and height
    total_width=$((total_width + virtual_width))
    total_height=$((total_height > virtual_height ? total_height : virtual_height))
done

# Adjust the framebuffer size
xrandr --fb ${total_width}x${total_height}

echo "$num_displays virtual displays created successfully!"
