# Skyscraper for Miyoo Mini

A set of scripts to scrape game artwork for the Miyoo Mini/Mini+ handheld using [Skyscraper](https://github.com/muldjord/skyscraper). Optimized for macOS but works on Linux too.

## Features

- 🎮 Scrape artwork for your entire ROM collection
- 🖼️ Generate composite images optimized for Miyoo Mini's display
- 📋 Create miyoogamelist.xml files for proper game titles
- 🔄 Incremental scraping (only process new games)
- 🧹 Clean up orphaned artwork when ROMs are deleted
- 🎨 Multiple artwork styles included

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/Sumidu/skyscraper4miyoo.git
cd skyscraper4miyoo
```

### 2. Run the setup script (macOS)

```bash
./scripts/setup.sh
```

This will:
- Install dependencies via Homebrew
- Download and compile Skyscraper
- Set up configuration files
- Guide you through initial configuration

### 3. Start scraping

```bash
# Scrape all systems
./scripts/scrape.sh --all

# Scrape specific systems
./scripts/scrape.sh GBA SFC FC

# Scrape only new ROMs (after first run)
./scripts/scrape.sh
```

## Directory Structure

Organize your ROMs like this:

```
~/MiyooMini/Roms/
├── FC/           # NES/Famicom
├── SFC/          # SNES/Super Famicom
├── GB/           # Game Boy
├── GBC/          # Game Boy Color
├── GBA/          # Game Boy Advance
├── MD/           # Mega Drive/Genesis
├── PS/           # PlayStation
└── ...
```

After scraping:

```
~/MiyooMini/Roms/GBA/
├── Game1.gba
├── Game2.gba
├── Imgs/
│   ├── Game1.png
│   └── Game2.png
└── miyoogamelist.xml
```

## Documentation

- [Installation Guide](docs/INSTALL.md) - Detailed setup instructions
- [Usage Guide](docs/USAGE.md) - How to use the scraper

## Configuration

### ScreenScraper Account

For the best experience, create a free account at [ScreenScraper](https://www.screenscraper.fr/). This gives you more API requests per day and access to more content.

### Configuration Files

- `~/.config/skyscraper4miyoo/config` - Main script configuration
- `~/.skyscraper/config.ini` - Skyscraper configuration
- `~/.skyscraper/artwork-miyoo*.xml` - Artwork templates

## Supported Systems

| Folder | System |
|--------|--------|
| FC | NES/Famicom |
| SFC | SNES/Super Famicom |
| GB | Game Boy |
| GBC | Game Boy Color |
| GBA | Game Boy Advance |
| MD | Mega Drive/Genesis |
| MS | Master System |
| GG | Game Gear |
| PCE | PC Engine |
| PS | PlayStation |
| ARCADE | Arcade/MAME |
| NEOGEO | Neo Geo |
| And more... | See [USAGE.md](docs/USAGE.md) |

## Artwork Styles

Three artwork styles are included:

1. **Style 1**: Screenshot with logo overlay (default)
2. **Style 2**: Screenshot with logo and cover art
3. **Style 3**: Screenshot with transparent left edge

## Requirements

- macOS or Linux
- [Skyscraper](https://github.com/muldjord/skyscraper)
- Qt5 (installed automatically on macOS)
- Bash shell

## Credits

- [Skyscraper](https://github.com/muldjord/skyscraper) by Lars Muldjord
- Inspired by [onionscraper](https://github.com/y-muller/onionscraper) by y-muller
- [OnionOS](https://github.com/OnionUI/Onion) for Miyoo Mini

## License

MIT License - See [LICENSE](LICENSE) for details.
