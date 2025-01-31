#!/bin/bash

#----------------------------------------
# Function to check if a command exists
#----------------------------------------
command_exists() {
    command -v "$1" &> /dev/null
}

#----------------------------------------
# Check if xrandr is installed
#----------------------------------------
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

#----------------------------------------
# Get primary display
#----------------------------------------
default_display=$(xrandr | grep " primary" | cut -d" " -f1)

# Fallback if no " primary" is found
if [ -z "$default_display" ]; then
    # This is a naive fallback—adjust if necessary for your environment.
    default_display=$(xrandr | grep " connected" | head -n1 | cut -d" " -f1)
fi

#----------------------------------------
# Ask the user how many virtual displays
#----------------------------------------
read -p "Enter the number of virtual displays to create: " num_displays

#----------------------------------------
# Ask for resolution/refresh
#----------------------------------------
read -p "Enter the desired resolution for virtual displays (e.g., 1920x1080): " virtual_resolution
read -p "Enter the refresh rate (e.g., 60): " refresh_rate

# Extract width & height from the string
virtual_width=$(echo "$virtual_resolution" | cut -d"x" -f1)
virtual_height=$(echo "$virtual_resolution" | cut -d"x" -f2)

#----------------------------------------
# Get primary display's resolution
#----------------------------------------
primary_resolution=$(xrandr | grep "$default_display " | awk '{print $4}')
primary_width=$(echo "$primary_resolution" | cut -d'+' -f1 | cut -d'x' -f1)
primary_height=$(echo "$primary_resolution" | cut -d'+' -f1 | cut -d'x' -f2)

# Fallback if the above parsing fails
if [ -z "$primary_width" ] || [ -z "$primary_height" ]; then
    echo "Warning: Could not detect primary display resolution. Defaulting to 1920x1080."
    primary_width=1920
    primary_height=1080
fi

#----------------------------------------
# Generate / create the new mode if needed
#----------------------------------------
# 1) Extract the actual mode name from 'cvt' output (e.g. "1920x1080_60.00")
mode_name=$(cvt "$virtual_width" "$virtual_height" "$refresh_rate" \
            | sed -n 's/.*Modeline "\(.*\)" .*/\1/p')

# 2) Extract just the numeric parameters that come after the quoted name
mode_line=$(cvt "$virtual_width" "$virtual_height" "$refresh_rate" \
            | grep Modeline | cut -d' ' -f3-)

# 3) Create the new mode only if it does not already exist in xrandr
if ! xrandr | grep -q "\"$mode_name\""; then
    echo "Creating new mode '$mode_name'..."
    xrandr --newmode "$mode_name" $mode_line
fi

#----------------------------------------
# Initialize total framebuffer dimensions
#----------------------------------------
total_width="$primary_width"
total_height="$primary_height"

#----------------------------------------
# Create the virtual displays in a loop
#----------------------------------------
for i in $(seq 1 "$num_displays"); do
    
    virtual_display="Virtual-$i"
    
    # Attach the mode to this new "output" / monitor
    xrandr --addmode "$virtual_display" "$mode_name"
    
    # Use --setmonitor to define a monitor region
    # The aspect ratio arguments (e.g. /64 /48) are placeholders.
    # You can adjust them if needed, or remove them if your driver doesn't use them.
    xrandr --setmonitor "$virtual_display" \
            ${virtual_width}/64x${virtual_height}/48+${total_width}+0 none
    
    # Now apply the mode on the output
    xrandr --output "$virtual_display" --mode "$mode_name" --right-of "$default_display"
    
    # Update total width & height for the next pass
    total_width=$((total_width + virtual_width))
    # If the new virtual display is taller, increase total height
    if (( virtual_height > total_height )); then
        total_height="$virtual_height"
    fi
done

#----------------------------------------
# Finally, expand the framebuffer
#----------------------------------------
xrandr --fb "${total_width}x${total_height}"

echo "$num_displays virtual displays created successfully!"
