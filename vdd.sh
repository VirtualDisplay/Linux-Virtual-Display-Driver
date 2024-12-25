# Get the current primary display name
default_display=$(xrandr | grep " primary" | cut -d" " -f1)

# Get the resolution of the primary display
resolution=$(xrandr | grep "*" | awk '{print $1}')
width=$(echo $resolution | cut -d"x" -f1)
height=$(echo $resolution | cut -d"x" -f2)

# Add a custom mode with 1080p resolution for DVI-D-0
xrandr --addmode DVI-D-0 1920x1080

# Set the output mode for DVI-D-0 to 1920x1080 and position it to the right of the primary display
xrandr --output DVI-D-0 --mode 1920x1080 --right-of $default_display

# Calculate the new framebuffer size
new_width=$(($width + 1920))
new_height=$((height > 1080 ? height : 1080))

# Configure the framebuffer (virtual screen size) to accommodate both monitors
xrandr --fb ${new_width}x${new_height} --output $default_display --panning ${width}x${height}/${new_width}x${new_height}

# Create a virtual monitor configuration with the dimensions and position for DVI-D-0
xrandr --setmonitor virtual 1920/64x1080/48+${width}+0 none
