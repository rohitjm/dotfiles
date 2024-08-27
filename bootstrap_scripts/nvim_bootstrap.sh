#!/bin/bash

# Variables
src="nvim"
dst="$HOME/.config"
LOGFILE="$DOTFILES/nvim_symlink.log"

# Function to log messages with a timestamp
log_message() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

# Start of the script
log_message "Script started."

# Step 1: Create directories in the destination
log_message "Creating directories in $dst..."
find "$src" -type d -exec mkdir -p "$dst/{}" \;
if [ $? -eq 0 ]; then
  log_message "Directories created successfully."
else
  log_message "Failed to create directories."
fi

# Step 2: Create symlinks for files in the corresponding destination directories
log_message "Creating symlinks for files..."
find "$src" -type f -exec ln -sf "$DOTFILES/{}" "$dst/{}" \;
if [ $? -eq 0 ]; then
  log_message "Symlinks created successfully."jjelse
  log_message "Failed to create symlinks."
fi

# End of the script
log_message "Script completed."
