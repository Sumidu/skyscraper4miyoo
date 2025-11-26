# Installation Guide

## macOS Setup

### Prerequisites

1. **Homebrew** - Package manager for macOS
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Qt5** and other dependencies
   ```bash
   brew install qt@5 wget
   brew link qt@5 --force
   ```

### Quick Install

The easiest way to set up the project is using the setup script:

```bash
git clone https://github.com/Sumidu/skyscraper4miyoo.git
cd skyscraper4miyoo
./scripts/setup.sh
```

The setup script will:
- Check and install dependencies via Homebrew
- Download and compile Skyscraper
- Create configuration files
- Set up artwork templates

### Manual Installation

If you prefer to install manually:

1. **Install Skyscraper**
   ```bash
   mkdir -p ~/skysource
   cd ~/skysource
   wget -q -O - https://raw.githubusercontent.com/muldjord/skyscraper/master/update_skyscraper.sh | bash
   ```

2. **Copy configuration files**
   ```bash
   cp config/skyscraper.ini.example ~/.skyscraper/config.ini
   cp artwork/*.xml ~/.skyscraper/
   cp -r artwork/resources/* ~/.skyscraper/resources/
   ```

3. **Edit configuration**
   - Edit `~/.skyscraper/config.ini` and set:
     - `inputFolder` to your ROM directory path
     - `userCreds` to your ScreenScraper username:password

## Linux Setup

The same steps apply, but replace Homebrew commands with your distribution's package manager:

### Ubuntu/Debian
```bash
sudo apt update
sudo apt install build-essential qtbase5-dev qt5-qmake qtbase5-dev-tools wget
```

### Fedora
```bash
sudo dnf install qt5-qtbase-devel wget
```

Then follow the manual installation steps above.

## ScreenScraper Account

For best results, create a free account at [ScreenScraper](https://www.screenscraper.fr/):

1. Go to https://www.screenscraper.fr/
2. Click "Inscription" to register
3. Add your credentials to the Skyscraper config file

Note: Without an account, you'll have limited API requests per day.

## Verifying Installation

Test your installation:

```bash
Skyscraper --help
```

If you see the help output, Skyscraper is installed correctly.

## Troubleshooting

### Qt5 not found on macOS

If you get Qt5-related errors:
```bash
brew link qt@5 --force
export PATH="/usr/local/opt/qt@5/bin:$PATH"
```

### Compilation errors

Make sure you have all Qt5 development packages:
```bash
# macOS
brew reinstall qt@5

# Ubuntu/Debian
sudo apt install qt5-default qtbase5-dev qt5-qmake qtbase5-dev-tools
```

### Permission denied

Make scripts executable:
```bash
chmod +x scripts/*.sh
```
