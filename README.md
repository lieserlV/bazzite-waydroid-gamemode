# bazzite-waydroid-gamemode
Utility scripts for Bazzite

## How to use Waydroid on GameMode

Follow these steps.

0. **Dependencies**

The following packages are required to run this script:

- **cage**: Runs apps/games in a dedicated Wayland session
- **wlr-randr**: Used for display mode handling
- **waydroid**: Android container and launcher

### Install on Bazzite

Bazzite is an atomic Fedora-based system, but cage and wlr-randr is already installed. For Waydroid, you need install in Bazzite Portal or via ```ujust```.

1. **Download the Script**  
   Download the `waydroid-cage.sh` file to your Desktop or any folder you prefer:

   ```bash
   cd ~/Desktop
   wget https://raw.githubusercontent.com/lieserlV/bazzite-waydroid-gamemode/main/waydroid-cage.sh
   ```

2. **Give Execute Permission**  
   Make the script executable:

   ```bash
   chmod +x waydroid-cage.sh
   ```

3. **Add the script to Steam**

Done!

> ⚠️ **Note:** This script is designed for **Bazzite** with **Cage** and **Waydroid**.  
> Make sure Waydroid is installed and properly set up before running this script.
