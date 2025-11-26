# skyscraper4miyoo

A set of bash scripts to scrape and generate game artwork images for the Miyoo Mini using the SkyScraper command line tool. These scripts run on macOS.

## Prerequisites

### Install Skyscraper

On macOS, install Skyscraper using Homebrew:

```bash
brew install skyscraper
```

For other platforms, see the [Skyscraper GitHub repository](https://github.com/Gemba/skyscraper).

### Get ScreenScraper Account (Recommended)

Create a free account at [ScreenScraper](https://www.screenscraper.fr) for the best scraping results. Add your credentials to the config file.

## Quick Start

1. **Clone this repository:**
   ```bash
   git clone https://github.com/Sumidu/skyscraper4miyoo.git
   cd skyscraper4miyoo
   ```

2. **Edit the configuration file:**
   ```bash
   cp config.cfg config.cfg.backup  # Optional backup
   nano config.cfg
   ```
   
   Configure at minimum:
   - `ROM_BASE_PATH` - Path to your ROM collection
   - `SCREENSCRAPER_USER` - Your ScreenScraper username
   - `SCREENSCRAPER_PASS` - Your ScreenScraper password

3. **Run the scraping script:**
   ```bash
   chmod +x scrape.sh
   ./scrape.sh
   ```
   
   Or scrape a specific platform:
   ```bash
   ./scrape.sh gba
   ```

4. **Generate artwork:**
   ```bash
   chmod +x generate_artwork.sh
   ./generate_artwork.sh
   ```

5. **Copy the generated images to your Miyoo Mini SD card.**

## Configuration

Edit `config.cfg` to customize the scraping settings:

| Setting | Description | Default |
|---------|-------------|---------|
| `ROM_BASE_PATH` | Path to your ROM collection | (required) |
| `CACHE_PATH` | Path to store scraped cache | (optional) |
| `ARTWORK_OUTPUT_PATH` | Output path for generated artwork | `<ROM_PATH>/<platform>/Imgs` |
| `SCRAPE_SOURCE` | Scraping source (screenscraper, thegamesdb, etc.) | `screenscraper` |
| `SCREENSCRAPER_USER` | ScreenScraper username | (required for screenscraper) |
| `SCREENSCRAPER_PASS` | ScreenScraper password | (required for screenscraper) |
| `ARTWORK_TYPE` | Type of artwork (screenshot, cover, wheel, marquee) | `screenshot` |
| `IMAGE_WIDTH` | Output image width | `640` |
| `IMAGE_HEIGHT` | Output image height | `480` |
| `PLATFORMS` | Space-separated list of platforms to scrape | (see config) |
| `SKIP_EXISTING` | Skip games that already have artwork | `true` |
| `MAX_THREADS` | Number of concurrent threads | `4` |

## Supported Platforms

The scripts support common Miyoo Mini platforms:

- `gb` - Game Boy
- `gbc` - Game Boy Color
- `gba` - Game Boy Advance
- `nes` - Nintendo Entertainment System
- `snes` - Super Nintendo
- `megadrive` - Sega Genesis / Mega Drive
- `mastersystem` - Sega Master System
- `psx` - PlayStation 1
- `arcade` - Arcade
- `pcengine` - PC Engine / TurboGrafx-16
- `neogeo` - Neo Geo

## Directory Structure

The scripts expect ROMs to be organized in platform-specific folders:

```
ROM_BASE_PATH/
├── GB/
│   └── *.gb
├── GBC/
│   └── *.gbc
├── GBA/
│   └── *.gba
├── NES/
│   └── *.nes
└── ...
```

Generated artwork will be placed in `Imgs` subdirectories by default.

## Troubleshooting

### Skyscraper not found
Ensure Skyscraper is installed and in your PATH:
```bash
which Skyscraper
brew install skyscraper  # If not installed
```

### ScreenScraper credentials error
Verify your ScreenScraper account credentials in `config.cfg`.

### No ROMs found
Check that:
- `ROM_BASE_PATH` is set correctly in the config
- ROM folders exist (the scripts check both lowercase and uppercase folder names)

## License

MIT License
