# Uniform Font Customization for Linux and Chrome

Achieve a harmonious browsing experience with scripts tailored for those who appreciate uniformity in fonts and sizes across Linux and Chrome. Perfect for the detail-oriented and OCD-friendly!

## Contents

- **[fontconfig.conf](./fontconfig.conf)**: Streamline Linux fonts! Choose from variable (Open Sans), condensed (Liberation Sans), or fixed-width (Cousine) fonts—or pick your favorites.
- **[replace-fonts.js](./replace-fonts.js)**: A Tampermonkey script for Chrome to override web fonts. It respects your choices and keeps certain domains like Google Docs in their original style.
- **[replace-font-sizes.js](./replace-font-sizes.js)**: Adjust font sizes across the web to suit your preference. This Tampermonkey script ensures readability and comfort, with special settings for sites like Wikipedia and Twitter.
- **[google-chrome-dark-mode-exceptions.js](./google-chrome-dark-mode-exceptions.js)**: Control Chrome's dark mode on a per-site basis. Enjoy your preferred theme—dark or light—on websites like GitHub or Google Docs, regardless of Chrome's settings.

## Highlights

- **Simple Installation**: Easy setup for both Linux and Chrome.
- **Customization at Your Fingertips**: Swap fonts and sizes effortlessly.
- **Improved Readability**: Tailor web pages to your visual comfort.
- **Selective Dark Mode**: Choose which sites go dark in Chrome.

## Installation Instructions

### Setting up the Font Configuration in Linux

1. **Download the `fontconfig.conf` file**: Save the file to a known location on your Linux machine.
2. **Create the Font Configuration Directory**: If it doesn't already exist, create a `.config/fontconfig` directory in your home folder using the command:
   ```bash
   mkdir -p ~/.config/fontconfig
   ```
3. **Move the Configuration File**: Move the downloaded `fontconfig.conf` to the newly created directory:
   ```bash
   mv path/to/downloaded/fontconfig.conf ~/.config/fontconfig/fonts.conf
   ```
4. **Refresh Font Config**: Update the font cache using the command:
   ```bash
   fc-cache -fv
   ```

### Installing Tampermonkey Scripts in Chrome

1. **Install Tampermonkey**: If you haven't already, add the Tampermonkey extension to your Chrome browser from the [Chrome Web Store](https://chrome.google.com/webstore/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo).
2. **Open Tampermonkey Dashboard**: Click on the Tampermonkey icon in your browser and select "Dashboard".
3. **Create New Script**: In the Dashboard, go to the "Utilities" tab, then under "File", click "Import".
4. **Import the Script**: For each of the `.js` files (`replace-fonts.js`, `replace-font-sizes.js`, `google-chrome-dark-mode-exceptions.js`):
   - Click on “Choose File” and select the respective file.
   - Click on “Import” to add the script to Tampermonkey.
5. **Enable the Script**: After importing, make sure the script is enabled. You should see it listed in the "Installed scripts" tab.

## Get Started

Enhance your browsing experience with these scripts and configuration files. Just download, apply, and enjoy a seamless, uniform look across your digital world!
